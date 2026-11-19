import { clerkClient } from '../../lib/clerk';
import { UserRole } from '@prisma/client';
import { prisma } from '../../lib/prisma';
import { ApiError, handle, json, readBody, requireUser } from '../../lib/api';

export const POST = handle(async (req) => {
  const user = await requireUser();
  if (user.providerProfile) throw new ApiError(400, 'Provider profile already exists');
  const b = await readBody(req);
  const businessName = String(b.businessName ?? '').trim();
  if (!businessName) throw new ApiError(400, 'Business name is required');

  await prisma.providerProfile.create({
    data: {
      userId: user.id,
      businessName,
      description: b.description ? String(b.description) : null,
      phoneNumber: b.phoneNumber ? String(b.phoneNumber) : null,
    },
  });
  if (user.role === UserRole.USER) {
    await prisma.user.update({ where: { id: user.id }, data: { role: UserRole.PROVIDER } });
  }
  const clerk = await clerkClient();
  await clerk.users.updateUserMetadata(user.clerkId, {
    publicMetadata: { role: user.role === UserRole.ADMIN ? 'ADMIN' : 'PROVIDER' },
  });
  return json({ ok: true }, 201);
});
