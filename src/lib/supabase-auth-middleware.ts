// Pengganti `requireSupabaseAuth` bawaan (auto-generated) dengan verifikasi
// yang tahan-banting di runtime Cloudflare Workers.
//
// ROOT CAUSE "Unauthorized: Invalid token" di production:
// middleware bawaan memakai `auth.getClaims(token)` yang memverifikasi tanda
// tangan JWT secara LOKAL memakai JWKS. Verifikasi lokal itu gagal bila:
//   1) proyek backend production masih memakai JWT secret simetris (HS256) —
//      tidak ada kunci publik untuk diverifikasi di edge;
//   2) SUPABASE_URL pada Worker menunjuk proyek yang BERBEDA dengan proyek
//      tempat browser login (issuer token ≠ issuer JWKS) → selalu invalid;
//   3) cache JWKS kosong / gagal di-fetch saat cold start Worker.
//
// Solusi: verifikasi token ke server Auth (`auth.getUser(token)`), yang
// otoritatif untuk semua algoritma penandatanganan, dan deteksi eksplisit
// ketidakcocokan issuer supaya pesan errornya bisa ditindaklanjuti.
import { createMiddleware } from "@tanstack/react-start";
import { getRequest } from "@tanstack/react-start/server";
import { createClient } from "@supabase/supabase-js";
import type { Database } from "@/integrations/supabase/types";

function isNewSupabaseApiKey(value: string): boolean {
  return value.startsWith("sb_publishable_") || value.startsWith("sb_secret_");
}

function createSupabaseFetch(supabaseKey: string): typeof fetch {
  return (input, init) => {
    const headers = new Headers(
      typeof Request !== "undefined" && input instanceof Request ? input.headers : undefined,
    );
    if (init?.headers) {
      new Headers(init.headers).forEach((value, key) => headers.set(key, value));
    }
    // Kunci API format baru bersifat opaque, bukan bearer JWT.
    if (
      isNewSupabaseApiKey(supabaseKey) &&
      headers.get("Authorization") === `Bearer ${supabaseKey}`
    ) {
      headers.delete("Authorization");
    }
    headers.set("apikey", supabaseKey);
    return fetch(input, { ...init, headers });
  };
}

function decodeJwtPayload(token: string): Record<string, unknown> | null {
  try {
    const raw = token.split(".")[1];
    const json = atob(raw.replace(/-/g, "+").replace(/_/g, "/"));
    return JSON.parse(json) as Record<string, unknown>;
  } catch {
    return null;
  }
}

export const requireSupabaseAuth = createMiddleware({ type: "function" }).server(
  async ({ next }) => {
    const SUPABASE_URL = process.env.SUPABASE_URL;
    const SUPABASE_PUBLISHABLE_KEY = process.env.SUPABASE_PUBLISHABLE_KEY;

    if (!SUPABASE_URL || !SUPABASE_PUBLISHABLE_KEY) {
      const missing = [
        ...(!SUPABASE_URL ? ["SUPABASE_URL"] : []),
        ...(!SUPABASE_PUBLISHABLE_KEY ? ["SUPABASE_PUBLISHABLE_KEY"] : []),
      ];
      throw new Error(
        `Konfigurasi backend belum lengkap di server: ${missing.join(", ")} tidak ditemukan.`,
      );
    }

    const request = getRequest();
    const authHeader = request?.headers?.get("authorization");
    if (!authHeader) throw new Error("Unauthorized: No authorization header provided");
    if (!authHeader.startsWith("Bearer "))
      throw new Error("Unauthorized: Only Bearer tokens are supported");

    const token = authHeader.slice("Bearer ".length).trim();
    if (!token) throw new Error("Unauthorized: No token provided");
    if (token.split(".").length !== 3) throw new Error("Unauthorized: Malformed token");

    const payload = decodeJwtPayload(token);
    const issuer = typeof payload?.iss === "string" ? payload.iss : null;
    const expectedIssuer = `${SUPABASE_URL.replace(/\/$/, "")}/auth/v1`;
    if (issuer && issuer !== expectedIssuer) {
      // Bisa terjadi secara sah bila klien memakai domain proxy/gateway yang
      // berbeda teks dengan SUPABASE_URL server. Jangan langsung tolak —
      // biarkan verifikasi otoritatif `auth.getUser(token)` di bawah yang
      // memutuskan valid/tidaknya sesi.
      console.warn(`[auth] issuer differs: token=${issuer} server=${expectedIssuer}`);
    }

    const supabase = createClient<Database>(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
      global: {
        fetch: createSupabaseFetch(SUPABASE_PUBLISHABLE_KEY),
        headers: { Authorization: `Bearer ${token}` },
      },
      auth: { storage: undefined, persistSession: false, autoRefreshToken: false },
    });

    // Verifikasi otoritatif ke server Auth (berlaku untuk HS256 maupun ES256).
    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data?.user?.id) {
      console.error(`[auth] getUser failed: ${error?.message ?? "no user"}`);
      throw new Error(
        error?.status === 401 || !error
          ? "Unauthorized: Invalid token"
          : `Unauthorized: gagal memvalidasi sesi (${error.message})`,
      );
    }

    return next({
      context: {
        supabase,
        userId: data.user.id,
        claims: (payload ?? { sub: data.user.id }) as Record<string, unknown> & { sub: string },
      },
    });
  },
);
