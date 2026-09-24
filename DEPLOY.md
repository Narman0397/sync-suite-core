# Deploy ke Cloudflare Workers + Supabase Pribadi

Halaman "Terjadi kesalahan" di production = SSR Worker throw karena env Supabase
belum lengkap. Ada **dua** set env yang WAJIB ada di dua momen yang berbeda.

## 1. Build-time (VITE_*) — di-inline ke bundle browser

`VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY`, `VITE_SUPABASE_PROJECT_ID`
di-baca oleh Vite ketika `bun run build` berjalan, lalu ditanam ke JS browser.
Setelah build selesai, mengubah nilai ini tidak berpengaruh — harus rebuild.

> Repo ini TIDAK menyimpan kredensial backend apa pun (tidak ada nilai fallback
> di `vite.config.ts`). Kalau ketiga variabel di atas kosong saat build
> produksi, build sengaja GAGAL dengan pesan yang menyebut variabel yang
> hilang — supaya bundle klien tidak pernah menunjuk backend development
> sementara Worker menunjuk backend produksi.

Pilih SALAH SATU cara:


### A. Build di lokal, deploy dari lokal
```bash
cp .env.example .env
# isi VITE_SUPABASE_* dengan kredensial Supabase pribadi Anda
bun install
bun run build
wrangler deploy
```

### B. Build di Cloudflare Workers Builds (CI dari GitHub)
Di dashboard Cloudflare → Workers & Pages → project Anda → Settings →
**Build** → **Build variables and secrets**, tambahkan:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`
- `VITE_SUPABASE_PROJECT_ID`

(Ini variable build, bukan runtime — cuma dipakai saat `bun run build` di CI.)

## 2. Runtime (SUPABASE_* tanpa VITE_) — dipakai Worker saat request

Server function, `requireSupabaseAuth`, dan `supabaseAdmin` membaca nilai ini
dari `process.env`. Di Cloudflare, vars/secret hanya tersalin ke `process.env`
bila `compatibility_date >= 2025-04-01` (+ flag `nodejs_compat_populate_process_env`);
`src/server.ts` juga menyalin `env` → `process.env` di awal tiap request.
Set sebagai **secret** (bukan var biasa) di worker ini:


```bash
wrangler secret put SUPABASE_URL
wrangler secret put SUPABASE_PUBLISHABLE_KEY
wrangler secret put SUPABASE_SERVICE_ROLE_KEY
wrangler secret put SUPABASE_PROJECT_ID
```

> Worker staging/dev terpisah TIDAK boleh dibuat lewat blok `[env.*]` di
> `wrangler.toml` — nitro menyalinnya ke `dist/server/wrangler.json` dan
> Cloudflare menolak redirected config yang punya environment. Pakai file
> config terpisah (`wrangler.dev.toml`, nama worker berbeda, tetap datar):
> `wrangler deploy --config wrangler.dev.toml`.


Cek isi:
```bash
wrangler secret list
```

## 3. Auth redirect

Di dashboard Supabase pribadi → Authentication → URL Configuration, tambahkan
domain Worker (mis. `https://narmanportofolio.site` dan `https://*.workers.dev`)
ke **Site URL** & **Redirect URLs**.

## Checklist saat halaman "Terjadi kesalahan" muncul

1. `wrangler secret list` → apakah 4 secret di atas ada?
2. Buka DevTools → Network → refresh → lihat response HTML root: apakah 500?
3. Cek log runtime: `wrangler tail`
   → biasanya kelihatan `Missing Supabase environment variable(s): ...`
4. Kalau log kosong tapi 500 tetap muncul, VITE_* saat build kosong —
   rebuild dengan `.env` terisi lalu redeploy.

## Alur cepat "fix from zero"

```bash
# 1. Isi build vars lokal
cp .env.example .env
$EDITOR .env

# 2. Set runtime secrets Worker
for k in SUPABASE_URL SUPABASE_PUBLISHABLE_KEY SUPABASE_SERVICE_ROLE_KEY SUPABASE_PROJECT_ID; do
  wrangler secret put $k
done

# 3. Rebuild + deploy
bun run build
wrangler deploy

# 4. Verifikasi
wrangler tail
```
