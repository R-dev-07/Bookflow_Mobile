import { prisma } from '../../../lib/prisma';
import { handle, json, listingInclude, listingSummary, requireUser } from '../../../lib/api';

// ?status=PENDING_REVIEW (default) | APPROVED | REJECTED | PAUSED | DRAFT
export const GET = handle(async (req) => {
  await requireUser('ADMIN');
  const s = new URL(req.url).searchParams.get('status') ?? 'PENDING_REVIEW';
  const status = (['PENDING_REVIEW', 'APPROVED', 'REJECTED', 'PAUSED', 'DRAFT'].includes(s) ? s : 'PENDING_REVIEW') as 'PENDING_REVIEW';
  const rows = await prisma.listing.findMany({
    where: { status },
    include: listingInclude,
    orderBy: { updatedAt: 'desc' },
    take: 100,
  });
  return json({ items: rows.map(listingSummary) });
});
