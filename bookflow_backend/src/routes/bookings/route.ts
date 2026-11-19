import { prisma } from '../../lib/prisma';
import {
  ApiError, bookingInclude, dayBounds, fmtDate, fullName, handle, json, readBody, requireUser, serializeBooking,
} from '../../lib/api';

export const GET = handle(async () => {
  const user = await requireUser();
  const rows = await prisma.booking.findMany({
    where: { userId: user.id },
    include: bookingInclude,
    orderBy: { createdAt: 'desc' },
  });
  return json({ items: rows.map(serializeBooking) });
});

/**
 * Body: { eventType, eventDate (ISO), guestCount, notes?,
 *         items: [{ listingId, pricingTierId, addOnIds?: string[] }] }
 */
export const POST = handle(async (req) => {
  const user = await requireUser();
  const b = await readBody(req);

  const eventType = String(b.eventType ?? '').trim();
  const guestCount = Number(b.guestCount);
  const eventDate = new Date(b.eventDate);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const items: any[] = Array.isArray(b.items) ? b.items : [];

  if (!eventType || !Number.isInteger(guestCount) || guestCount < 1 || isNaN(eventDate.getTime()) || !items.length) {
    throw new ApiError(400, 'eventType, eventDate, guestCount and items are required');
  }
  if (eventDate.getTime() < Date.now() - 24 * 3600 * 1000) {
    throw new ApiError(400, 'Event date must be in the future');
  }

  const day = dayBounds(eventDate);
  const listings = await prisma.listing.findMany({
    where: { id: { in: items.map((i) => String(i.listingId)) }, status: 'APPROVED' },
    include: {
      pricingTiers: true,
      addOns: true,
      venueDetails: true,
      provider: true,
      availabilityBlocks: { where: { startDate: { lte: day.end }, endDate: { gte: day.start } } },
    },
  });

  const prepared = items.map((it) => {
    const l = listings.find((x) => x.id === String(it.listingId));
    if (!l) throw new ApiError(404, 'Listing not found or not available');
    if (l.provider.userId === user.id) throw new ApiError(400, 'You cannot book your own listing');
    if (l.availabilityBlocks.length) throw new ApiError(409, `${l.title} is not available on that date`);
    if (l.venueDetails && guestCount > l.venueDetails.capacity) {
      throw new ApiError(400, `${l.title} holds at most ${l.venueDetails.capacity} guests`);
    }
    const tier =
      l.pricingTiers.find((t) => t.id === it.pricingTierId) ??
      (l.pricingTiers.length === 1 ? l.pricingTiers[0] : undefined);
    if (!tier) throw new ApiError(400, `Select a pricing option for ${l.title}`);

    const chosen = new Set<string>(Array.isArray(it.addOnIds) ? it.addOnIds.map(String) : []);
    l.addOns.filter((a) => a.isRequired).forEach((a) => chosen.add(a.id));
    const addOns = l.addOns.filter((a) => chosen.has(a.id));
    const price = Number(tier.price) + addOns.reduce((s, a) => s + Number(a.price), 0);
    return { l, tier, addOns, price };
  });

  const booking = await prisma.booking.create({
    data: {
      userId: user.id,
      eventType,
      eventDate,
      guestCount,
      notes: b.notes ? String(b.notes) : null,
      items: {
        create: prepared.map((p) => ({
          listingId: p.l.id,
          pricingTierId: p.tier.id,
          addOns: p.addOns.map((a) => a.id),
          quotedPrice: p.price,
        })),
      },
    },
    include: bookingInclude,
  });

  await prisma.notification.createMany({
    data: prepared.map((p) => ({
      userId: p.l.provider.userId,
      type: 'BOOKING_REQUEST' as const,
      title: 'New booking request',
      message: `${fullName(user)} requested ${p.l.title} for ${fmtDate(eventDate)}`,
      link: '/provider/bookings',
    })),
  });

  return json(serializeBooking(booking), 201);
});
