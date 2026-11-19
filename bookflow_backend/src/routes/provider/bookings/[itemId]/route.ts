import { prisma } from '../../../../lib/prisma';
import {
  ApiError, dayBounds, fmtDate, handle, ItemCtx, json, readBody, recomputeBookingStatus, requireProvider,
} from '../../../../lib/api';

// Body: { action: 'approve' | 'reject' | 'complete', reason?: string, quotedPrice?: number }
export const PATCH = handle(async (req, ctx: ItemCtx) => {
  const { itemId } = await ctx.params;
  const { profile } = await requireProvider();
  const b = await readBody(req);

  const item = await prisma.bookingItem.findFirst({
    where: { id: itemId, listing: { providerId: profile.id } },
    include: { booking: true, listing: true },
  });
  if (!item) throw new ApiError(404, 'Request not found');

  const { start, end } = dayBounds(item.booking.eventDate);
  let title = '';
  let message = '';

  if (b.action === 'approve') {
    if (item.status !== 'PENDING') throw new ApiError(400, 'Only pending requests can be approved');
    const clash = await prisma.availabilityBlock.findFirst({
      where: { listingId: item.listingId, startDate: { lte: end }, endDate: { gte: start } },
    });
    if (clash) throw new ApiError(409, 'That date is already blocked for this listing');
    const price = b.quotedPrice != null ? Number(b.quotedPrice) : null;
    if (price != null && !(price >= 0)) throw new ApiError(400, 'Invalid price');
    await prisma.$transaction([
      prisma.bookingItem.update({
        where: { id: itemId },
        data: { status: 'APPROVED', ...(price != null ? { quotedPrice: price } : {}) },
      }),
      prisma.availabilityBlock.create({
        data: { listingId: item.listingId, startDate: start, endDate: end, reason: 'booked', isAutoBlock: true },
      }),
    ]);
    title = 'Booking approved';
    message = `${item.listing.title} on ${fmtDate(item.booking.eventDate)} was approved`;
  } else if (b.action === 'reject') {
    if (item.status !== 'PENDING') throw new ApiError(400, 'Only pending requests can be rejected');
    const reason = b.reason ? String(b.reason).slice(0, 500) : null;
    await prisma.bookingItem.update({ where: { id: itemId }, data: { status: 'REJECTED', rejectionReason: reason } });
    title = 'Booking declined';
    message = `${item.listing.title} on ${fmtDate(item.booking.eventDate)} was declined${reason ? `: ${reason}` : ''}`;
  } else if (b.action === 'complete') {
    if (item.status !== 'APPROVED') throw new ApiError(400, 'Only approved bookings can be completed');
    if (end.getTime() > Date.now() + 24 * 3600 * 1000) throw new ApiError(400, 'The event has not happened yet');
    await prisma.bookingItem.update({ where: { id: itemId }, data: { status: 'COMPLETED' } });
    title = 'Booking completed';
    message = `${item.listing.title} is marked complete - you can now leave a review`;
  } else {
    throw new ApiError(400, 'Unsupported action');
  }

  await recomputeBookingStatus(item.bookingId);
  await prisma.notification.create({
    data: { userId: item.booking.userId, type: 'BOOKING_UPDATE', title, message, link: `/dashboard/bookings/${item.bookingId}` },
  });
  return json({ ok: true });
});
