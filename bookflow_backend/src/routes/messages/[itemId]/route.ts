import { prisma } from '../../../lib/prisma';
import { ApiError, fullName, handle, ItemCtx, json, readBody, requireUser } from '../../../lib/api';

async function loadItem(itemId: string, userId: string) {
  const item = await prisma.bookingItem.findFirst({
    where: {
      id: itemId,
      OR: [{ booking: { userId } }, { listing: { provider: { userId } } }],
    },
    include: { listing: { include: { provider: true } }, booking: { include: { user: true } } },
  });
  if (!item) throw new ApiError(404, 'Conversation not found');
  const iAmCustomer = item.booking.userId === userId;
  return {
    item,
    otherId: iAmCustomer ? item.listing.provider.userId : item.booking.userId,
    otherName: iAmCustomer ? item.listing.provider.businessName : fullName(item.booking.user),
  };
}

export const GET = handle(async (_req, ctx: ItemCtx) => {
  const { itemId } = await ctx.params;
  const user = await requireUser();
  const { item, otherName } = await loadItem(itemId, user.id);
  await prisma.message.updateMany({
    where: { bookingItemId: itemId, receiverId: user.id, isRead: false },
    data: { isRead: true, readAt: new Date() },
  });
  const messages = await prisma.message.findMany({
    where: { bookingItemId: itemId },
    orderBy: { createdAt: 'asc' },
    take: 500,
  });
  return json({
    title: item.listing.title,
    otherName,
    messages: messages.map((m) => ({
      id: m.id,
      content: m.content,
      createdAt: m.createdAt,
      mine: m.senderId === user.id,
    })),
  });
});

// Body: { content }
export const POST = handle(async (req, ctx: ItemCtx) => {
  const { itemId } = await ctx.params;
  const user = await requireUser();
  const content = String((await readBody(req)).content ?? '').trim();
  if (!content) throw new ApiError(400, 'Message is empty');
  if (content.length > 4000) throw new ApiError(400, 'Message is too long');

  const { item, otherId } = await loadItem(itemId, user.id);
  const m = await prisma.message.create({
    data: { bookingItemId: itemId, senderId: user.id, receiverId: otherId, content },
  });
  await prisma.notification.create({
    data: {
      userId: otherId,
      type: 'MESSAGE',
      title: `New message about ${item.listing.title}`,
      message: content.slice(0, 120),
      link: `/messages/${itemId}`,
    },
  });
  return json({ id: m.id, content: m.content, createdAt: m.createdAt, mine: true }, 201);
});
