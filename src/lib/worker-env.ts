// Cloudflare Workers env → process.env bridge.
//
// ROOT CAUSE this file addresses:
// On workerd, `wrangler secret put` / `[vars]` values are exposed as properties
// of the `env` object passed to `fetch(request, env, ctx)`. They are ONLY mirrored
// onto `process.env` when the `nodejs_compat_populate_process_env` behaviour is
// active, which requires compatibility_date >= 2025-04-01 (see wrangler.toml).
// All server-side readers in this app (Supabase clients, auth middleware, cron
// auth, push, logger) read `process.env.*` — the Node-idiomatic source that also
// works in local dev. Hydrating process.env from the Worker `env` binding at the
// very start of each request makes both runtimes read the exact same names.
//
// No renaming, no per-file special-casing: one canonical source of truth.

export function hydrateProcessEnv(env: unknown): void {
  if (!env || typeof env !== "object") return;

  const globalProcess = (globalThis as { process?: { env?: Record<string, unknown> } }).process;
  if (!globalProcess) return;
  if (!globalProcess.env) globalProcess.env = {};
  const target = globalProcess.env;

  for (const [key, value] of Object.entries(env as Record<string, unknown>)) {
    // Only plain string config values; skip Worker bindings (KV, R2, Durable
    // Objects, service bindings, the ASSETS fetcher, …) which are objects.
    if (typeof value !== "string") continue;
    if (target[key] === undefined || target[key] === "") target[key] = value;
  }
}
