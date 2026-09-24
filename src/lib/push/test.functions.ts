// Server function untuk mengirim push notifikasi tes ke diri sendiri.
// Mengembalikan jumlah subscription yang ditargetkan + hasil per-endpoint
// sehingga UI dapat memberi feedback bermakna kalau device belum
// terdaftar / VAPID mismatch / permission dicabut oleh browser.
import { createServerFn } from "@tanstack/react-start";
import { requireSupabaseAuth } from "@/lib/supabase-auth-middleware";

export const sendTestPush = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { userId } = context as { userId: string };
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { data: subs } = await supabaseAdmin
      .from("push_subscription")
      .select("id,endpoint,p256dh,auth")
      .eq("user_id", userId);
    const list = (subs ?? []) as Array<{
      id: string;
      endpoint: string;
      p256dh: string;
      auth: string;
    }>;
    if (list.length === 0) {
      return { total: 0, ok: 0, failed: 0, statuses: [] as number[] };
    }
    const { sendWebPush } = await import("@/lib/push/web-push.server");
    const vapidPub = process.env.VAPID_PUBLIC_KEY;
    const vapidPriv = process.env.VAPID_PRIVATE_KEY;
    const vapidSub = process.env.VAPID_SUBJECT || "mailto:admin@lovable.app";
    if (!vapidPub || !vapidPriv) {
      throw new Error("Server belum dikonfigurasi VAPID_PUBLIC_KEY / VAPID_PRIVATE_KEY");
    }
    // Load VAPID once (mirroring internal loader behaviour).
    const b64u = (s: string) => {
      const pad = "=".repeat((4 - (s.length % 4)) % 4);
      const b = (s + pad).replace(/-/g, "+").replace(/_/g, "/");
      const raw = atob(b);
      const out = new Uint8Array(raw.length);
      for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
      return out;
    };
    const bytesToB64u = (arr: Uint8Array) => {
      let s = "";
      for (const x of arr) s += String.fromCharCode(x);
      return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
    };
    const pubRaw = b64u(vapidPub);
    const jwk: JsonWebKey = {
      kty: "EC",
      crv: "P-256",
      d: vapidPriv,
      x: bytesToB64u(pubRaw.slice(1, 33)),
      y: bytesToB64u(pubRaw.slice(33, 65)),
      ext: true,
    };
    const privKey = await crypto.subtle.importKey(
      "jwk",
      jwk,
      { name: "ECDSA", namedCurve: "P-256" },
      false,
      ["sign"],
    );
    const vapid = { pubRaw, privKey, subject: vapidSub };
    const payload = {
      title: "Tes notifikasi",
      body: "Notifikasi push berhasil terkirim ke perangkat ini.",
      url: "/notifikasi",
      tag: "test-push",
    };
    const results = await Promise.all(list.map((s) => sendWebPush(s, payload, vapid).catch(() => 0)));
    const ok = results.filter((s) => s >= 200 && s < 300).length;
    return {
      total: list.length,
      ok,
      failed: list.length - ok,
      statuses: results,
    };
  });
