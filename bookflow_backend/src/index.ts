import 'dotenv/config';
import compression from 'compression';
import cors from 'cors';
import express, { type NextFunction, type Request, type Response } from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import { registerRoutes } from './routes';

for (const name of ['DATABASE_URL', 'CLERK_SECRET_KEY']) {
  if (!process.env[name]) {
    console.error(`Missing environment variable ${name}. Copy .env.example to .env and fill it in.`);
    process.exit(1);
  }
}

const app = express();
app.set('trust proxy', 1); // behind Render/Railway/Fly/nginx
app.disable('x-powered-by');
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
// Bearer tokens (not cookies) are used, so any origin may call the API (needed for Flutter web).
app.use(
  cors({
    origin: '*',
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Authorization', 'Content-Type'],
    maxAge: 86400,
  }),
);
app.use(compression()); // gzip JSON responses: typically 60-80% smaller on the wire
// Public browse endpoints may be cached briefly by the client / CDN.
app.use('/api/v1/listings', (req, res, next) => {
  if (req.method === 'GET') res.set('Cache-Control', 'public, max-age=30');
  next();
});
app.use(rateLimit({ windowMs: 60_000, limit: 300, standardHeaders: true, legacyHeaders: false }));
app.use(express.json({ limit: '1mb' }));

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

registerRoutes(app);

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// eslint-disable-next-line @typescript-eslint/no-unused-vars
app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
  if ((err as { type?: string })?.type === 'entity.parse.failed') {
    res.status(400).json({ error: 'Invalid JSON body' });
    return;
  }
  console.error('[server]', err);
  res.status(500).json({ error: 'Internal server error' });
});

const port = Number(process.env.PORT ?? 4000);
app.listen(port, '0.0.0.0', () => console.log(`BookFlow API listening on http://0.0.0.0:${port}`));
