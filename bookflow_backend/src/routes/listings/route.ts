import { Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma';
import { handle, json, listingInclude, listingSummary } from '../../lib/api';

// Public: browse + search approved listings.
export const GET = handle(async (req) => {
  const sp = new URL(req.url).searchParams;
  const q = sp.get('q')?.trim();
  const type = sp.get('type');
  const page = Math.max(1, Number(sp.get('page') ?? 1) || 1);
  const take = 20;

  const where: Prisma.ListingWhereInput = {
    status: 'APPROVED',
    ...(type === 'VENUE' || type === 'SERVICE' ? { type } : {}),
    ...(q
      ? {
          OR: [
            { title: { contains: q, mode: 'insensitive' } },
            { description: { contains: q, mode: 'insensitive' } },
            { city: { contains: q, mode: 'insensitive' } },
            { serviceDetails: { category: { contains: q, mode: 'insensitive' } } },
          ],
        }
      : {}),
  };

  const [rows, total] = await Promise.all([
    prisma.listing.findMany({
      where,
      include: listingInclude,
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * take,
      take,
    }),
    prisma.listing.count({ where }),
  ]);
  return json({ items: rows.map(listingSummary), page, hasMore: page * take < total });
});
