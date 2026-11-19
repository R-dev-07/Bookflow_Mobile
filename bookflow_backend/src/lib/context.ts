import { AsyncLocalStorage } from 'node:async_hooks';

/** Holds the bearer token of the request currently being handled. */
export const requestContext = new AsyncLocalStorage<{ token: string | null }>();
