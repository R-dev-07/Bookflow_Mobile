import { clerkClient } from '../../../../lib/clerk';
import { UserRole } from '@prisma/client';
import { prisma } from '../../../../lib/prisma';
import { ApiError, handle, IdCtx, json, readBody, requireUser } from '../../../../lib/api';

// Body: { role: 'USER' | 'PROVIDER' | 'ADMIN' }
export const PATCH = handle(async (req, ctx: IdCtx) => {
  const { id } = await ctx.params;
  const admin = await requireUser('ADMIN');
  const role = (await readBody(req)).role as UserRole;
  if (!Object.values(UserRole).includes(role)) throw new ApiError(400, 'Invalid role');
  if (id === admin.id) throw new ApiError(400, 'You cannot change your own role');

  const target = await prisma.user.findUnique({ where: { id }, include: { providerProfile: true } });
  if (!target || target.deletedAt) throw new ApiError(404, 'User not found');
  if (role === 'PROVIDER' && !target.providerProfile) {
    throw new ApiError(400, 'This user has no provider profile yet');
  }

  await prisma.user.update({ where: { id }, data: { role } });
  const clerk = await clerkClient();
  await clerk.users.updateUserMetadata(target.clerkId, { publicMetadata: { role } });
  return json({ ok: true });
});
