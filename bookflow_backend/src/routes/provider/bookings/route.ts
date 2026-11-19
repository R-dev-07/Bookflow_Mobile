import { prisma } from '../../../lib/prisma';
import { fullName, handle, json, requireProvider } from '../../../lib/api';

// Booking requests for the provider's listings. Optional ?status=PENDING|APPROVED|...
export const GET = handle(async (req) => {
  const { profile } = await requireProvider();
  const status = new URL(req.url).searchParams.get('status');
  const rows = await prisma.bookingItem.findMany({
    where: {
      listing: { providerId: profile.id },
      ...(status && ['PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'COMPLETED'].includes(status)
        ? { status: status as 'PENDING' }
        : {}),
    },
    include: { booking: { include: { user: true } }, listing: true, pricingTier: true },
    orderBy: { createdAt: 'desc' },
    take: 100,
  });
  return json({
    items: rows.map((i) => ({
      itemId: i.id,
      bookingId: i.bookingId,
      status: i.status,
      listingTitle: i.listing.title,
      customerName: fullName(i.booking.user),
      eventType: i.booking.eventType,
      eventDate: i.booking.eventDate,
      guestCount: i.booking.guestCount,
      notes: i.booking.notes,
      tierName: i.pricingTier?.name ?? null,
      quotedPrice: i.quotedPrice == null ? null : Number(i.quotedPrice),
      rejectionReason: i.rejectionReason,
    })),
  });
});
