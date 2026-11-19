import { prisma } from '../../lib/prisma';
import { ApiError, fmtDate, fullName, handle, json, readBody, requireUser } from '../../lib/api';

/*
 * MOCK PAYMENTS: the schema has no Payment model, so a "payment" is derived from
 * approved/completed booking items, and a payment receipt is stored as a
 * Notification whose `link` is `payment:<bookingItemId>`.
 * Replace with a real provider (Stripe / Flutterwave / ...) + a Payment table later.
 */

export const GET = handle(async () => {
  const user = await requireUser();
  const items = await prisma.bookingItem.findMany({
    where: { booking: { userId: user.id }, status: { in: ['APPROVED', 'COMPLETED'] } },
    include: { listing: true, booking: true },
    orderBy: { updatedAt: 'desc' },
  });
  const receipts = await prisma.notification.findMany({
    where: { userId: user.id, link: { startsWith: 'payment:' } },
    select: { link: true, createdAt: true },
  });
  const paid = new Map(receipts.map((r) => [r.link!.slice('payment:'.length), r.createdAt]));

  const rows = items.map((i) => ({
    bookingItemId: i.id,
    bookingId: i.bookingId,
    title: i.listing.title,
    amount: Number(i.quotedPrice ?? 0),
    eventDate: i.booking.eventDate,
    paid: paid.has(i.id),
    paidAt: paid.get(i.id) ?? null,
  }));
  return json({
    items: rows,
    totalPaid: rows.filter((r) => r.paid).reduce((s, r) => s + r.amount, 0),
    totalDue: rows.filter((r) => !r.paid).reduce((s, r) => s + r.amount, 0),
  });
});

// Body: { bookingItemId }
export const POST = handle(async (req) => {
  const user = await requireUser();
  const b = await readBody(req);
  const item = await prisma.bookingItem.findFirst({
    where: { id: String(b.bookingItemId ?? ''), booking: { userId: user.id } },
    include: { listing: { include: { provider: true } }, booking: true },
  });
  if (!item) throw new ApiError(404, 'Booking item not found');
  if (item.status !== 'APPROVED' && item.status !== 'COMPLETED') {
    throw new ApiError(400, 'Only approved bookings can be paid');
  }
  const link = `payment:${item.id}`;
  if (await prisma.notification.findFirst({ where: { userId: user.id, link } })) {
    throw new ApiError(409, 'Already paid');
  }
  const amount = Number(item.quotedPrice ?? 0).toFixed(2);
  await prisma.notification.createMany({
    data: [
      {
        userId: user.id,
        type: 'BOOKING_UPDATE',
        title: 'Payment received (mock)',
        message: `Payment of ${amount} for ${item.listing.title} on ${fmtDate(item.booking.eventDate)}`,
        link,
      },
      {
        userId: item.listing.provider.userId,
        type: 'BOOKING_UPDATE',
        title: 'Payment received (mock)',
        message: `${fullName(user)} paid ${amount} for ${item.listing.title}`,
        link: `payment-received:${item.id}`,
      },
    ],
  });
  return json({ ok: true }, 201);
});
