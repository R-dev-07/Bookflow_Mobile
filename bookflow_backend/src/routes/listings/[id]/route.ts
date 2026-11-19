import { prisma } from '../../../lib/prisma';
import { ApiError, fullName, handle, IdCtx, json, listingInclude, listingSummary } from '../../../lib/api';

export const GET = handle(async (_req, ctx: IdCtx) => {
  const { id } = await ctx.params;
  const l = await prisma.listing.findFirst({
    where: { id, status: 'APPROVED' },
    include: {
      ...listingInclude,
      addOns: true,
      availabilityBlocks: {
        where: { endDate: { gte: new Date() } },
        select: { startDate: true, endDate: true },
      },
      reviews: {
        where: { type: 'USER_TO_PROVIDER' },
        include: { reviewer: true },
        orderBy: { createdAt: 'desc' },
        take: 30,
      },
    },
  });
  if (!l) throw new ApiError(404, 'Listing not found');

  const v = l.venueDetails;
  const s = l.serviceDetails;
  return json({
    ...listingSummary(l),
    location: l.location,
    country: l.country,
    photos: v?.photos?.length ? v.photos : s?.portfolio ?? [],
    amenities: [
      ...(v?.amenities ?? []),
      ...(v?.hasParking ? ['Parking'] : []),
      ...(v?.hasWifi ? ['WiFi'] : []),
      ...(v?.hasAV ? ['A/V equipment'] : []),
      ...(v?.hasCatering ? ['Catering'] : []),
      ...(v?.hasTables ? ['Tables'] : []),
      ...(v?.hasChairs ? ['Chairs'] : []),
    ].filter((x, i, a) => a.indexOf(x) === i),
    serviceArea: s?.serviceArea ?? [],
    travelRadius: s?.travelRadius ?? null,
    minimumLeadTime: s?.minimumLeadTime ?? null,
    providerDescription: l.provider.description,
    tiers: l.pricingTiers.map((t) => ({
      id: t.id,
      name: t.name,
      description: t.description,
      price: Number(t.price),
      duration: t.duration,
    })),
    addOns: l.addOns.map((a) => ({
      id: a.id,
      name: a.name,
      description: a.description,
      price: Number(a.price),
      isRequired: a.isRequired,
    })),
    blockedRanges: l.availabilityBlocks,
    reviews: l.reviews.map((r) => ({
      id: r.id,
      rating: r.rating,
      comment: r.comment,
      createdAt: r.createdAt,
      listingId: l.id,
      listingTitle: l.title,
      reviewerName: fullName(r.reviewer),
    })),
  });
});
