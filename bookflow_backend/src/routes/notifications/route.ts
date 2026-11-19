import { prisma } from '../../lib/prisma';
import { handle, json, readBody, requireUser } from '../../lib/api';

export const GET = handle(async () => {
  const user = await requireUser();
  const [items, unread] = await Promise.all([
    prisma.notification.findMany({ where: { userId: user.id }, orderBy: { createdAt: 'desc' }, take: 60 }),
    prisma.notification.count({ where: { userId: user.id, isRead: false } }),
  ]);
  return json({
    unread,
    items: items.map((n) => ({
      id: n.id,
      type: n.type,
      title: n.title,
      message: n.message,
      isRead: n.isRead,
      createdAt: n.createdAt,
    })),
  });
});

// Body: { all: true } or { ids: string[] }
export const PATCH = handle(async (req) => {
  const user = await requireUser();
  const b = await readBody(req);
  await prisma.notification.updateMany({
    where: {
      userId: user.id,
      isRead: false,
      ...(b.all ? {} : { id: { in: Array.isArray(b.ids) ? b.ids.map(String) : [] } }),
    },
    data: { isRead: true, readAt: new Date() },
  });
  return json({ ok: true });
});
