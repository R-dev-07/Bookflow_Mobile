import { prisma } from '../../../lib/prisma';
import {
  ApiError, bookingInclude, dayBounds, fullName, handle, IdCtx, json, readBody, requireUser, serializeBooking,
} from '../../../lib/api';

async function load(id: string, userId: string, isAdmin: boolean) {
  const b = await prisma.booking.findUnique({ where: { id }, include: bookingInclude });
  if (!b || (b.userId !== userId && !isAdmin)) throw new ApiError(404, 'Booking not found');
  return b;
}

export const GET = handle(async (_req, ctx: IdCtx) => {
  const { id } = await ctx.params;
  const user = await requireUser();
  return json(serializeBooking(await load(id, user.id, user.role === 'ADMIN')));
});

// Body: { action: 'cancel' }
export const PATCH = handle(async (req, ctx: IdCtx) => {
  const { id } = await ctx.params;
  const user = await requireUser();
  const body = await readBody(req);
  if (body.action !== 'cancel') throw new ApiError(400, 'Unsupported action');

  const b = await load(id, user.id, false);
  if (b.status !== 'PENDING' && b.status !== 'APPROVED') {
    throw new ApiError(400, `A ${b.status.toLowerCase()} booking cannot be cancelled`);
  }

  const { start, end } = dayBounds(b.eventDate);
  const cancellable = b.items.filter((i) => i.status === 'PENDING' || i.status === 'APPROVED');

  await prisma.$transaction([
    prisma.bookingItem.updateMany({
      where: { id: { in: cancellable.map((i) => i.id) } },
      data: { status: 'CANCELLED' },
    }),
    prisma.booking.update({ where: { id }, data: { status: 'CANCELLED' } }),
    prisma.availabilityBlock.deleteMany({
      where: {
        listingId: { in: cancellable.map((i) => i.listingId) },
        isAutoBlock: true,
        startDate: { gte: start },
        endDate: { lte: end },
      },
    }),
    prisma.notification.createMany({
      data: cancellable.map((i) => ({
        userId: i.listing.provider.userId,
        type: 'BOOKING_UPDATE' as const,
        title: 'Booking cancelled',
        message: `${fullName(user)} cancelled their request for ${i.listing.title}`,
        link: '/provider/bookings',
      })),
    }),
  ]);

  return json(serializeBooking(await load(id, user.id, false)));
});
