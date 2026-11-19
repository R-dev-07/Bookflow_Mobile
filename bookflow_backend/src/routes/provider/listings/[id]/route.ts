import { prisma } from '../../../../lib/prisma';
import { ApiError, handle, IdCtx, json, readBody, requireUser } from '../../../../lib/api';

// Body: { action: 'submit' | 'pause' | 'resume' | 'archive' }
export const PATCH = handle(async (req, ctx: IdCtx) => {
  const { id } = await ctx.params;
  const user = await requireUser('PROVIDER', 'ADMIN');
  const { action } = await readBody(req);

  const where = user.role === 'ADMIN' ? { id } : { id, provider: { userId: user.id } };
  const l = await prisma.listing.findFirst({ where });
  if (!l) throw new ApiError(404, 'Listing not found');

  const allowed: Record<string, { from: string[]; to: 'PENDING_REVIEW' | 'PAUSED' | 'APPROVED' | 'ARCHIVED' }> = {
    submit: { from: ['DRAFT', 'REJECTED'], to: 'PENDING_REVIEW' },
    pause: { from: ['APPROVED'], to: 'PAUSED' },
    resume: { from: ['PAUSED'], to: 'APPROVED' },
    archive: { from: ['DRAFT', 'REJECTED', 'PAUSED', 'APPROVED', 'PENDING_REVIEW'], to: 'ARCHIVED' },
  };
  const rule = allowed[String(action)];
  if (!rule) throw new ApiError(400, 'Unsupported action');
  if (!rule.from.includes(l.status)) throw new ApiError(400, `Cannot ${action} a listing that is ${l.status}`);

  await prisma.listing.update({
    where: { id },
    data: { status: rule.to, ...(rule.to === 'PENDING_REVIEW' ? { rejectionReason: null } : {}) },
  });
  return json({ ok: true, status: rule.to });
});

// PUT: Update listing details
export const PUT = handle(async (req, ctx: IdCtx) => {
  const { id } = await ctx.params;
  const user = await requireUser('PROVIDER', 'ADMIN');
  const where = user.role === 'ADMIN' ? { id } : { id, provider: { userId: user.id } };
  const l = await prisma.listing.findFirst({ where });
  if (!l) throw new ApiError(404, 'Listing not found');

  const b = await readBody(req);
  const title = String(b.title ?? l.title).trim();
  const description = String(b.description ?? l.description).trim();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const tiers: any[] = Array.isArray(b.tiers) ? b.tiers : [];
  if (!title || !description) throw new ApiError(400, 'Title and description are required');

  const photos: string[] = (Array.isArray(b.photos) ? b.photos : []).map(String).filter((u: string) => /^https?:\/\//.test(u) || /^data:(image|video)\//.test(u));
  const amenities: string[] = (Array.isArray(b.amenities) ? b.amenities : []).map(String);

  await prisma.listing.update({
    where: { id },
    data: {
      title,
      description,
      location: b.location !== undefined ? (b.location ? String(b.location) : null) : l.location,
      city: b.city !== undefined ? (b.city ? String(b.city) : null) : l.city,
      state: b.state !== undefined ? (b.state ? String(b.state) : null) : l.state,
      country: b.country !== undefined ? (b.country ? String(b.country) : null) : l.country,
      status: 'PENDING_REVIEW', // re-submit for review on edit
      rejectionReason: null,
      ...(l.type === 'VENUE'
        ? {
            venueDetails: {
              update: {
                photos,
                amenities: amenities.length ? amenities : undefined,
              },
            },
          }
        : {
            serviceDetails: {
              update: {
                portfolio: photos,
              },
            },
          }),
      ...(tiers.length > 0 ? {
        pricingTiers: {
          deleteMany: {},
          create: tiers.map((t, i) => ({
            name: String(t.name).trim(),
            description: t.description ? String(t.description) : null,
            price: Number(t.price),
            duration: t.duration ? Number(t.duration) : null,
            isDefault: i === 0,
          })),
        }
      } : {}),
    },
  });

  return json({ ok: true });
});
