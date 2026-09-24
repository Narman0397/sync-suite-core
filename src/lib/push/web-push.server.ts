// Web Push sender (RFC 8291, aes128gcm) — Cloudflare Worker compatible.
// Menggunakan Web Crypto API (crypto.subtle), TIDAK memakai library Node-only.
// Wajib dipanggil dari handler body server function/route (bukan module scope).
import { supabaseAdmin } from "@/integrations/supabase/client.server";
import { log } from "@/lib/logger";

export type PushPayload = {
  title: string;
  body?: string;
  url?: string;
  tag?: string;
};

// Cast Uint8Array (dengan ArrayBufferLike backing) ke BufferSource untuk Web Crypto API.
// TS 5.7 memisahkan ArrayBuffer vs SharedArrayBuffer, sedangkan Web Crypto hanya menerima ArrayBuffer.
function bs(u: Uint8Array): ArrayBuffer {
  return u.buffer.slice(u.byteOffset, u.byteOffset + u.byteLength) as ArrayBuffer;
}
function te(s: string): Uint8Array {
  return new TextEncoder().encode(s);
}

// ================= base64url helpers =================
function b64uToBytes(s: string): Uint8Array {
  const pad = "=".repeat((4 - (s.length % 4)) % 4);
  const b64 = (s + pad).replace(/-/g, "+").replace(/_/g, "/");
  const raw = atob(b64);
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
  for (const p of parts) {
    out.set(p, o);
    o += p.length;
  }
  return out;
}

// ================= HKDF (SHA-256) =================
async function hkdf(
  salt: Uint8Array,
  ikm: Uint8Array,
  info: Uint8Array,
  length: number,
): Promise<Uint8Array> {
  const key = await crypto.subtle.importKey("raw", bs(salt), { name: "HMAC", hash: "SHA-256" }, false, [
    "sign",
  ]);
  const prk = new Uint8Array(await crypto.subtle.sign("HMAC", key, bs(ikm)));
  const prkKey = await crypto.subtle.importKey(
    "raw",
    bs(prk),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const infoAndCounter = concat(info, new Uint8Array([1]));
  const okm = new Uint8Array(await crypto.subtle.sign("HMAC", prkKey, bs(infoAndCounter)));
  return okm.slice(0, length);
}

// ================= P-256 keys =================
// public key: 65-byte uncompressed (0x04||X||Y). Convert to JWK for import.
async function importP256Public(rawUncompressed: Uint8Array): Promise<CryptoKey> {
  if (rawUncompressed.length !== 65 || rawUncompressed[0] !== 0x04) {
    throw new Error("invalid P-256 public key");
  }
  const jwk = {
    kty: "EC",
    crv: "P-256",
    x: bytesToB64u(rawUncompressed.slice(1, 33)),
    y: bytesToB64u(rawUncompressed.slice(33, 65)),
    ext: true,
  };
  return crypto.subtle.importKey("jwk", jwk, { name: "ECDH", namedCurve: "P-256" }, false, []);
}
async function exportP256PublicRaw(key: CryptoKey): Promise<Uint8Array> {
  const jwk = (await crypto.subtle.exportKey("jwk", key)) as JsonWebKey;
  return concat(new Uint8Array([0x04]), b64uToBytes(jwk.x!), b64uToBytes(jwk.y!));
}

// ================= Encrypt payload (aes128gcm) =================
async function encryptPayload(
  payload: Uint8Array,
  subP256dhB64u: string,
  subAuthB64u: string,
): Promise<{ body: Uint8Array; asPublicRaw: Uint8Array }> {
  const uaPubRaw = b64uToBytes(subP256dhB64u); // 65 bytes
  const auth = b64uToBytes(subAuthB64u); // 16 bytes

  // 1. ephemeral ECDH keypair (application server side).
  const asKeys = await crypto.subtle.generateKey({ name: "ECDH", namedCurve: "P-256" }, true, [
    "deriveBits",
  ]);
  const asPublicRaw = await exportP256PublicRaw(asKeys.publicKey);
  const uaPubKey = await importP256Public(uaPubRaw);

  // 2. shared ECDH secret.
  const shared = new Uint8Array(
    await crypto.subtle.deriveBits({ name: "ECDH", public: uaPubKey }, asKeys.privateKey, 256),
  );

  // 3. RFC 8291 §3.4 — IKM = HKDF(auth, shared, "WebPush: info\0"||uaPub||asPub, 32)
  const infoIkm = concat(
    te("WebPush: info\0"),
    uaPubRaw,
    asPublicRaw,
  );
  const ikm = await hkdf(auth, shared, infoIkm, 32);

  // 4. Random 16-byte salt. CEK & nonce via HKDF w/ salt & ikm.
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const cek = await hkdf(salt, ikm, te("Content-Encoding: aes128gcm\0"), 16);
  const nonce = await hkdf(salt, ikm, te("Content-Encoding: nonce\0"), 12);

  // 5. Pad + encrypt (0x02 = last-record delimiter, no additional padding).
  const padded = concat(payload, new Uint8Array([0x02]));
  const aesKey = await crypto.subtle.importKey("raw", bs(cek), { name: "AES-GCM" }, false, ["encrypt"]);
  const ct = new Uint8Array(
    await crypto.subtle.encrypt({ name: "AES-GCM", iv: bs(nonce) }, aesKey, bs(padded)),
  );

  // 6. Header (RFC 8188 §2.1): salt(16) || rs(4, BE=4096) || idlen(1)=65 || keyid(asPublicRaw)
  const rs = new Uint8Array([0x00, 0x00, 0x10, 0x00]);
  const header = concat(salt, rs, new Uint8Array([asPublicRaw.length]), asPublicRaw);
  return { body: concat(header, ct), asPublicRaw };
}

// ================= VAPID JWT (ES256) =================
async function importVapidPrivate(dB64u: string, pubRaw: Uint8Array): Promise<CryptoKey> {
  const jwk: JsonWebKey = {
    kty: "EC",
    crv: "P-256",
    d: dB64u,
    x: bytesToB64u(pubRaw.slice(1, 33)),
    y: bytesToB64u(pubRaw.slice(33, 65)),
    ext: true,
  };
  return crypto.subtle.importKey(
    "jwk",
    jwk,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
}

async function signVapidJwt(
  audience: string,
  subject: string,
  vapidPrivKey: CryptoKey,
): Promise<string> {
  const header = { alg: "ES256", typ: "JWT" };
  const claims = {
    aud: audience,
    exp: Math.floor(Date.now() / 1000) + 12 * 60 * 60,
    sub: subject,
  };
  const enc = (o: unknown) => bytesToB64u(te(JSON.stringify(o)));
  const signingInput = `${enc(header)}.${enc(claims)}`;
  const sigDer = new Uint8Array(
    await crypto.subtle.sign(
      { name: "ECDSA", hash: "SHA-256" },
      vapidPrivKey,
      bs(te(signingInput)),
    ),
  );
  return `${signingInput}.${bytesToB64u(sigDer)}`;
}

// ================= Public API =================
export type StoredSubscription = {
  id: string;
  endpoint: string;
  p256dh: string;
  auth: string;
};

async function loadVapid(): Promise<{ pubRaw: Uint8Array; privKey: CryptoKey; subject: string } | null> {
  const pub = process.env.VAPID_PUBLIC_KEY;
  const priv = process.env.VAPID_PRIVATE_KEY;
  const subject = process.env.VAPID_SUBJECT || "mailto:admin@lovable.app";
  if (!pub || !priv) {
    log.warn("push.vapid.missing_env");
    return null;
  }
  const pubRaw = b64uToBytes(pub);
  const privKey = await importVapidPrivate(priv, pubRaw);
  return { pubRaw, privKey, subject };
}

async function deleteSubscription(id: string) {
  await supabaseAdmin.from("push_subscription").delete().eq("id", id);
}

/** Kirim satu payload ke satu subscription. Return HTTP status. */
export async function sendWebPush(
  sub: StoredSubscription,
  payload: PushPayload,
  vapid: { pubRaw: Uint8Array; privKey: CryptoKey; subject: string },
): Promise<number> {
  const body = te(JSON.stringify(payload));
  const { body: cipher } = await encryptPayload(body, sub.p256dh, sub.auth);

  const url = new URL(sub.endpoint);
  const audience = `${url.protocol}//${url.host}`;
  const jwt = await signVapidJwt(audience, vapid.subject, vapid.privKey);

  const res = await fetch(sub.endpoint, {
    method: "POST",
    headers: {
      TTL: "60",
      Urgency: "normal",
      "Content-Encoding": "aes128gcm",
      "Content-Type": "application/octet-stream",
      "Content-Length": String(cipher.length),
      Authorization: `vapid t=${jwt}, k=${bytesToB64u(vapid.pubRaw)}`,
    },
    body: bs(cipher) as BodyInit,
  });

  if (res.status === 404 || res.status === 410) {
    await deleteSubscription(sub.id);
    log.info("push.subscription.gone", { id: sub.id, status: res.status });
  } else if (res.status === 403) {
    // VAPID key mismatch — subscription created with different public key; drop.
    await deleteSubscription(sub.id);
    log.warn("push.subscription.forbidden", { id: sub.id });
  } else if (res.status >= 500) {
    log.warn("push.transient", { id: sub.id, status: res.status });
  } else if (res.status >= 400) {
    const text = await res.text().catch(() => "");
    log.warn("push.error", { id: sub.id, status: res.status, text: text.slice(0, 200) });
  }
  return res.status;
}

/** Kirim payload ke semua subscription milik userId. Fire-and-log. */
export async function sendWebPushToUser(userId: string, payload: PushPayload): Promise<void> {
  const vapid = await loadVapid();
  if (!vapid) return;
  const { data: subs, error } = await supabaseAdmin
    .from("push_subscription")
    .select("id,endpoint,p256dh,auth")
    .eq("user_id", userId);
  if (error || !subs || subs.length === 0) return;
  await Promise.allSettled(
    (subs as StoredSubscription[]).map((s) =>
      sendWebPush(s, payload, vapid).catch((e) =>
        log.warn("push.send.throw", { id: s.id, error: e instanceof Error ? e.message : String(e) }),
      ),
    ),
  );
}

/** Kirim payload berbeda per-user secara paralel. */
export async function sendWebPushToMany(
  items: Array<{ userId: string; payload: PushPayload }>,
): Promise<void> {
  if (items.length === 0) return;
  const vapid = await loadVapid();
  if (!vapid) return;
  const userIds = Array.from(new Set(items.map((i) => i.userId)));
  const { data: subs, error } = await supabaseAdmin
    .from("push_subscription")
    .select("id,user_id,endpoint,p256dh,auth")
    .in("user_id", userIds);
  if (error || !subs || subs.length === 0) return;
  const byUser = new Map<string, StoredSubscription[]>();
  for (const s of subs as Array<StoredSubscription & { user_id: string }>) {
    const arr = byUser.get(s.user_id) ?? [];
    arr.push({ id: s.id, endpoint: s.endpoint, p256dh: s.p256dh, auth: s.auth });
    byUser.set(s.user_id, arr);
  }
  const tasks: Promise<unknown>[] = [];
  for (const { userId, payload } of items) {
    const list = byUser.get(userId);
    if (!list) continue;
    for (const s of list) {
      tasks.push(
        sendWebPush(s, payload, vapid).catch((e) =>
          log.warn("push.send.throw", { id: s.id, error: e instanceof Error ? e.message : String(e) }),
        ),
      );
    }
  }
  await Promise.allSettled(tasks);
}
