import { prisma } from '../../../lib/prisma';
import { handle, json, requireUser } from '../../../lib/api';

export const GET = handle(async () => {
  await requireUser('ADMIN');
  const [users, providers, pendingListings, approvedListings, bookings, pendingBookings] = await Promise.all([
    prisma.user.count({ where: { deletedAt: null } }),
    prisma.providerProfile.count(),
    prisma.listing.count({ where: { status: 'PENDING_REVIEW' } }),
    prisma.listing.count({ where: { status: 'APPROVED' } }),
    prisma.booking.count(),
    prisma.booking.count({ where: { status: 'PENDING' } }),
  ]);
  return json({ users, providers, pendingListings, approvedListings, bookings, pendingBookings });
});
