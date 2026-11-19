import { prisma } from '../../../lib/prisma';
import { handle, json, requireProvider } from '../../../lib/api';

export const GET = handle(async () => {
  const { profile } = await requireProvider();
  const own = { listing: { providerId: profile.id } };
  const [listings, pending, upcoming, done, ratings] = await Promise.all([
    prisma.listing.groupBy({ by: ['status'], where: { providerId: profile.id }, _count: { _all: true } }),
    prisma.bookingItem.count({ where: { ...own, status: 'PENDING' } }),
    prisma.bookingItem.count({ where: { ...own, status: 'APPROVED' } }),
    prisma.bookingItem.aggregate({
      where: { ...own, status: { in: ['APPROVED', 'COMPLETED'] } },
      _sum: { quotedPrice: true },
    }),
    prisma.review.aggregate({
      where: { listing: { providerId: profile.id }, type: 'USER_TO_PROVIDER' },
      _avg: { rating: true },
      _count: { _all: true },
    }),
  ]);
  const byStatus = Object.fromEntries(listings.map((l) => [l.status, l._count._all]));
  return json({
    businessName: profile.businessName,
    isVerified: profile.isVerified,
    listingsTotal: listings.reduce((s, l) => s + l._count._all, 0),
    listingsApproved: byStatus['APPROVED'] ?? 0,
    listingsPending: byStatus['PENDING_REVIEW'] ?? 0,
    pendingRequests: pending,
    upcomingBookings: upcoming,
    revenue: Number(done._sum.quotedPrice ?? 0),
    avgRating: ratings._avg.rating,
    reviewCount: ratings._count._all,
  });
});
