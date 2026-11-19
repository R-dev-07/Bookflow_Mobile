import { prisma } from '../../lib/prisma';
import { fullName, handle, json, requireUser } from '../../lib/api';

// Conversations = one per booking item, between the customer and the listing's provider.
export const GET = handle(async () => {
  const user = await requireUser();
  const items = await prisma.bookingItem.findMany({
    where: {
      OR: [{ booking: { userId: user.id } }, { listing: { provider: { userId: user.id } } }],
    },
    include: {
      listing: { include: { provider: true } },
      booking: { include: { user: true } },
      messages: { orderBy: { createdAt: 'desc' }, take: 1 },
    },
  });
  const unread = await prisma.message.groupBy({
    by: ['bookingItemId'],
    where: { receiverId: user.id, isRead: false },
    _count: { _all: true },
  });
  const unreadMap = new Map(unread.map((u) => [u.bookingItemId, u._count._all]));

  const rows = items
    .map((i) => {
      const iAmCustomer = i.booking.userId === user.id;
      const last = i.messages[0];
      return {
        bookingItemId: i.id,
        title: i.listing.title,
        otherName: iAmCustomer ? i.listing.provider.businessName : fullName(i.booking.user),
        lastMessage: last?.content ?? null,
        lastAt: (last?.createdAt ?? i.createdAt).toISOString(),
        unread: unreadMap.get(i.id) ?? 0,
      };
    })
    .sort((a, b) => b.lastAt.localeCompare(a.lastAt));
  return json({ items: rows });
});
