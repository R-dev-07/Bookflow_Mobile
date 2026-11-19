import type { RequestHandler } from 'express';
import { requestContext } from './lib/context';

// The route files use the standard Web `Request`/`Response` API. This adapter runs them inside Express.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type WebHandler = (req: Request, ctx: any) => Promise<Response>;

function bearer(header: string | undefined): string | null {
  const m = /^Bearer\s+(.+)$/i.exec(header ?? '');
  return m ? m[1].trim() : null;
}

export function adapt(handler: WebHandler): RequestHandler {
  return async (req, res, next) => {
    try {
      const headers = new Headers();
      for (const [k, v] of Object.entries(req.headers)) {
        if (k === 'content-length' || k === 'transfer-encoding') continue;
        if (typeof v === 'string') headers.set(k, v);
        else if (Array.isArray(v)) headers.set(k, v.join(', '));
      }
      const hasBody = req.method !== 'GET' && req.method !== 'HEAD';
      const webReq = new Request(`http://${req.get('host') ?? 'localhost'}${req.originalUrl}`, {
        method: req.method,
        headers,
        body: hasBody ? JSON.stringify(req.body ?? {}) : undefined,
      });

      const response = await requestContext.run({ token: bearer(req.headers.authorization) }, () =>
        handler(webReq, { params: Promise.resolve(req.params) }),
      );
      // Never let clients/CDNs cache an error, even on routes that allow caching of successes.
      if (response.status >= 400) res.set('Cache-Control', 'no-store');
      res.status(response.status).type('application/json').send(await response.text());
    } catch (e) {
      next(e);
    }
  };
}
