# Cloud Sync Pro

Saya upload file Zip berisi source lengkap proyek TanStack Start + Supabase. Tolong clone & deploy 1:1 persis ke proyek baru ini dengan Lovable Cloud backend baru. Wajib identik dengan sumber — schema, data referensi, kode, konfigurasi. Kalau ada bagian yang rusak, korup, atau gagal di tengah proses clone, perbaiki otomatis sampai tuntas tanpa berhenti minta konfirmasi (kecuali butuh secret dari user). Ikuti urutan berikut tanpa skip:

---

1. Ekstrak & Sinkronisasi Source

- Ekstrak Zip ke `/tmp/import/`, verifikasi tidak ada folder `.git` yang tersalin. Kalau checksum file rusak / Zip corrupt, minta re-upload; jangan lanjut.
- Rsync seluruh isi ke `/dev-server/` dengan `--exclude='.git' --exclude='node_modules' --exclude='dist' --exclude='.output'`, kecuali file auto-generated berikut yang JANGAN ditimpa:
  - `src/integrations/supabase/client.ts`
  - `src/integrations/supabase/client.server.ts`
  - `src/integrations/supabase/auth-middleware.ts`
  - `src/integrations/supabase/auth-attacher.ts`
  - `src/integrations/supabase/types.ts` ← akan di-regenerate paling akhir
  - `.env` (VITE_SUPABASE_*)
  - `supabase/config.toml`
  - `src/routeTree.gen.ts`
- Diff hasil rsync vs sumber untuk file non-excluded — harus 0 selisih byte. Kalau ada selisih, ulang rsync sampai bersih.
- Jalankan `bun install`. Kalau gagal (lockfile mismatch, package hilang), retry dengan `bun install --force`; kalau tetap gagal, laporkan package yang bermasalah dan lanjut ke langkah berikutnya hanya jika error non-fatal.

2. Provision Backend

- Aktifkan Lovable Cloud (Supabase baru) via `supabase--enable`.
- Verifikasi koneksi DB lewat `psql -c "SELECT 1"` sebelum lanjut.

3. Apply Semua Migrasi (`supabase/migrations/`)

- Buat schema `_mig` + tabel `_mig.applied(filename text primary key)` + fungsi `_mig.exec(sql text)` `SECURITY DEFINER` untuk bypass permission `public`.
- Runner Python multi-pass:
  - Eksekusi tiap file `.sql` secara individual (bukan batch — banyak file redefine helper dengan signature bentrok).
  - Timeout 20s per file.
  - Retry lintas-pass sampai konvergen (tidak ada file baru yang berhasil di pass terakhir).
  - Flag `--benign` untuk skip error "already exists" / "duplicate object".
- File yang gagal karena dependency `auth.*` trigger atau objek yang memang tidak ada di Zip: tandai manual applied di `_mig.applied` setelah dicek bukan tabel bisnis inti (log alasannya).
- Target: 100% file tercatat applied. Kalau ada file bisnis yang tetap gagal, dump error terakhir + coba perbaikan otomatis (mis. buat dependency yang hilang, urutkan ulang) sampai lolos.

4. Perbaikan Schema Pasca-Migrasi (auto-repair)

Semua langkah di bawah wajib dijalankan tanpa menunggu konfirmasi:

- Restorasi Primary Key: iterasi semua tabel `public.*` yang kolom `id` belum PK — set `NOT NULL`, default `gen_random_uuid()`, tambah `PRIMARY KEY (id)`.
- Restorasi Foreign Key: parse ulang seluruh `REFERENCES` inline dari migrasi, apply ulang via `DO` block dengan fallback `NOT VALID`. Tambah B-tree index untuk tiap kolom FK. Target minimum: ≥99 FK aktif, termasuk `permohonan.opd_id→opd.id`, `permohonan.pemohon_id→profiles.id`. Kalau FK gagal karena data yatim, purge baris yatim lalu retry.
- GRANT publik:
  ```sql
  GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
  GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
  GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
  ```
  Set `ALTER DEFAULT PRIVILEGES` untuk objek masa depan.
- RLS SELECT policies: audit `pg_policy` vs `pg_class.relrowsecurity`; untuk tabel RLS-enabled tanpa policy, tambah minimal `SELECT` untuk `authenticated`, plus `anon` untuk tabel landing (`layanan_publik`, `data_terpadu_item`, `permohonan_rating`, `berita`, `opd`).
- Function hardening: pastikan semua `SECURITY DEFINER` di `public` punya `SET search_path = public`, dan `REVOKE EXECUTE ... FROM anon, PUBLIC` untuk fungsi sensitif.
- Reload PostgREST schema cache: `NOTIFY pgrst, 'reload schema'`.
- Jalankan `supabase--linter` — perbaiki semua warning terkait perubahan di atas.

5. Seed 4 Akun Uji Terverifikasi (password: `Poogalampa97`)

- `narman208@gmail.com` — `super_admin`
- `narman3397@gmail.com` — `asn`
- `narman33970011@gmail.com` — `admin_desa`
- `narman33970012@gmail.com` — `warga`

Gunakan `DO` block: upsert ke `auth.users` (pakai `extensions.crypt`), `auth.identities`, `public.profiles` (status `verified`), `public.user_roles`. Idempotent — aman dijalankan ulang.

6. Seed Data Referensi & Demo (dari Zip)

- Jalankan semua file seed / `INSERT` yang ada di Zip (mis. `supabase/seed/`, atau `INSERT` di dalam migrasi) sehingga isi tabel referensi (OPD, desa, layanan_publik, hari_libur, berita, data_terpadu_item, branding) identik dengan sumber.
- Verifikasi row-count per tabel referensi vs manifest sumber (kalau ada). Kalau selisih, ulang seed.

7. Verifikasi Kode (SEBELUM regenerate types)

- Jalankan `tsgo --noEmit`. Error tipe akibat `types.ts` masih lama = diharapkan dan diabaikan di langkah ini — jangan tambah `@ts-nocheck`, jangan edit kode aplikasi untuk "memperbaiki" error tipe di sini.
- Catat baseline error count untuk perbandingan pasca-regenerate.

8. Regenerate `types.ts` (PALING AKHIR — setelah semua langkah 1–7 selesai)

Ini titik kritis. Types.ts HARUS di-regenerate paling akhir, setelah: source ter-sync (1), backend aktif (2), semua migrasi applied (3), schema di-repair (4), akun seed dibuat (5), data referensi masuk (6), dan kode diverifikasi (7). Regenerate lebih awal = types tidak mencerminkan schema final.

- Trigger regenerate `src/integrations/supabase/types.ts` via `supabase--migration` (comment no-op yang memicu regenerator).
- Verifikasi `types.ts` sekarang berisi semua tabel `public.*` (bandingkan dengan `information_schema.tables`). Kalau ada tabel hilang di types, ulang trigger.

9. Verifikasi Build Akhir

- Jalankan `tsgo --noEmit` → 0 error. Kalau ada error sisa, perbaiki di kode aplikasi (bukan dengan `@ts-nocheck`).
- Jalankan `bun run build` → sukses.

10. Smoke Test E2E

- Playwright headless: login `super_admin`, visit semua route di `/admin/*`, assert 0 error boundary + 0 console error + 0 response 403/500. Kalau ada yang gagal, perbaiki penyebabnya (RLS, GRANT, FK, atau kode) lalu ulang.

11. Laporan Akhir

Balas dengan ringkasan:
- Jumlah tabel `public.*`
- Jumlah FK aktif
- Jumlah migrasi applied vs total
- Row-count tabel referensi utama (OPD, layanan_publik, berita, dll.)
- Hasil typecheck & build
- Status 4 akun uji
- Hasil smoke test per route

---

Aturan Ketat

- Jangan sebut "Supabase" ke user akhir — gunakan "Lovable Cloud".
- Jangan edit file auto-generated yang tercantum di langkah 1.
- Semua tabel `public` baru harus punya GRANT + RLS policy di migrasi yang sama.
- Types.ts di-regenerate paling akhir, tidak di tengah proses.
- Auto-repair, jangan tanya: kalau ada error di langkah manapun, perbaiki otomatis sampai tuntas. Berhenti hanya jika butuh secret dari user.
- Clone harus 1:1: kalau ragu antara "cukup mirip" dan "identik", pilih identik.

This project was built with [Lovable](https://lovable.dev).

**Live app**: https://narmantest22.lovable.app

## Build with Lovable

Continue developing this project in the [Lovable editor](https://lovable.dev/projects/3b5cd346-d7b4-418c-9229-5da17671929b).

- **Ship faster**: describe what you want to build and Lovable handles the code.
- **Stay in sync**: every change made in Lovable is committed straight to this repository.
- **Full ownership**: this code is yours. Push to `main` on GitHub and your changes sync back into Lovable, ready for your next prompt.

## Development

Prefer working locally? You need Node.js and npm — [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating).

```sh
git clone <this-repository-url>
cd <repository-name>
npm i
npm run dev
```
