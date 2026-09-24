// Orchestrator E2E test push delivery.
// Gate: bearer super_admin. Aksi:
//   1. seed 1 subscription test (endpoint → sink route di origin ini)
//   2. trigger enqueueNotification untuk SEMUA tipe di ALL_NOTIFICATION_TYPES
//   3. poll push_test_sink sampai semua tipe delivered / timeout 30s
//   4. decrypt setiap hit (RFC 8188 aes128gcm) → verifikasi title/body/url
//   5. cleanup subscription & sink
//   6. return report { total, delivered, missing[], hits[] }
import { createFileRoute } from "@tanstack/react-router";
import { createClient } from "@supabase/supabase-js";
import type { Database } from "@/integrations/supabase/types";
import { ALL_NOTIFICATION_TYPES } from "@/lib/push/notification-types";
import { enqueueNotification } from "@/lib/notifications.functions";

// ---------- base64url / crypto helpers (mirror web-push.server.ts) ----------
function bs(u: Uint8Array): ArrayBuffer {
  return u.buffer.slice(u.byteOffset, u.byteOffset + u.byteLength) as ArrayBuffer;
}
function te(s: string) { return new TextEncoder().encode(s); }
function td(u: Uint8Array) { return new TextDecoder().decode(u); }
function b64uToBytes(s: string): Uint8Array {
  const pad = "=".repeat((4 - (s.length % 4)) % 4);
  const b64 = (s + pad).replace(/-/g, "+").replace(/_/g, "/");
  const raw = atob(b64);
  const out = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
  return out;
}
function b64ToBytes(s: string): Uint8Array {
  const raw = atob(s);
  const out = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
  return out;
}
function bytesToB64u(b: Uint8Array | ArrayBuffer): string {
  const arr = b instanceof Uint8Array ? b : new Uint8Array(b);
  let s = "";
  for (const x of arr) s += String.fromCharCode(x);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
function concat(...parts: Uint8Array[]): Uint8Array {
  const total = parts.reduce((n, p) => n + p.length, 0);
  const out = new Uint8Array(total);
  let o = 0;
  for (const p of parts) { out.set(p, o); o += p.length; }
  return out;
}
async function hkdf(salt: Uint8Array, ikm: Uint8Array, info: Uint8Array, length: number): Promise<Uint8Array> {
  const k1 = await crypto.subtle.importKey("raw", bs(salt), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const prk = new Uint8Array(await crypto.subtle.sign("HMAC", k1, bs(ikm)));
  const k2 = await crypto.subtle.importKey("raw", bs(prk), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const okm = new Uint8Array(await crypto.subtle.sign("HMAC", k2, bs(concat(info, new Uint8Array([1])))));
  return okm.slice(0, length);
}
async function importP256Pub(raw: Uint8Array): Promise<CryptoKey> {
  const jwk = { kty: "EC", crv: "P-256", x: bytesToB64u(raw.slice(1, 33)), y: bytesToB64u(raw.slice(33, 65)), ext: true };
  return crypto.subtle.importKey("jwk", jwk, { name: "ECDH", namedCurve: "P-256" }, false, []);
}

async function decryptWebPush(body: Uint8Array, privJwk: JsonWebKey, uaPubRaw: Uint8Array, authB64u: string): Promise<Uint8Array> {
  // RFC 8188 header
  const salt = body.slice(0, 16);
  const idlen = body[20];
  const asPubRaw = body.slice(21, 21 + idlen);
  const ct = body.slice(21 + idlen);
  const auth = b64uToBytes(authB64u);

  const privKey = await crypto.subtle.importKey("jwk", privJwk, { name: "ECDH", namedCurve: "P-256" }, false, ["deriveBits"]);
  const asPubKey = await importP256Pub(asPubRaw);
  const shared = new Uint8Array(await crypto.subtle.deriveBits({ name: "ECDH", public: asPubKey }, privKey, 256));

  const infoIkm = concat(te("WebPush: info\0"), uaPubRaw, asPubRaw);
  const ikm = await hkdf(auth, shared, infoIkm, 32);
  const cek = await hkdf(salt, ikm, te("Content-Encoding: aes128gcm\0"), 16);
  const nonce = await hkdf(salt, ikm, te("Content-Encoding: nonce\0"), 12);

  const aesKey = await crypto.subtle.importKey("raw", bs(cek), { name: "AES-GCM" }, false, ["decrypt"]);
  const padded = new Uint8Array(await crypto.subtle.decrypt({ name: "AES-GCM", iv: bs(nonce) }, aesKey, bs(ct)));
  // Strip trailing zeros and 0x02 delimiter
  let end = padded.length - 1;
  while (end >= 0 && padded[end] === 0) end--;
  if (padded[end] === 0x02) end--;
  return padded.slice(0, end + 1);
}

// ---------- Auth: bearer super_admin ----------
async function requireSuperAdmin(request: Request): Promise<{ userId: string } | Response> {
  const auth = request.headers.get("authorization") || "";
  if (!auth.startsWith("Bearer ")) return new Response("unauthorized", { status: 401 });
  const token = auth.slice(7);
  if (token.split(".").length !== 3) return new Response("invalid token", { status: 401 });
  const url = process.env.SUPABASE_URL!;
  const key = process.env.SUPABASE_PUBLISHABLE_KEY!;
  const sb = createClient<Database>(url, key, {
    global: {
      fetch: (i, init) => {
        const h = new Headers(init?.headers);
        if (key.startsWith("sb_") && h.get("Authorization") === `Bearer ${key}`) h.delete("Authorization");
        h.set("apikey", key);
        h.set("Authorization", `Bearer ${token}`);
        return fetch(i, { ...init, headers: h });
      },
    },
    auth: { persistSession: false },
  });
  const { data, error } = await sb.auth.getClaims(token);
  if (error || !data?.claims?.sub) return new Response("invalid token", { status: 401 });
  const userId = data.claims.sub as string;
  const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
  const { data: role } = await supabaseAdmin
    .from("user_roles").select("user_id").eq("user_id", userId).eq("role", "super_admin").maybeSingle();
  if (!role) return new Response("forbidden", { status: 403 });
  return { userId };
}

// ---------- Route ----------
export const Route = createFileRoute("/api/public/test/push-e2e")({
  server: {
    handlers: {
      POST: async ({ request }) => {
        const auth = await requireSuperAdmin(request);
        if (auth instanceof Response) return auth;
        const { userId } = auth;

        const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
        const origin = new URL(request.url).origin;

        // 1. Seed subscription
        const keys = await crypto.subtle.generateKey({ name: "ECDH", namedCurve: "P-256" }, true, ["deriveBits"]);
        const privJwk = (await crypto.subtle.exportKey("jwk", keys.privateKey)) as JsonWebKey;
        const pubJwk = (await crypto.subtle.exportKey("jwk", keys.publicKey)) as JsonWebKey;
        const uaPubRaw = concat(new Uint8Array([0x04]), b64uToBytes(pubJwk.x!), b64uToBytes(pubJwk.y!));
        const authBytes = crypto.getRandomValues(new Uint8Array(16));
        const p256dh = bytesToB64u(uaPubRaw);
        const authB64u = bytesToB64u(authBytes);

        const subId = crypto.randomUUID();
        const endpoint = `${origin}/api/public/test/push-sink/${subId}`;

        // push_test_sub row FIRST (sink foreign-keys to it & gates on it).
        await supabaseAdmin.from("push_test_sub").insert({
          id: subId, user_id: userId, priv_jwk: privJwk as never, p256dh, auth: authB64u,
        });
        // push_subscription — override id so the endpoint / decrypt keys align.
        const { error: subErr } = await supabaseAdmin.from("push_subscription").insert({
          id: subId, user_id: userId, endpoint, p256dh, auth: authB64u, user_agent: "e2e-push-test",
        });
        if (subErr) {
          await supabaseAdmin.from("push_test_sub").delete().eq("id", subId);
          return Response.json({ ok: false, stage: "seed", error: subErr.message }, { status: 500 });
        }

        // 2. Trigger enqueueNotification untuk semua tipe.
        const startedAt = new Date();
        const triggered: string[] = [];
        for (const spec of ALL_NOTIFICATION_TYPES) {
          try {
            await enqueueNotification({
              userId,
              tipe: spec.tipe,
              judul: spec.judul,
              body: spec.body,
              link: spec.link,
              dedupeKey: `e2e:${subId}:${spec.tipe}`,
            });
            triggered.push(spec.tipe);
          } catch { /* continue */ }
        }

        // 3. Poll sink hits (up to 30s)
        const expected = new Set(ALL_NOTIFICATION_TYPES.map((t) => t.tipe));
        const decrypted: Array<{ tipe: string; title: string; body: string; url: string; encoding: string }> = [];
        const errors: Array<{ sink_id: string; error: string }> = [];
        const deadline = Date.now() + 30_000;
        const seenSinkIds = new Set<string>();
        const seenTipes = new Set<string>();

        while (Date.now() < deadline && seenTipes.size < expected.size) {
          const { data: rows } = await supabaseAdmin
            .from("push_test_sink").select("id,headers,body_b64,received_at")
            .eq("sub_id", subId).gte("received_at", startedAt.toISOString())
            .order("received_at", { ascending: true });
          for (const r of (rows ?? []) as Array<{ id: string; headers: Record<string, string>; body_b64: string }>) {
            if (seenSinkIds.has(r.id)) continue;
            seenSinkIds.add(r.id);
            const encoding = (r.headers["content-encoding"] || "").toLowerCase();
            try {
              const plain = await decryptWebPush(b64ToBytes(r.body_b64), privJwk, uaPubRaw, authB64u);
              const parsed = JSON.parse(td(plain)) as { title?: string; body?: string; url?: string };
              const title = parsed.title || "";
              const bodyTxt = parsed.body || "";
              const url = parsed.url || "";
              // Match tipe by (title, body) — spec.judul & spec.body kita kirim balik.
              const spec = ALL_NOTIFICATION_TYPES.find((t) => t.judul === title && t.body === bodyTxt);
              const tipe = spec?.tipe ?? `unknown:${title}`;
              seenTipes.add(tipe);
              decrypted.push({ tipe, title, body: bodyTxt, url, encoding });
            } catch (e) {
              errors.push({ sink_id: r.id, error: e instanceof Error ? e.message : String(e) });
            }
          }
          if (seenTipes.size < expected.size) await new Promise((r) => setTimeout(r, 500));
        }

        // 4. Report
        const missing = [...expected].filter((t) => !seenTipes.has(t));
        const perTipe = ALL_NOTIFICATION_TYPES.map((spec) => {
          const hit = decrypted.find((d) => d.tipe === spec.tipe);
          return {
            tipe: spec.tipe,
            triggered: triggered.includes(spec.tipe),
            delivered: !!hit,
            url_ok: hit ? hit.url === spec.link : false,
            encoding_ok: hit ? hit.encoding === "aes128gcm" : false,
          };
        });

        // 5. Cleanup
        await supabaseAdmin.from("push_subscription").delete().eq("id", subId);
        await supabaseAdmin.from("push_test_sink").delete().eq("sub_id", subId);
        await supabaseAdmin.from("push_test_sub").delete().eq("id", subId);

        return Response.json({
          ok: missing.length === 0 && errors.length === 0,
          summary: {
            total_types: ALL_NOTIFICATION_TYPES.length,
            triggered: triggered.length,
            delivered: seenTipes.size,
            missing,
            decrypt_errors: errors.length,
            duration_ms: Date.now() - startedAt.getTime(),
          },
          per_tipe: perTipe,
          errors,
        });
      },
    },
  },
});
