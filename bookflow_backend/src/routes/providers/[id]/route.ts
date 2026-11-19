import { prisma } from '../../../lib/prisma';
import { ApiError, handle, json, listingInclude, listingSummary } from '../../../lib/api';

export const GET = handle(async (_req, ctx: { params: Promise<{ id: string }> }) => {
  const { id } = await ctx.params;
  const provider = await prisma.providerProfile.findUnique({
    where: { id },
    include: {
      user: { select: { firstName: true, lastName: true, imageUrl: true, email: true } },
      listings: {
        where: { status: 'APPROVED' },
        include: listingInclude,
        orderBy: { createdAt: 'desc' },
      },
    },
  });

  if (!provider) throw new ApiError(404, 'Provider not found');

  const ratings = provider.listings.flatMap((l) => l.reviews.map((r) => r.rating));
  const avgRating = ratings.length ? ratings.reduce((a, b) => a + b, 0) / ratings.length : null;

  return json({
    id: provider.id,
    businessName: provider.businessName,
    description: provider.description,
    isVerified: provider.isVerified,
    imageUrl: provider.user.imageUrl,
    email: provider.user.email,
    avgRating,
    reviewCount: ratings.length,
    listings: provider.listings.map(listingSummary),
  });
});
