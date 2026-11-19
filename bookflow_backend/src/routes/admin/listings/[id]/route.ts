import { prisma } from '../../../../lib/prisma';
import { ApiError, handle, IdCtx, json, readBody, requireUser } from '../../../../lib/api';

// Body: { action: 'approve' | 'reject', reason?: string }
export const PATCH = handle(async (req, ctx: IdCtx) => {
  const { id } = await ctx.params;
  await requireUser('ADMIN');
  const b = await readBody(req);
  const l = await prisma.listing.findUnique({ where: { id }, include: { provider: true } });
  if (!l) throw new ApiError(404, 'Listing not found');

  if (b.action === 'approve') {
    await prisma.listing.update({
      where: { id },
      data: { status: 'APPROVED', rejectionReason: null, publishedAt: l.publishedAt ?? new Date() },
    });
    await prisma.notification.create({
      data: { userId: l.provider.userId, type: 'LISTING_APPROVED', title: 'Listing approved', message: `${l.title} is now live`, link: '/provider/listings' },
    });
  } else if (b.action === 'reject') {
    const reason = String(b.reason ?? '').trim();
    if (!reason) throw new ApiError(400, 'A rejection reason is required');
    await prisma.listing.update({ where: { id }, data: { status: 'REJECTED', rejectionReason: reason.slice(0, 500) } });
    await prisma.notification.create({
      data: { userId: l.provider.userId, type: 'LISTING_REJECTED', title: 'Listing needs changes', message: `${l.title}: ${reason}`, link: '/provider/listings' },
    });
  } else {
    throw new ApiError(400, 'Unsupported action');
  }
  return json({ ok: true });
});
