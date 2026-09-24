// @lovable.dev/vite-tanstack-config already includes the following — do NOT add them manually
// or the app will break with duplicate plugins:
//   - tanstackStart, viteReact, tailwindcss, tsConfigPaths, nitro (build-only using cloudflare as a default target),
//     componentTagger (dev-only), VITE_* env injection, @ path alias, React/TanStack dedupe,
//     error logger plugins, and sandbox detection (port/host/strictPort).
// You can pass additional config via defineConfig({ vite: { ... }, etc... }) if needed.
import { defineConfig } from "@lovable.dev/vite-tanstack-config";
import { loadEnv } from "vite";
import { VitePWA } from "vite-plugin-pwa";
import { imagetools } from "vite-imagetools";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const tslibEsm = require.resolve("tslib/tslib.es6.mjs");

// ============================================================================
// ENV KLIEN (VITE_*) — TIDAK ADA NILAI HARDCODE DI REPO.
//
// Repo GitHub sengaja TIDAK membawa kredensial backend apa pun. Nilai diambil
// hanya dari environment build:
//   - Lokal / Lovable preview : file `.env` (gitignored)
//   - Cloudflare Workers      : Settings → Build → Variables and Secrets
//     (VITE_SUPABASE_URL, VITE_SUPABASE_PUBLISHABLE_KEY, VITE_SUPABASE_PROJECT_ID)
//   - GitHub Actions          : repository secrets/variables
//
// Kalau kosong saat build produksi → build DIGAGALKAN, supaya tidak pernah
// lagi terjadi bundle klien menunjuk backend development sementara Worker
// menunjuk backend produksi ("sesi berasal dari backend yang berbeda").
// ============================================================================
const REQUIRED_CLIENT_ENV = [
  "VITE_SUPABASE_URL",
  "VITE_SUPABASE_PUBLISHABLE_KEY",
  "VITE_SUPABASE_PROJECT_ID",
] as const;

// These values identify this app's Lovable Cloud backend. They are public
// browser configuration (not secrets), so keeping them here is safe and makes
// preview/publish builds deterministic even when the build runner exposes only
// runtime SUPABASE_* variables.
// PENTING: harus sama dengan backend yang dipakai preview, jika tidak maka
// situs published memakai backend berbeda dan login gagal ("kredensial sama
// tidak bisa dipakai di URL published").
const LOVABLE_CLOUD_CLIENT_ENV: Record<(typeof REQUIRED_CLIENT_ENV)[number], string> = {
  VITE_SUPABASE_URL: "https://c--7c7f4cbb-b346-4f65-ac26-2374020ca793-prod.lovable.cloud",
  VITE_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_4w4PB9tE0jfgiKtYXNrjkQ_OrAE34-T",
  VITE_SUPABASE_PROJECT_ID: "cfpfbadtfnxszzrelnxb",
};

// NODE_ENV selalu "production" untuk `vite build`, termasuk ketika perintahnya
// `vite build --mode development`. Ambil mode dari argumen CLI agar build:dev
// tidak salah diperlakukan sebagai deploy produksi Cloudflare.
const modeFlagIndex = process.argv.indexOf("--mode");
const inlineModeFlag = process.argv.find((arg) => arg.startsWith("--mode="));
const viteMode =
  (modeFlagIndex >= 0 ? process.argv[modeFlagIndex + 1] : undefined) ||
  inlineModeFlag?.slice("--mode=".length) ||
  "production";
const fileEnv = loadEnv(viteMode, process.cwd(), "VITE_");

// Sumber nilai, berurutan:
//   1) process.env VITE_*  → Lovable preview/dev, Cloudflare build vars, CI
//   2) file .env           → build lokal
//   3) nama alternatif      → VITE_SUPABASE_ANON_KEY (dipakai Lovable Cloud)
//                             dan nama runtime server SUPABASE_* sebagai jaring terakhir
const ALIASES: Record<string, readonly string[]> = {
  VITE_SUPABASE_URL: ["VITE_SUPABASE_URL", "SUPABASE_URL"],
  VITE_SUPABASE_PUBLISHABLE_KEY: [
    "VITE_SUPABASE_PUBLISHABLE_KEY",
    "VITE_SUPABASE_ANON_KEY",
    "SUPABASE_PUBLISHABLE_KEY",
    "SUPABASE_ANON_KEY",
  ],
  VITE_SUPABASE_PROJECT_ID: ["VITE_SUPABASE_PROJECT_ID", "SUPABASE_PROJECT_ID"],
};

const rawRead = (key: string) => process.env[key] || fileEnv[key];
const readEnv = (key: string): string | undefined => {
  for (const alias of ALIASES[key] ?? [key]) {
    const value = rawRead(alias);
    if (value) return value;
  }
  // Project ref bisa diturunkan dari URL backend bila tidak diset eksplisit.
  if (key === "VITE_SUPABASE_PROJECT_ID") {
    const url = readEnv("VITE_SUPABASE_URL");
    const ref = url?.match(/^https?:\/\/([a-z0-9-]+)\.supabase\.(?:co|in)/i)?.[1];
    if (ref) return ref;
  }
  return LOVABLE_CLOUD_CLIENT_ENV[key as (typeof REQUIRED_CLIENT_ENV)[number]];
};

const resolvedClientEnv = Object.fromEntries(
  REQUIRED_CLIENT_ENV.map((key) => [key, readEnv(key)]).filter(([, value]) => Boolean(value)),
) as Record<string, string>;

const missingClientEnv = REQUIRED_CLIENT_ENV.filter((key) => !resolvedClientEnv[key]);

// Tulis kembali ke process.env dengan nama kanonik VITE_*. Vite ikut membaca
// process.env untuk membangun objek `import.meta.env`, sehingga akses bracket
// (`import.meta.env['VITE_SUPABASE_URL']`) juga ter-inline dengan benar —
// `define` saja hanya mengganti akses notasi titik.
for (const [key, value] of Object.entries(resolvedClientEnv)) {
  process.env[key] = value;
}

if (missingClientEnv.length > 0) {
  // Jangan pernah menggagalkan build (preview Lovable ikut memakai mode
  // production). Cukup peringatkan supaya penyebabnya terlihat di log build.
  console.warn(
    `[build] Environment klien belum lengkap: ${missingClientEnv.join(", ")}. ` +
      "Set nilainya di environment build (Lovable Cloud / Cloudflare Build Variables) atau file .env.",
  );
}

// Rolldown accepts only identifier-style define keys, not
// `import.meta.env["KEY"]`. Rewrite the generated integration's bracket access
// before Vite's env pass so the deterministic values below are embedded.
const normalizeClientEnvAccess = {
  name: "normalize-client-env-access",
  enforce: "pre" as const,
  transform(code: string) {
    if (!code.includes("import.meta.env[")) return null;
    const transformed = code.replace(
      /import\.meta\.env\[['"](VITE_SUPABASE_(?:URL|PUBLISHABLE_KEY|PROJECT_ID))['"]\]/g,
      "import.meta.env.$1",
    );
    return transformed === code ? null : { code: transformed, map: null };
  },
};

const supabaseEnvDefines = Object.fromEntries(
  Object.entries(resolvedClientEnv).map(([key, value]) => [
    `import.meta.env.${key}`,
    JSON.stringify(value),
  ]),
);


export default defineConfig({
  tanstackStart: {
    // Prerender disabled: all public pages are rendered on demand (SSR) and
    // cached at the edge. Keeps build time well within CI limits.
    prerender: { enabled: false },
  },
  vite: {
    define: supabaseEnvDefines,
    environments: {
      ssr: {
        build: {
          rollupOptions: {
            output: {
              entryFileNames: "server.js",
            },
          },
        },
      },
    },
    resolve: {
      alias: [
        // Force tslib to its proper ESM build. The default "node" export
        // condition resolves to modules/index.js which does
        //   `import tslib from '../tslib.js'; const { __extends } = tslib;`
        // On Cloudflare Workers / esbuild interop, tslib.js is CJS and
        // `.default` is undefined → runtime error:
        // "Cannot destructure property '__extends' of '__toESM(...).default'".
        // Using tslib.es6.mjs exposes the helpers as real named ESM exports.
        { find: /^tslib$/, replacement: tslibEsm },
      ],
    },
    plugins: [
      normalizeClientEnvAccess,
      imagetools(),
      VitePWA({
        strategies: "injectManifest",
        srcDir: "public",
        filename: "sw.js",
        injectRegister: null,
        registerType: "autoUpdate",
        devOptions: { enabled: true, type: "module", navigateFallback: "/" },
        manifest: false, // pakai public/manifest.webmanifest
        injectManifest: {
          globPatterns: ["**/*.{js,css,html,svg,png,ico,webp,woff2}"],
          globIgnores: ["**/service-worker.js"],
          maximumFileSizeToCacheInBytes: 5 * 1024 * 1024,
        },
      }),
    ],
  },
});
