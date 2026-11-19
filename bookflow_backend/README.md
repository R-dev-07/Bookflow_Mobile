# BookFlow Backend (Node.js + TypeScript)

Standalone REST API for the BookFlow mobile app. It uses **the same Postgres database and the same Clerk
instance as the BookFlow website**, so users, listings and bookings are shared. You do **not** need to run
the Next.js website for the app to work.

Stack: Express, Prisma (schema copied from the website), `@clerk/backend` (verifies Clerk session tokens).

## Run locally

```bash
cd bookflow_backend
cp .env.example .env        # fill in DATABASE_URL and CLERK_SECRET_KEY (same values as the website's .env)
npm install                 # also runs `prisma generate`
npm run dev                 # http://localhost:4000   (health check: GET /health)
```

No database migration is needed: the schema is identical to the website's (`prisma/schema.prisma`).
If you change the website's schema, copy the new `schema.prisma` here and run `npx prisma generate`.

## How authentication works

The mobile app signs in with Clerk and sends `Authorization: Bearer <session token>` on every request.
The backend verifies the token with `CLERK_SECRET_KEY`, loads the user from the database by `clerkId`,
and creates the row on first use if the Clerk webhook has not already (verified email required).
Roles (`USER` / `PROVIDER` / `ADMIN`) come from the database `User.role`.

## Endpoints (`/api/v1`)

`me`, `become-provider`, `listings`, `listings/:id`, `bookings`, `bookings/:id`, `payments` (mock), `reviews`,
`messages`, `messages/:itemId`, `notifications`,
`provider/{summary,listings,listings/:id,bookings,bookings/:itemId,reviews}`,
`admin/{summary,listings,listings/:id,users,users/:id}`.

Route handlers live in `src/routes/**/route.ts`; `src/routes.ts` (generated) maps them to URLs and
`src/adapter.ts` runs them inside Express. `src/lib/api.ts` holds auth + shared helpers.

## Deploy (so the app works when your computer is off)

Any Node host works (Render, Railway, Fly.io, a VPS). Example for Render / Railway:

* Build command: `npm install && npm run build`
* Start command: `npm start`
* Environment variables: `DATABASE_URL`, `CLERK_SECRET_KEY` (`PORT` is provided by the host)

Then build the mobile app with `--dart-define=API_BASE_URL=https://your-backend-url`.
Always use https in production.

## Notes

* Rate limited to 300 requests/minute per IP; CORS allows any origin (Bearer tokens, no cookies).
* Mock payments, polling-based chat and URL-only photos: see the top-level README.
