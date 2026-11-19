import { verifyToken } from '@clerk/backend';
import { Prisma, UserRole } from '@prisma/client';
import { prisma } from './prisma';
import { clerkClient } from './clerk';
import { requestContext } from './context';

/* ------------------------------------------------------------------ */
/* Errors / response helpers                                           */
/* ------------------------------------------------------------------ */

export class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

export function json(data: unknown, status = 200) {
  return Response.json(data, { status });
}

/** Wraps a route handler so thrown ApiErrors become JSON error responses. */
export function handle<C = unknown>(fn: (req: Request, ctx: C) => Promise<Response>) {
  return async (req: Request, ctx: C) => {
    try {
      return await fn(req, ctx);
    } catch (e) {
      if (e instanceof ApiError) return json({ error: e.message }, e.status);
      console.error('[api/v1]', e);
      return json({ error: 'Internal server error' }, 500);
    }
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export async function readBody(req: Request): Promise<Record<string, any>> {
  try {
    return (await req.json()) ?? {};
  } catch {
    throw new ApiError(400, 'Invalid JSON body');
  }
}

export type IdCtx = { params: Promise<{ id: string }> };
export type ItemCtx = { params: Promise<{ itemId: string }> };

/* ------------------------------------------------------------------ */
/* Auth                                                                */
/* ------------------------------------------------------------------ */

/** Verifies the Clerk session token (Authorization: Bearer ...) of the current request. */
async function currentUserId(): Promise<string | null> {
  const token = requestContext.getStore()?.token;
  if (!token) return null;
  try {
    const payload = await verifyToken(token, { secretKey: process.env.CLERK_SECRET_KEY });
    return payload.sub ?? null;
  } catch {
    return null;
  }
}

const userInclude = { providerProfile: true } satisfies Prisma.UserInclude;

/**
 * Resolves the signed-in user from the Clerk session token (cookie OR
 * `Authorization: Bearer <token>`, which is what the mobile app sends).
 * If the Clerk webhook has not created the DB row yet, it is created here.
 */
export async function requireUser(...roles: UserRole[]) {
  const userId = await currentUserId();
  if (!userId) throw new ApiError(401, 'Unauthorized');

  let user = await prisma.user.findUnique({ where: { clerkId: userId }, include: userInclude });

  const clerk = await clerkClient();
  const cu = await clerk.users.getUser(userId);
  const userCount = await prisma.user.count();
  const isClerkAdmin = cu.publicMetadata?.role === 'ADMIN' || userCount <= 1;

  if (!user) {
    const primary = cu.emailAddresses.find((e) => e.id === cu.primaryEmailAddressId);
    if (!primary || primary.verification?.status !== 'verified') {
      throw new ApiError(403, 'A verified email address is required');
    }
    user = await prisma.user.upsert({
      where: { email: primary.emailAddress },
      update: {
        clerkId: userId,
        role: isClerkAdmin ? UserRole.ADMIN : UserRole.USER,
      },
      create: {
        clerkId: userId,
        email: primary.emailAddress,
        firstName: cu.firstName,
        lastName: cu.lastName,
        imageUrl: cu.imageUrl,
        role: isClerkAdmin ? UserRole.ADMIN : UserRole.USER,
      },
      include: userInclude,
    });
  } else if (isClerkAdmin && user.role !== UserRole.ADMIN) {
    user = await prisma.user.update({
      where: { id: user.id },
      data: { role: UserRole.ADMIN },
      include: userInclude,
    });
  }

  if (user.deletedAt) throw new ApiError(403, 'Account disabled');
  if (roles.length && !roles.includes(user.role)) throw new ApiError(403, 'Forbidden');
  return user;
}

/** A PROVIDER (or an ADMIN that also has a provider profile). */
export async function requireProvider() {
  const user = await requireUser(UserRole.PROVIDER, UserRole.ADMIN);
  if (!user.providerProfile) throw new ApiError(403, 'No provider profile');
  return { user, profile: user.providerProfile };
}

export const fullName = (u: { firstName: string | null; lastName: string | null; email: string }) =>
  [u.firstName, u.lastName].filter(Boolean).join(' ') || u.email.split('@')[0];

/* ------------------------------------------------------------------ */
/* Dates                                                               */
/* ------------------------------------------------------------------ */

export function dayBounds(d: Date) {
  const start = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), 0, 0, 0, 0));
  const end = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), 23, 59, 59, 999));
  return { start, end };
}

export const fmtDate = (d: Date) =>
  d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric', timeZone: 'UTC' });

/* ------------------------------------------------------------------ */
/* Listings                                                            */
/* ------------------------------------------------------------------ */

export const listingInclude = {
  provider: true,
  venueDetails: true,
  serviceDetails: true,
  pricingTiers: true,
  reviews: { select: { rating: true } },
} satisfies Prisma.ListingInclude;

export type ListingWithRels = Prisma.ListingGetPayload<{ include: typeof listingInclude }>;

export function listingSummary(l: ListingWithRels) {
  const prices = l.pricingTiers.map((t) => Number(t.price));
  const ratings = l.reviews.map((r) => r.rating);
  const photos = l.venueDetails?.photos?.length ? l.venueDetails.photos : l.serviceDetails?.portfolio ?? [];
  return {
    id: l.id,
    providerId: l.providerId,
    type: l.type,
    title: l.title,
    description: l.description,
    city: l.city,
    state: l.state,
    status: l.status,
    rejectionReason: l.rejectionReason,
    minPrice: prices.length ? Math.min(...prices) : null,
    avgRating: ratings.length ? ratings.reduce((a, b) => a + b, 0) / ratings.length : null,
    reviewCount: ratings.length,
    image: photos[0] ?? null,
    providerName: l.provider.businessName,
    verified: l.provider.isVerified,
    category: l.serviceDetails?.category ?? null,
    capacity: l.venueDetails?.capacity ?? null,
  };
}

/* ------------------------------------------------------------------ */
/* Bookings                                                            */
/* ------------------------------------------------------------------ */

export const bookingInclude = {
  items: {
    include: {
      listing: { include: listingInclude },
      pricingTier: true,
    },
    orderBy: { createdAt: 'asc' },
  },
} satisfies Prisma.BookingInclude;

export type BookingWithItems = Prisma.BookingGetPayload<{ include: typeof bookingInclude }>;

export function serializeBooking(b: BookingWithItems) {
  const active = b.items.filter((i) => i.status !== 'REJECTED' && i.status !== 'CANCELLED');
  return {
    id: b.id,
    eventType: b.eventType,
    eventDate: b.eventDate,
    guestCount: b.guestCount,
    notes: b.notes,
    status: b.status,
    createdAt: b.createdAt,
    total: active.reduce((s, i) => s + Number(i.quotedPrice ?? 0), 0),
    items: b.items.map((i) => {
      const s = listingSummary(i.listing);
      return {
        id: i.id,
        status: i.status,
        listingId: i.listingId,
        listingTitle: i.listing.title,
        image: s.image,
        tierName: i.pricingTier?.name ?? null,
        quotedPrice: i.quotedPrice == null ? null : Number(i.quotedPrice),
        rejectionReason: i.rejectionReason,
        providerName: i.listing.provider.businessName,
      };
    }),
  };
}

/** Re-derives Booking.status from its items. */
export async function recomputeBookingStatus(bookingId: string) {
  const items = await prisma.bookingItem.findMany({ where: { bookingId }, select: { status: true } });
  if (!items.length) return;
  const st = items.map((i) => i.status);
  const all = (s: string) => st.every((x) => x === s);
  let next: 'PENDING' | 'APPROVED' | 'REJECTED' | 'CANCELLED' | 'COMPLETED';
  if (all('CANCELLED')) next = 'CANCELLED';
  else if (all('REJECTED')) next = 'REJECTED';
  else if (st.includes('PENDING')) next = 'PENDING';
  else if (st.every((x) => x === 'COMPLETED' || x === 'REJECTED' || x === 'CANCELLED') && st.includes('COMPLETED'))
    next = 'COMPLETED';
  else next = 'APPROVED';
  await prisma.booking.update({ where: { id: bookingId }, data: { status: next } });
}

export function reviewItem(r: {
  id: string;
  rating: number;
  comment: string | null;
  createdAt: Date;
  listingId: string;
  listing: { title: string };
  reviewer: { firstName: string | null; lastName: string | null; email: string };
}) {
  return {
    id: r.id,
    rating: r.rating,
    comment: r.comment,
    createdAt: r.createdAt,
    listingId: r.listingId,
    listingTitle: r.listing.title,
    reviewerName: fullName(r.reviewer),
  };
}
