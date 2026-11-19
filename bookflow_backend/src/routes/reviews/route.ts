import { prisma } from '../../lib/prisma';
import { ApiError, fullName, handle, json, readBody, requireUser, reviewItem } from '../../lib/api';

// Reviews I wrote + listings I can still review (completed bookings without a review).
export const GET = handle(async () => {
  const user = await requireUser();
  const [given, completed] = await Promise.all([
    prisma.review.findMany({
      where: { reviewerId: user.id, type: 'USER_TO_PROVIDER' },
      include: { listing: true, reviewer: true },
      orderBy: { createdAt: 'desc' },
    }),
    prisma.bookingItem.findMany({
      where: { booking: { userId: user.id }, status: 'COMPLETED' },
      include: { listing: true },
      orderBy: { updatedAt: 'desc' },
    }),
  ]);
  const reviewed = new Set(given.map((r) => r.listingId));
  const seen = new Set<string>();
  const pending = completed
    .filter((i) => !reviewed.has(i.listingId) && !seen.has(i.listingId) && seen.add(i.listingId))
    .map((i) => ({ listingId: i.listingId, listingTitle: i.listing.title, bookingItemId: i.id }));
  return json({ given: given.map(reviewItem), pending });
});

// Body: { listingId, rating (1-5), comment? }
export const POST = handle(async (req) => {
  const user = await requireUser();
  const b = await readBody(req);
  const rating = Number(b.rating);
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) throw new ApiError(400, 'Rating must be 1-5');
  const listingId = String(b.listingId ?? '');

  const listing = await prisma.listing.findUnique({ where: { id: listingId }, include: { provider: true } });
  if (!listing) throw new ApiError(404, 'Listing not found');

  const done = await prisma.bookingItem.findFirst({
    where: { listingId, status: 'COMPLETED', booking: { userId: user.id } },
  });
  if (!done) throw new ApiError(403, 'You can only review listings from completed bookings');
  if (await prisma.review.findFirst({ where: { listingId, reviewerId: user.id, type: 'USER_TO_PROVIDER' } })) {
    throw new ApiError(409, 'You already reviewed this listing');
  }

  const review = await prisma.review.create({
    data: {
      listingId,
      reviewerId: user.id,
      revieweeId: listing.provider.userId,
      type: 'USER_TO_PROVIDER',
      rating,
      comment: b.comment ? String(b.comment).slice(0, 2000) : null,
    },
    include: { listing: true, reviewer: true },
  });
  await prisma.notification.create({
    data: {
      userId: listing.provider.userId,
      type: 'REVIEW',
      title: 'New review',
      message: `${fullName(user)} left ${rating} star${rating === 1 ? '' : 's'} on ${listing.title}`,
      link: '/provider/reviews',
    },
  });
  return json(reviewItem(review), 201);
});
