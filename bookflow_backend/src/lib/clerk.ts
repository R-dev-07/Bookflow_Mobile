import { createClerkClient } from '@clerk/backend';

const client = createClerkClient({ secretKey: process.env.CLERK_SECRET_KEY });

export async function clerkClient() {
  return client;
}
