import { prisma } from '../../../lib/prisma';
import { fullName, handle, json, requireUser } from '../../../lib/api';

export const GET = handle(async (req) => {
  await requireUser('ADMIN');
  const q = new URL(req.url).searchParams.get('q')?.trim();
  const rows = await prisma.user.findMany({
    where: {
      deletedAt: null,
      ...(q
        ? {
            OR: [
              { email: { contains: q, mode: 'insensitive' } },
              { firstName: { contains: q, mode: 'insensitive' } },
              { lastName: { contains: q, mode: 'insensitive' } },
            ],
          }
        : {}),
    },
    orderBy: { createdAt: 'desc' },
    take: 100,
  });
  return json({
    items: rows.map((u) => ({
      id: u.id,
      name: fullName(u),
      email: u.email,
      role: u.role,
      createdAt: u.createdAt,
    })),
  });
});
