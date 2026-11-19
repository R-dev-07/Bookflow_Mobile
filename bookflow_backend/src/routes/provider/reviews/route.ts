import { prisma } from '../../../lib/prisma';
import { handle, json, requireProvider, reviewItem } from '../../../lib/api';

export const GET = handle(async () => {
  const { profile } = await requireProvider();
  const rows = await prisma.review.findMany({
    where: { listing: { providerId: profile.id }, type: 'USER_TO_PROVIDER' },
    include: { listing: true, reviewer: true },
    orderBy: { createdAt: 'desc' },
    take: 100,
  });
  return json({ items: rows.map(reviewItem) });
});
