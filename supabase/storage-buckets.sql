-- Bucket penyimpanan yang dibutuhkan aplikasi.
-- Idempotent: aman dijalankan berulang. Semua bucket PRIVAT — akses lewat
-- RLS pada storage.objects (lihat migrasi *_storage_baseline.sql) + signed URL.
--
-- Cara pakai:
--   1) SQL Editor Supabase: tempel isi file ini lalu Run, ATAU
--   2) psql "postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres" -f supabase/storage-buckets.sql
--   3) Isi file ini juga sudah termasuk di supabase/seed.sql (dipakai `supabase db reset`
--      dan workflow GitHub Actions).

INSERT INTO storage.buckets (id, name, public) VALUES
  ('pejabat-foto','pejabat-foto',false),
  ('branding','branding',false),
  ('berkas-permohonan','berkas-permohonan',false),
  ('aset-foto','aset-foto',false),
  ('form-submissions','form-submissions',false),
  ('signed-documents','signed-documents',false),
  ('signatures','signatures',false),
  ('share-files','share-files',false),
  ('absensi-foto','absensi-foto',false),
  ('verification-assets','verification-assets',false),
  ('documents','documents',false),
  ('bukti-dokumen','bukti-dokumen',false),
  ('form-uploads','form-uploads',false),
  ('document-templates','document-templates',false)
ON CONFLICT (id) DO NOTHING;
