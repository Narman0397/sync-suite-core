// Tiny per-worker TTL + single-flight cache for PostgREST reads.
//
// Public pages (home, layanan list, opd list, berita, etc.) are read-mostly
// and identical across visitors. Under bursty traffic the same query can be
// issued hundreds of times per second. This cache:
//   - Memoises the resolved value per key for `ttlMs` (default 30s).
//   - Deduplicates concurrent in-flight requests for the same key
//     (single-flight): the first caller fetches, everyone else awaits the
//     same promise.
//
// It runs both on the server (per Worker isolate) and in the browser (per
// tab). React Query already dedupes within one client, so the biggest gain
// is on the SSR path where each request would otherwise re-hit PostgREST.

type Entry<T> = { value: T; expiresAt: number };

const store = new Map<string, Entry<unknown>>();
const inflight = new Map<string, Promise<unknown>>();

export function cachedFetch<T>(key: string, ttlMs: number, fetcher: () => Promise<T>): Promise<T> {
  const now = Date.now();
  const hit = store.get(key) as Entry<T> | undefined;
  if (hit && hit.expiresAt > now) {
    return Promise.resolve(hit.value);
  }
  const pending = inflight.get(key) as Promise<T> | undefined;
  if (pending) return pending;

  const p = (async () => {
    try {
      const value = await fetcher();
      store.set(key, { value, expiresAt: Date.now() + ttlMs });
      return value;
    } finally {
      inflight.delete(key);
    }
  })();
  inflight.set(key, p);
  return p;
}

export function invalidateCache(prefix?: string): void {
  if (!prefix) {
    store.clear();
    return;
  }
  for (const key of store.keys()) {
    if (key.startsWith(prefix)) store.delete(key);
  }
}
