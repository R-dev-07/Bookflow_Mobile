import { prisma } from '../../lib/prisma';
import { handle, json, readBody, requireUser } from '../../lib/api';

export const GET = handle(async () => {
  const u = await requireUser();
  return json({
    id: u.id,
    email: u.email,
    firstName: u.firstName,
    lastName: u.lastName,
    imageUrl: u.imageUrl,
    role: u.role,
    providerProfile: u.providerProfile
      ? {
          businessName: u.providerProfile.businessName,
          description: u.providerProfile.description,
          isVerified: u.providerProfile.isVerified,
        }
      : null,
  });
});

export const PATCH = handle(async (req) => {
  const u = await requireUser();
  const body = await readBody(req);
  const firstName = body.firstName !== undefined ? String(body.firstName).trim() : u.firstName;
  const lastName = body.lastName !== undefined ? String(body.lastName).trim() : u.lastName;
  const imageUrl = body.imageUrl !== undefined ? String(body.imageUrl).trim() : u.imageUrl;

  const updatedUser = await prisma.user.update({
    where: { id: u.id },
    data: { firstName, lastName, imageUrl },
    include: { providerProfile: true },
  });

  if (u.providerProfile && (body.businessName !== undefined || body.description !== undefined)) {
    const businessName = body.businessName !== undefined ? String(body.businessName).trim() : u.providerProfile.businessName;
    const description = body.description !== undefined ? String(body.description).trim() : u.providerProfile.description;
    await prisma.providerProfile.update({
      where: { userId: u.id },
      data: { businessName, description },
    });
  }

  return json({ success: true });
});

export const DELETE = handle(async () => {
  const u = await requireUser();
  await prisma.user.update({
    where: { id: u.id },
    data: { deletedAt: new Date() },
  });
  return json({ success: true });
});
