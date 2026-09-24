// Edge HTTP caching helpers for the Cloudflare Worker SSR entry.
//
// Strategy:
//   - Only GET/HEAD requests on a curated allowlist of public routes are cached.
//   - Never cache when the request carries auth cookies/headers (per-user data).
//   - Only cache successful (200) HTML/JSON responses that don't Set-Cookie.
//   - Attach a Cache-Control header with s-maxage + stale-while-revalidate so
//     Cloudflare's edge cache (and any downstream CDN) can serve subsequent
//     hits without touching the origin Worker.
//   - Also write into `caches.default` when available so bursts within the same
//     colony are served from cache even before Cloudflare's PoP-level cache
//     picks up the Cache-Control header.

type CacheRule = {
  test: (pathname: string) => boolean;
  // seconds
  sMaxAge: number;
  swr: number;
};

const RULES: CacheRule[] = [
  // Truly static informational pages — konten jarang berubah, cache lama di edge.
  // 24 jam s-maxage + 7 hari stale-while-revalidate: hampir semua request jadi HIT,
  // update tetap propagate cepat karena SWR merefresh di background.
  { test: (p) => p === "/tentang" || p === "/kontak" || p === "/maklumat-pelayanan", sMaxAge: 60 * 60 * 24, swr: 60 * 60 * 24 * 7 },
  // Landing/home — sedikit lebih dinamis (stats), tapi tetap aman di-cache beberapa menit.
  { test: (p) => p === "/", sMaxAge: 60, swr: 300 },
  { test: (p) => p === "/layanan" || p.startsWith("/layanan/"), sMaxAge: 60, swr: 300 },
  { test: (p) => p === "/data-terbuka" || p.startsWith("/data-terbuka/"), sMaxAge: 60, swr: 300 },
  { test: (p) => p === "/berita", sMaxAge: 60, swr: 300 },
  { test: (p) => p === "/kinerja-opd" || p === "/statistik-layanan", sMaxAge: 120, swr: 600 },
  { test: (p) => p === "/data", sMaxAge: 120, swr: 600 },
  { test: (p) => p.startsWith("/instansi/"), sMaxAge: 120, swr: 600 },
  // Static-ish assets already handled by build hashing; catch anything under /assets
  { test: (p) => p.startsWith("/assets/") || p.startsWith("/_build/"), sMaxAge: 60 * 60 * 24 * 30, swr: 60 * 60 * 24 },
];

// Paths that must NEVER be cached, even if a rule above would match.
const NEVER_CACHE_PREFIXES = [
  "/api/",
  "/auth",
  "/admin",
  "/_authenticated",
  "/permohonan",
  "/lapor",
  "/akun",
  "/verify",
  "/ikm/",
  "/v/",
  "/cek-permohonan",
  "/reset-password",
  "/pending-verification",
];

function isAuthed(request: Request): boolean {
  const cookie = request.headers.get("cookie") ?? "";
  if (!cookie) return false;
  // Supabase auth cookie names: sb-<project>-auth-token, sb-access-token, etc.
  return /(?:^|;\s*)sb[-_][A-Za-z0-9._-]*(?:auth-token|access-token|refresh-token)/i.test(cookie);
}

function ruleFor(pathname: string): CacheRule | null {
  for (const prefix of NEVER_CACHE_PREFIXES) {
    if (pathname === prefix || pathname.startsWith(prefix)) return null;
  }
  for (const rule of RULES) {
    if (rule.test(pathname)) return rule;
  }
  return null;
}

// Host preview/editor Lovable: jangan pernah cache HTML di edge, supaya
// perubahan langsung terlihat di preview dan tidak ada versi lama tersimpan.
function isPreviewHost(hostname: string): boolean {
  return (
    hostname === "localhost" ||
    hostname === "127.0.0.1" ||
    hostname.endsWith(".lovable.app") ||
    hostname.endsWith(".lovableproject.com") ||
    hostname.endsWith(".lovableproject-dev.com") ||
    hostname.endsWith(".lovable.dev") ||
    hostname.endsWith(".gptengineer.run") ||
    hostname.endsWith(".gpt-eng.com")
  );
}

function shouldConsider(request: Request): { rule: CacheRule; url: URL } | null {
  if (request.method !== "GET" && request.method !== "HEAD") return null;
  const url = new URL(request.url);
  if (isPreviewHost(url.hostname)) return null;
  // Skip requests with query strings that likely make the page user-specific.
  // Simple heuristic: allow only when there's no query string, to keep the
  // cache key set small and predictable.
  if (url.search) return null;
  if (isAuthed(request)) return null;
  const rule = ruleFor(url.pathname);
  if (!rule) return null;
  return { rule, url };
}

// CATATAN PENTING (root cause bug "halaman kosong" di Cloudflare Workers):
// Sebelumnya file ini juga menaruh respons SSR ke Cache API
// (`caches.default.put(request, response.clone())`). Meng-clone body SSR yang
// masih berupa stream membuat dua cabang stream; cabang cache di-buffer sampai
// selesai sehingga aliran ke browser tidak pernah ditutup — request `/`,
// `/kontak`, dst. menggantung tanpa satu byte pun terkirim. Cache API juga
// no-op di subdomain *.workers.dev. Karena itu modul ini sekarang HANYA
// menempelkan header Cache-Control/Vary dan membiarkan edge Cloudflare yang
// melakukan caching.


// Returns a (possibly new) Response with cache headers applied if cacheable,
// or null if the response should be passed through unchanged.
export function applyEdgeCache(request: Request, response: Response): Response | null {
  const info = shouldConsider(request);
  if (!info) return null;
  if (response.status !== 200) return null;
  // Don't cache anything that sets a cookie — that indicates per-user state.
  if (response.headers.has("set-cookie")) return null;
  const contentType = response.headers.get("content-type") ?? "";
  if (!/^(text\/html|application\/json|text\/plain|application\/javascript|text\/css|image\/)/i.test(contentType)) {
    return null;
  }
  // Only override if origin didn't already set a directive.
  const existing = response.headers.get("cache-control");
  const headers = new Headers(response.headers);
  if (!existing || /no-store|private/i.test(existing)) {
    headers.set(
      "cache-control",
      `public, max-age=0, s-maxage=${info.rule.sMaxAge}, stale-while-revalidate=${info.rule.swr}`,
    );
  }
  headers.set("vary", mergeVary(headers.get("vary"), "Accept-Encoding, Accept"));
  headers.set("x-edge-cache", "MISS");
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}

function mergeVary(existing: string | null, add: string): string {
  if (!existing) return add;
  const set = new Set(
    existing
      .split(",")
      .map((v) => v.trim())
      .filter(Boolean)
      .concat(add.split(",").map((v) => v.trim()).filter(Boolean))
      .map((v) => v.toLowerCase()),
  );
  return Array.from(set).join(", ");
}

