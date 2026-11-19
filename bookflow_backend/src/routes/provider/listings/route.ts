import { prisma } from '../../../lib/prisma';
import { ApiError, handle, json, listingInclude, listingSummary, readBody, requireProvider } from '../../../lib/api';

export const GET = handle(async () => {
  const { profile } = await requireProvider();
  const rows = await prisma.listing.findMany({
    where: { providerId: profile.id, status: { not: 'ARCHIVED' } },
    include: listingInclude,
    orderBy: { createdAt: 'desc' },
  });
  return json({ items: rows.map(listingSummary) });
});

const slugify = (s: string) =>
  s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60) || 'listing';

/**
 * Body: { type: 'VENUE'|'SERVICE', title, description, city?, state?, country?, location?,
 *         capacity? (venue), category? (service), photos?: string[] (URLs or data URIs), amenities?: string[],
 *         tiers: [{ name, price, description?, duration? }], submit?: boolean }
 */
export const POST = handle(async (req) => {
  const { profile } = await requireProvider();
  const b = await readBody(req);

  const type = b.type === 'SERVICE' ? 'SERVICE' : b.type === 'VENUE' ? 'VENUE' : null;
  const title = String(b.title ?? '').trim();
  const description = String(b.description ?? '').trim();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const tiers: any[] = Array.isArray(b.tiers) ? b.tiers : [];
  if (!type || !title || !description) throw new ApiError(400, 'type, title and description are required');
  if (!tiers.length || tiers.some((t) => !String(t.name ?? '').trim() || !(Number(t.price) > 0))) {
    throw new ApiError(400, 'At least one pricing tier with a name and a price > 0 is required');
  }
  const photos: string[] = (Array.isArray(b.photos) ? b.photos : []).map(String).filter((u: string) => /^https?:\/\//.test(u) || /^data:(image|video)\//.test(u));
  const amenities: string[] = (Array.isArray(b.amenities) ? b.amenities : []).map(String);

  const l = await prisma.listing.create({
    data: {
      providerId: profile.id,
      type,
      title,
      slug: `${slugify(title)}-${Math.random().toString(36).slice(2, 7)}`,
      description,
      location: b.location ? String(b.location) : null,
      city: b.city ? String(b.city) : null,
      state: b.state ? String(b.state) : null,
      country: b.country ? String(b.country) : null,
      status: b.submit ? 'PENDING_REVIEW' : 'DRAFT',
      pricingTiers: {
        create: tiers.map((t, i) => ({
          name: String(t.name).trim(),
          description: t.description ? String(t.description) : null,
          price: Number(t.price),
          duration: t.duration ? Number(t.duration) : null,
          isDefault: i === 0,
        })),
      },
      ...(type === 'VENUE'
        ? { venueDetails: { create: { capacity: Math.max(1, Number(b.capacity) || 1), amenities, photos } } }
        : { serviceDetails: { create: { category: String(b.category || 'General'), serviceArea: [], portfolio: photos } } }),
    },
    include: listingInclude,
  });
  return json(listingSummary(l), 201);
});
