-- ============================================================
-- Full schema dump (public) — generated from development database
-- Idempotent-ish: run on an empty target database.
-- ============================================================
SET statement_timeout = 0;
SET client_min_messages = warning;
-- Functions are emitted in catalog order, so a SQL function may reference a
-- function that is created later in this file. Body validation must be off or
-- those CREATE FUNCTION statements abort and leave the schema incomplete.
SET check_function_bodies = off;
CREATE SCHEMA IF NOT EXISTS public;

-- ---------- EXTENSIONS ----------
-- Extensions are optional per target (managed platforms vary). A missing
-- extension must not abort the whole schema deployment.
DO $$
DECLARE
  ext record;
BEGIN
  FOR ext IN
    SELECT * FROM (VALUES
      ('pg_cron', 'pg_catalog'),
      ('pg_trgm', 'public'),
      ('supabase_vault', 'vault'),
      ('pg_net', 'extensions'),
      ('pgcrypto', 'extensions'),
      ('uuid-ossp', 'extensions'),
      ('pg_stat_statements', 'extensions')
    ) AS t(name, schema_name)
  LOOP
    BEGIN
      EXECUTE format('CREATE EXTENSION IF NOT EXISTS %I WITH SCHEMA %I', ext.name, ext.schema_name);
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Skipping extension %: %', ext.name, SQLERRM;
    END;
  END LOOP;
END $$;


-- ---------- ENUM TYPES ----------
DO $$ BEGIN CREATE TYPE public.announcement_prioritas AS ENUM ('info', 'penting', 'urgent'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.announcement_status AS ENUM ('draft', 'published', 'archived'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.announcement_target_type AS ENUM ('role', 'opd', 'asn_type', 'position', 'individu', 'unit_kerja'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.app_role AS ENUM ('super_admin', 'admin_pemda', 'pimpinan', 'admin_bkpsdm', 'kepala_bkpsdm', 'admin_opd', 'admin_desa', 'asn', 'warga'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.employment_type AS ENUM ('PNS', 'PPPK', 'PPPK_PW', 'NON_ASN', 'THL'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ---------- SEQUENCES ----------
CREATE SEQUENCE IF NOT EXISTS public.permohonan_kode_seq;

-- ---------- TABLES ----------
CREATE TABLE IF NOT EXISTS public.absensi_asn (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "opd_id" uuid,
  "tipe" text NOT NULL,
  "waktu" timestamp with time zone DEFAULT now() NOT NULL,
  "lokasi" text,
  "lat" numeric,
  "lng" numeric,
  "foto_url" text,
  "catatan" text,
  "device_info" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "device_fingerprint_hash" text,
  "is_late" boolean DEFAULT false NOT NULL,
  "late_minutes" integer DEFAULT 0 NOT NULL,
  "schedule_id" uuid
);
CREATE TABLE IF NOT EXISTS public.announcement_targets (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "announcement_id" uuid NOT NULL,
  "target_type" text NOT NULL,
  "target_value" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.announcements (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "judul" text NOT NULL,
  "isi" text DEFAULT ''::text NOT NULL,
  "prioritas" text DEFAULT 'info'::text NOT NULL,
  "link" text,
  "opd_pemilik_id" uuid,
  "status" text DEFAULT 'draft'::text NOT NULL,
  "published_at" timestamp with time zone,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.app_setting (
  "key" text NOT NULL,
  "value" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "category" text DEFAULT 'internal'::text NOT NULL,
  "public_visible" boolean DEFAULT false NOT NULL
);
CREATE TABLE IF NOT EXISTS public.aset (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "kode" text NOT NULL,
  "nama" text NOT NULL,
  "kategori" text,
  "kondisi" text DEFAULT 'baik'::text NOT NULL,
  "lokasi" text,
  "opd_id" uuid,
  "pemegang_user_id" uuid,
  "nilai_perolehan" numeric DEFAULT 0,
  "tanggal_perolehan" date,
  "deskripsi" text,
  "foto_url" text,
  "merk" text,
  "nomor_seri" text,
  "lokasi_terkini" text,
  "lat" numeric,
  "lng" numeric,
  "status" text DEFAULT 'aktif'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "catatan" text,
  "kib" text,
  "version_number" integer DEFAULT 1 NOT NULL,
  "qr_token" text,
  "lifecycle_status" text DEFAULT 'aktif'::text,
  "last_verified_at" timestamp with time zone,
  "garansi_sampai" date,
  "kalibrasi_berikut" date,
  "umur_ekonomis_bulan" integer,
  "metode_susut" text,
  "dokumen_kehilangan_url" text,
  "nilai_sisa" numeric DEFAULT 0
);
CREATE TABLE IF NOT EXISTS public.aset_bast (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "nomor" text NOT NULL,
  "pemberi_user" uuid,
  "penerima_user" uuid,
  "opd_id" uuid,
  "tanggal" date DEFAULT CURRENT_DATE NOT NULL,
  "catatan" text,
  "status" text DEFAULT 'issued'::text NOT NULL,
  "created_by" uuid,
  "approved_by" uuid,
  "approved_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.aset_bast_items (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "bast_id" uuid NOT NULL,
  "aset_id" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.aset_mutasi (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "aset_id" uuid NOT NULL,
  "dari_user" uuid,
  "ke_user" uuid,
  "dari_opd" uuid,
  "ke_opd" uuid,
  "alasan" text,
  "diajukan_oleh" uuid,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "catatan" text,
  "ttd_url" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "approved_by" uuid,
  "approved_at" timestamp with time zone,
  "catatan_approval" text
);
CREATE TABLE IF NOT EXISTS public.aset_nilai_buku (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "aset_id" uuid NOT NULL,
  "periode" text NOT NULL,
  "nilai_perolehan" numeric DEFAULT 0,
  "akumulasi_penyusutan" numeric DEFAULT 0,
  "nilai_buku" numeric DEFAULT 0,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "opd_id" uuid,
  "kode" text,
  "nama" text,
  "tanggal_perolehan" date,
  "umur_ekonomis_bulan" integer,
  "metode_susut" text
);
CREATE TABLE IF NOT EXISTS public.aset_opname (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "opd_id" uuid,
  "periode" text NOT NULL,
  "status" text DEFAULT 'open'::text NOT NULL,
  "catatan" text,
  "dibuat_oleh" uuid,
  "ditutup_oleh" uuid,
  "closed_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.aset_opname_items (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "opname_id" uuid NOT NULL,
  "aset_id" uuid NOT NULL,
  "hadir" boolean,
  "kondisi_temuan" text,
  "catatan" text,
  "verified_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.aset_pemeliharaan (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "aset_id" uuid NOT NULL,
  "opd_id" uuid,
  "jenis" text,
  "deskripsi" text,
  "jadwal" date,
  "selesai_at" timestamp with time zone,
  "biaya" numeric DEFAULT 0,
  "vendor" text,
  "status" text DEFAULT 'dijadwalkan'::text NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.aset_penyusutan_history (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "aset_id" uuid NOT NULL,
  "periode" text NOT NULL,
  "susut_bulan" numeric DEFAULT 0 NOT NULL,
  "akumulasi" numeric DEFAULT 0 NOT NULL,
  "nilai_buku" numeric DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.aset_riwayat (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "aset_id" uuid NOT NULL,
  "aksi" text NOT NULL,
  "catatan" text,
  "oleh" uuid,
  "data" jsonb,
  "lat" numeric,
  "lng" numeric,
  "lokasi_text" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.aset_verification_campaign (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "nama" text NOT NULL,
  "opd_id" uuid,
  "status" text DEFAULT 'open'::text NOT NULL,
  "catatan" text,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "deskripsi" text,
  "periode_mulai" date,
  "periode_selesai" date,
  "target_opd_ids" uuid[] DEFAULT '{}'::uuid[] NOT NULL
);
CREATE TABLE IF NOT EXISTS public.aset_verification_item (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "campaign_id" uuid NOT NULL,
  "aset_id" uuid NOT NULL,
  "verified" boolean DEFAULT false,
  "kondisi" text,
  "catatan" text,
  "verified_by" uuid,
  "verified_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "opd_id" uuid,
  "status" text DEFAULT 'belum'::text NOT NULL,
  "lat" numeric,
  "lng" numeric,
  "lokasi_text" text,
  "foto_url" text
);
CREATE TABLE IF NOT EXISTS public.attendance_shift_assignment (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "shift_id" uuid NOT NULL,
  "dari" date NOT NULL,
  "sampai" date,
  "aktif" boolean DEFAULT true NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.attendance_shifts (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "opd_id" uuid,
  "nama" text NOT NULL,
  "jam_masuk" time without time zone NOT NULL,
  "jam_pulang" time without time zone NOT NULL,
  "toleransi_menit" integer DEFAULT 15 NOT NULL,
  "jenis" text DEFAULT 'pagi'::text NOT NULL,
  "aktif" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.audit_log (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid,
  "user_email" text,
  "aksi" text NOT NULL,
  "entitas" text NOT NULL,
  "entitas_id" text,
  "data_sebelum" jsonb,
  "data_sesudah" jsonb,
  "ip_address" text,
  "user_agent" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "actor_id" uuid,
  "correlation_id" text,
  "request_id" text
);
CREATE TABLE IF NOT EXISTS public.backup_snapshot (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "label" text NOT NULL,
  "tipe" text DEFAULT 'manual'::text NOT NULL,
  "size_bytes" bigint DEFAULT 0 NOT NULL,
  "table_counts" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "data" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_by" uuid
);
CREATE TABLE IF NOT EXISTS public.berita (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "judul" text NOT NULL,
  "slug" text NOT NULL,
  "ringkasan" text,
  "isi" text DEFAULT ''::text NOT NULL,
  "gambar_url" text,
  "status" text DEFAULT 'draft'::text NOT NULL,
  "published_at" timestamp with time zone,
  "penulis_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.branding (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "key" text NOT NULL,
  "value" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_by" uuid
);
CREATE TABLE IF NOT EXISTS public.bukti_dokumen (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "kind" text NOT NULL,
  "entity_id" uuid NOT NULL,
  "opd_id" uuid,
  "nomor" text NOT NULL,
  "token" text NOT NULL,
  "path" text NOT NULL,
  "hash" text NOT NULL,
  "signer_user_id" uuid,
  "signer_name" text,
  "signer_position" text,
  "signer_nip" text,
  "status" text DEFAULT 'active'::text NOT NULL,
  "revoked_at" timestamp with time zone,
  "revoked_by" uuid,
  "revoked_reason" text,
  "snapshot" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.bukti_nomor_seq (
  "opd_id" uuid NOT NULL,
  "kind" text NOT NULL,
  "tahun" integer NOT NULL,
  "bulan" integer NOT NULL,
  "seq" integer DEFAULT 0 NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.bukti_nomor_sequence (
  "kind" text NOT NULL,
  "opd_id" uuid NOT NULL,
  "tahun" integer NOT NULL,
  "bulan" integer NOT NULL,
  "last_number" integer DEFAULT 0 NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.bukti_template_override (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "opd_id" uuid,
  "kind" text NOT NULL,
  "html" text NOT NULL,
  "updated_by" uuid,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.compliance_checklist (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "domain" text NOT NULL,
  "kode" text NOT NULL,
  "label" text NOT NULL,
  "status" text DEFAULT 'todo'::text NOT NULL,
  "bukti_url" text,
  "catatan" text,
  "updated_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "judul" text,
  "deskripsi" text
);
CREATE TABLE IF NOT EXISTS public.consent_log (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "consent_type" text NOT NULL,
  "version" text DEFAULT 'v1'::text NOT NULL,
  "granted" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.cron_history (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "job_name" text NOT NULL,
  "status" text DEFAULT 'running'::text NOT NULL,
  "request_id" text,
  "started_at" timestamp with time zone DEFAULT now() NOT NULL,
  "finished_at" timestamp with time zone,
  "duration_ms" integer,
  "affected_rows" integer,
  "error" text,
  "meta" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "detail" jsonb
);
CREATE TABLE IF NOT EXISTS public.data_terpadu_item (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "kategori" text NOT NULL,
  "label" text NOT NULL,
  "nilai_teks" text,
  "nilai_num" numeric,
  "nilai_num2" numeric,
  "satuan" text,
  "trend" text,
  "ikon" text,
  "format" text,
  "ukuran" text,
  "url" text,
  "opd" text,
  "aktif" boolean DEFAULT true NOT NULL,
  "urutan" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.dataset_submission (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "template_id" uuid,
  "user_id" uuid NOT NULL,
  "opd_id" uuid,
  "data" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "status" text DEFAULT 'draft'::text NOT NULL,
  "catatan_review" text,
  "reviewed_by" uuid,
  "reviewed_at" timestamp with time zone,
  "submitted_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "oleh_user_id" uuid,
  "review_status" text DEFAULT 'pending'::text NOT NULL,
  "review_note" text
);
CREATE TABLE IF NOT EXISTS public.dataset_submission_review (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "submission_id" uuid NOT NULL,
  "reviewer_id" uuid NOT NULL,
  "action" text NOT NULL,
  "catatan" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "aksi" text
);
CREATE TABLE IF NOT EXISTS public.dataset_template (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "judul" text NOT NULL,
  "deskripsi" text,
  "target_role" text DEFAULT 'asn'::text NOT NULL,
  "target_scope" text DEFAULT 'opd_sendiri'::text NOT NULL,
  "target_opd_ids" uuid[] DEFAULT '{}'::uuid[],
  "kolom" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "deadline" timestamp with time zone,
  "aktif" boolean DEFAULT true NOT NULL,
  "allow_multiple_submit" boolean DEFAULT false NOT NULL,
  "excel_layout" jsonb DEFAULT '{"group_by": "opd", "sheet_name": "Rangkuman"}'::jsonb,
  "created_by" uuid,
  "opd_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "kode" text,
  "opd_pemilik_id" uuid
);
CREATE TABLE IF NOT EXISTS public.dead_letter_jobs (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "job_name" text NOT NULL,
  "payload" jsonb DEFAULT '{}'::jsonb,
  "error_message" text,
  "retry_count" integer DEFAULT 0 NOT NULL,
  "resolved_at" timestamp with time zone,
  "resolved_by" uuid,
  "request_id" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "failed_at" timestamp with time zone DEFAULT now() NOT NULL,
  "replayed_to" uuid,
  "resolution_note" text
);
CREATE TABLE IF NOT EXISTS public.desa (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "nama" text NOT NULL,
  "kecamatan" text,
  "aktif" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.digital_signatures (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "signature_path" text NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "revoked_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.document_audit (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "document_id" uuid NOT NULL,
  "action" text NOT NULL,
  "actor" uuid,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "ip_hash" text,
  "user_agent" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.document_history (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "document_id" uuid NOT NULL,
  "action" text NOT NULL,
  "actor_id" uuid,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.document_numbering_rules (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "code" text NOT NULL,
  "name" text NOT NULL,
  "format" text DEFAULT '{kode}/{seq}/{singkatan}/{tahun}'::text NOT NULL,
  "scope" text DEFAULT 'global'::text NOT NULL,
  "category" text,
  "opd_id" uuid,
  "reset_period" text DEFAULT 'yearly'::text NOT NULL,
  "reset_per" text DEFAULT 'yearly'::text NOT NULL,
  "padding" integer DEFAULT 6 NOT NULL,
  "last_value" integer DEFAULT 0 NOT NULL,
  "status" text DEFAULT 'active'::text NOT NULL,
  "aktif" boolean DEFAULT true NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.document_numbering_sequences (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "rule_id" uuid NOT NULL,
  "scope_key" text DEFAULT ''::text NOT NULL,
  "year" integer NOT NULL,
  "last_number" integer DEFAULT 0 NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.document_template_versions (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "template_id" uuid NOT NULL,
  "version_number" integer DEFAULT 1 NOT NULL,
  "kind" text DEFAULT 'html'::text NOT NULL,
  "template_html" text,
  "template_storage_path" text,
  "variables" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "content" text,
  "storage_path" text,
  "schema_snapshot" jsonb DEFAULT '{}'::jsonb,
  "published_at" timestamp with time zone,
  "published_by" uuid,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.document_templates (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "code" text,
  "name" text NOT NULL,
  "description" text,
  "category" text,
  "opd_id" uuid,
  "current_version_id" uuid,
  "status" text DEFAULT 'draft'::text NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "kind" text DEFAULT 'html'::text,
  "template_html" text,
  "variables" jsonb DEFAULT '{}'::jsonb,
  "owner_opd_id" uuid,
  "numbering_rule_id" uuid,
  "current_version" integer DEFAULT 1
);
CREATE TABLE IF NOT EXISTS public.documents (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "title" text NOT NULL,
  "document_type" text NOT NULL,
  "generated_by_system" boolean DEFAULT false NOT NULL,
  "source_module" text,
  "source_ref_id" uuid,
  "file_path" text NOT NULL,
  "opd_id" uuid,
  "created_by" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.dokumen_verifikasi (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "permohonan_id" uuid,
  "storage_path" text NOT NULL,
  "jenis" text,
  "hash" text,
  "size_bytes" bigint,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "token" text,
  "nomor_surat" text,
  "sha256" text,
  "signature_provider" text,
  "diterbitkan_oleh" uuid
);
CREATE TABLE IF NOT EXISTS public.escalation_config (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "opd_id" uuid,
  "layanan_id" uuid,
  "threshold_hours" integer DEFAULT 48 NOT NULL,
  "action" text DEFAULT 'notify'::text NOT NULL,
  "target_user_id" uuid,
  "aktif" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "level" integer DEFAULT 1 NOT NULL,
  "threshold_days" integer DEFAULT 2 NOT NULL,
  "target_role" text DEFAULT 'admin_opd'::text NOT NULL
);
CREATE TABLE IF NOT EXISTS public.feature_flags (
  "key" text NOT NULL,
  "enabled" boolean DEFAULT true NOT NULL,
  "description" text,
  "updated_by" uuid,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "flag_key" text
);
CREATE TABLE IF NOT EXISTS public.form_assignments (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "form_id" uuid NOT NULL,
  "user_id" uuid,
  "opd_id" uuid,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "assigned_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "version_number" integer DEFAULT 1 NOT NULL,
  "due_at" timestamp with time zone,
  "assigned_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.form_audit_logs (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "action" text NOT NULL,
  "resource" text,
  "resource_id" text,
  "actor_id" uuid,
  "payload" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "resource_type" text,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "user_id" uuid
);
CREATE TABLE IF NOT EXISTS public.form_fields (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "form_id" uuid NOT NULL,
  "kode" text NOT NULL,
  "label" text NOT NULL,
  "tipe" text DEFAULT 'text'::text NOT NULL,
  "urutan" integer DEFAULT 0 NOT NULL,
  "required" boolean DEFAULT false NOT NULL,
  "options" jsonb DEFAULT '[]'::jsonb,
  "help" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "visible_if" jsonb,
  "placeholder" text,
  "help_text" text,
  "validation" jsonb DEFAULT '{}'::jsonb
);
CREATE TABLE IF NOT EXISTS public.form_submission_comment (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "submission_id" uuid NOT NULL,
  "oleh" uuid,
  "pesan" text NOT NULL,
  "internal_only" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.form_submission_files (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "submission_id" uuid NOT NULL,
  "field_kode" text,
  "storage_path" text NOT NULL,
  "provider" text DEFAULT 'supabase'::text NOT NULL,
  "mime" text,
  "size_bytes" bigint,
  "cleanup_status" text DEFAULT 'ok'::text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "uploaded_by" uuid,
  "finalized_at" timestamp with time zone
);
CREATE TABLE IF NOT EXISTS public.form_submission_versions (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "submission_id" uuid NOT NULL,
  "version" integer DEFAULT 1 NOT NULL,
  "data" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "files" jsonb DEFAULT '[]'::jsonb,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.form_submissions (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "form_id" uuid NOT NULL,
  "user_id" uuid,
  "opd_id" uuid,
  "data" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "status" text DEFAULT 'draft'::text NOT NULL,
  "assignment_id" uuid,
  "submitted_at" timestamp with time zone,
  "reviewed_at" timestamp with time zone,
  "reviewed_by" uuid,
  "version_number" integer DEFAULT 1 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "schema_version_snapshot" jsonb,
  "review_note" text,
  "workflow_version_id" uuid,
  "current_workflow_node" text,
  "code" text,
  "current_version_id" uuid,
  "form_snapshot" jsonb
);
CREATE TABLE IF NOT EXISTS public.form_targets (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "form_id" uuid NOT NULL,
  "target_type" text NOT NULL,
  "target_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "target_value" text
);
CREATE TABLE IF NOT EXISTS public.form_templates (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "code" text,
  "name" text NOT NULL,
  "description" text,
  "category" text,
  "scope" text DEFAULT 'global'::text NOT NULL,
  "status" text DEFAULT 'draft'::text NOT NULL,
  "owner_opd_id" uuid,
  "allowed_employee_types" text[] DEFAULT '{}'::text[],
  "fields" jsonb DEFAULT '[]'::jsonb,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.form_versions (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "form_id" uuid NOT NULL,
  "version_number" integer DEFAULT 1 NOT NULL,
  "schema_snapshot" jsonb DEFAULT '{}'::jsonb,
  "published_at" timestamp with time zone,
  "published_by" uuid,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "fields" jsonb,
  "meta" jsonb DEFAULT '{}'::jsonb
);
CREATE TABLE IF NOT EXISTS public.form_wizard_drafts (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "form_id" uuid,
  "step" text,
  "payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "title" text,
  "workflow_type" text,
  "status" text DEFAULT 'draft'::text NOT NULL
);
CREATE TABLE IF NOT EXISTS public.forms (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "judul" text NOT NULL,
  "deskripsi" text,
  "opd_pemilik_id" uuid,
  "status" text DEFAULT 'draft'::text NOT NULL,
  "schema_snapshot" jsonb DEFAULT '{}'::jsonb,
  "slug" text,
  "is_public" boolean DEFAULT false NOT NULL,
  "published_at" timestamp with time zone,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "deadline" timestamp with time zone,
  "allow_multiple_submit" boolean DEFAULT false NOT NULL,
  "published_by" uuid,
  "archived_at" timestamp with time zone,
  "code" text,
  "category" text,
  "sla_days" integer DEFAULT 0,
  "allowed_employee_types" text[] DEFAULT '{}'::text[],
  "current_version_id" uuid,
  "version_number" integer DEFAULT 1 NOT NULL,
  "current_workflow_version_id" uuid,
  "deleted_at" timestamp with time zone,
  "publish_status" text DEFAULT 'draft'::text NOT NULL,
  "publish_requested_by" uuid,
  "publish_requested_at" timestamp with time zone,
  "publish_approved_by" uuid,
  "publish_approved_at" timestamp with time zone,
  "publish_reject_reason" text,
  "show_in_open_data" boolean DEFAULT false NOT NULL,
  "deleted_by" uuid
);
CREATE TABLE IF NOT EXISTS public.generated_documents (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "submission_id" uuid,
  "template_id" uuid,
  "storage_path" text NOT NULL,
  "mime" text DEFAULT 'application/pdf'::text NOT NULL,
  "size_bytes" bigint,
  "signed_document_id" uuid,
  "generated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "generated_by" uuid,
  "doc_number" text,
  "name" text,
  "status" text DEFAULT 'generated'::text NOT NULL,
  "template_version" integer,
  "snapshot" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "archived_at" timestamp with time zone,
  "numbering_rule_id" uuid
);
CREATE TABLE IF NOT EXISTS public.geofence_audit (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid,
  "opd_id" uuid,
  "lat" numeric,
  "lng" numeric,
  "dist_m" numeric,
  "radius_m" numeric,
  "valid" boolean,
  "reason" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.hari_libur (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "tanggal" date NOT NULL,
  "nama" text NOT NULL,
  "jenis" text DEFAULT 'nasional'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "nasional" boolean DEFAULT true NOT NULL,
  "catatan" text
);
CREATE TABLE IF NOT EXISTS public.ikm_responses (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "survey_id" uuid NOT NULL,
  "permohonan_id" uuid,
  "user_id" uuid,
  "u1" integer,
  "u2" integer,
  "u3" integer,
  "u4" integer,
  "u5" integer,
  "u6" integer,
  "u7" integer,
  "u8" integer,
  "u9" integer,
  "saran" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.ikm_surveys (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "opd_id" uuid,
  "layanan_id" uuid,
  "judul" text NOT NULL,
  "aktif" boolean DEFAULT true NOT NULL,
  "mulai" date,
  "selesai" date,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "periode" text,
  "created_by" uuid
);
CREATE TABLE IF NOT EXISTS public.jabatan_permissions (
  "jabatan_id" uuid NOT NULL,
  "permission_code" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by" uuid
);
CREATE TABLE IF NOT EXISTS public.job_queue (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "job_type" text NOT NULL,
  "payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "attempts" integer DEFAULT 0 NOT NULL,
  "max_attempts" integer DEFAULT 3 NOT NULL,
  "scheduled_at" timestamp with time zone DEFAULT now() NOT NULL,
  "started_at" timestamp with time zone,
  "finished_at" timestamp with time zone,
  "error" text,
  "result" jsonb,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "status" text DEFAULT 'pending'::text NOT NULL
);
CREATE TABLE IF NOT EXISTS public.kantor_qr (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "opd_id" uuid NOT NULL,
  "token" text NOT NULL,
  "label" text,
  "lokasi" text,
  "lat" numeric,
  "lng" numeric,
  "radius_m" integer DEFAULT 100 NOT NULL,
  "aktif" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.kategori_layanan (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "nama" text NOT NULL,
  "slug" text NOT NULL,
  "sla_hari" integer DEFAULT 7 NOT NULL,
  "deskripsi" text,
  "aktif" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "kode" text
);
CREATE TABLE IF NOT EXISTS public.laporan_masyarakat (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "nama" text NOT NULL,
  "nik" text,
  "email" text NOT NULL,
  "no_hp" text,
  "kategori" text NOT NULL,
  "lokasi" text,
  "uraian" text NOT NULL,
  "status" text DEFAULT 'baru'::text NOT NULL,
  "opd_id" uuid,
  "tindak_lanjut" text,
  "ditangani_oleh" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "ticket_code" text,
  "pelapor_id" uuid
);
CREATE TABLE IF NOT EXISTS public.laporan_ticket_sequence (
  "tahun" integer NOT NULL,
  "last_seq" integer DEFAULT 0 NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.layanan_publik (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "judul" text NOT NULL,
  "slug" text NOT NULL,
  "deskripsi" text,
  "ikon" text,
  "opd_id" uuid,
  "persyaratan" text,
  "alur" text,
  "aktif" boolean DEFAULT true NOT NULL,
  "urutan" integer DEFAULT 0 NOT NULL,
  "sla_hari" integer DEFAULT 14 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "dasar_hukum" text,
  "biaya" text,
  "produk_layanan" text,
  "jam_pelayanan" text,
  "sarana_prasarana" text,
  "kompetensi_pelaksana" text,
  "jumlah_pelaksana" integer,
  "jaminan_pelayanan" text,
  "jaminan_keamanan" text,
  "mekanisme_pengaduan" text,
  "evaluasi_kinerja" text,
  "maklumat_pelayanan" text,
  "faq" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "ticket_code" text,
  "pelapor_id" uuid,
  "document_template_id" uuid,
  "tte_required" boolean DEFAULT false NOT NULL,
  "tte_signer_role" text
);
CREATE TABLE IF NOT EXISTS public.leave_balances (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "tahun" integer NOT NULL,
  "jenis" text NOT NULL,
  "kuota" integer DEFAULT 0 NOT NULL,
  "terpakai" integer DEFAULT 0 NOT NULL,
  "catatan" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.lokasi_gedung (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "nama" text NOT NULL,
  "alamat" text,
  "opd_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.lokasi_lantai (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "gedung_id" uuid NOT NULL,
  "nama" text NOT NULL,
  "urutan" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.lokasi_ruangan (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "lantai_id" uuid NOT NULL,
  "nama" text NOT NULL,
  "kode" text,
  "pic_user_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.master_jabatan (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "kode" text NOT NULL,
  "nama" text NOT NULL,
  "kategori" text,
  "urutan" integer DEFAULT 0 NOT NULL,
  "aktif" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "system_position" text,
  "is_system" boolean DEFAULT false NOT NULL
);
CREATE TABLE IF NOT EXISTS public.nomor_surat_issued (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "nomor" text NOT NULL,
  "tahun" integer NOT NULL,
  "opd_id" uuid,
  "permohonan_id" uuid,
  "issued_at" timestamp with time zone DEFAULT now() NOT NULL,
  "issued_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.nomor_surat_sequence (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "opd_id" uuid,
  "tahun" integer NOT NULL,
  "last_number" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.notification_templates (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "opd_id" uuid,
  "channel" text NOT NULL,
  "key" text NOT NULL,
  "subject" text,
  "body" text NOT NULL,
  "variables" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "enabled" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by" uuid
);
CREATE TABLE IF NOT EXISTS public.notifications (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "tipe" text NOT NULL,
  "judul" text NOT NULL,
  "body" text,
  "link" text,
  "meta" jsonb DEFAULT '{}'::jsonb,
  "dibaca" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.opd (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "nama" text NOT NULL,
  "singkatan" text NOT NULL,
  "kategori" text[] DEFAULT '{}'::text[] NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "nomor_surat_format" text DEFAULT '{kode}/{seq}/{singkatan}/{tahun}'::text,
  "nomor_surat_kode" text DEFAULT '470'::text,
  "slug" text
);
CREATE TABLE IF NOT EXISTS public.overtime_requests (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "opd_id" uuid,
  "tanggal" date NOT NULL,
  "jam_mulai" time without time zone NOT NULL,
  "jam_selesai" time without time zone NOT NULL,
  "alasan" text,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "approved_by" uuid,
  "catatan_approval" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "approved_at" timestamp with time zone
);
CREATE TABLE IF NOT EXISTS public.payroll_periods (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "opd_id" uuid,
  "tahun" integer NOT NULL,
  "bulan" integer NOT NULL,
  "locked_at" timestamp with time zone,
  "locked_by" uuid,
  "unlocked_at" timestamp with time zone,
  "unlocked_by" uuid,
  "catatan" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.pejabat (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "nama" text NOT NULL,
  "jabatan" text NOT NULL,
  "foto_url" text,
  "urutan" integer DEFAULT 0 NOT NULL,
  "aktif" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "user_id" uuid,
  "pimpinan_type" text,
  "is_pimpinan" boolean DEFAULT false NOT NULL,
  "opd_id" uuid,
  "nip" text
);
CREATE TABLE IF NOT EXISTS public.pengajuan_izin (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "opd_id" uuid,
  "jenis" text NOT NULL,
  "dari" date NOT NULL,
  "sampai" date NOT NULL,
  "alasan" text,
  "lampiran_url" text,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "approved_by" uuid,
  "catatan_approval" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "approved_at" timestamp with time zone,
  "mengurangi_saldo" boolean DEFAULT false NOT NULL,
  "saldo_terpotong" integer DEFAULT 0 NOT NULL
);
CREATE TABLE IF NOT EXISTS public.permissions (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "code" text NOT NULL,
  "label" text NOT NULL,
  "kategori" text DEFAULT 'general'::text NOT NULL,
  "description" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.permohonan (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "kode" text NOT NULL,
  "pemohon_id" uuid NOT NULL,
  "opd_id" uuid NOT NULL,
  "judul" text NOT NULL,
  "kategori" text NOT NULL,
  "deskripsi" text,
  "petugas_id" uuid,
  "tanggal_masuk" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "prioritas" text DEFAULT 'normal'::text NOT NULL,
  "tenggat" timestamp with time zone,
  "ringkasan" text,
  "untuk_orang_lain" boolean DEFAULT false NOT NULL,
  "atas_nama_nama" text,
  "atas_nama_nik" text,
  "atas_nama_hp" text,
  "wakil_ambil_nama" text,
  "wakil_ambil_nik" text,
  "current_disposition_id" uuid,
  "dokumen_final_path" text,
  "sla_paused_at" timestamp with time zone,
  "sla_total_pause_seconds" integer DEFAULT 0,
  "nomor_surat" text,
  "rejection_reason_code" text,
  "bukti_token" text,
  "bukti_path" text,
  "bukti_generated_at" timestamp with time zone,
  "bukti_verified_at" timestamp with time zone,
  "bukti_verified_by" uuid,
  "bukti_verified_note" text,
  "status" text DEFAULT 'baru'::text NOT NULL
);
CREATE TABLE IF NOT EXISTS public.permohonan_berkas (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "permohonan_id" uuid NOT NULL,
  "storage_path" text NOT NULL,
  "jenis" text,
  "nama_file" text,
  "size_bytes" bigint,
  "uploaded_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.permohonan_rating (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "permohonan_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "skor" integer NOT NULL,
  "komentar" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.permohonan_riwayat (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "permohonan_id" uuid NOT NULL,
  "oleh" uuid,
  "aksi" text NOT NULL,
  "catatan" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.profiles (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "nama_lengkap" text DEFAULT ''::text NOT NULL,
  "nik" text,
  "no_hp" text,
  "opd_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "status" text DEFAULT 'active'::text NOT NULL,
  "desa" text,
  "verified_at" timestamp with time zone,
  "verified_by" uuid,
  "nip" text,
  "jabatan" text,
  "username" text,
  "asn_type" text,
  "system_position" text,
  "pangkat" text,
  "golongan" text,
  "foto_url" text,
  "verification_status" text,
  "verification_method" text,
  "rejected_at" timestamp with time zone,
  "rejected_by" uuid,
  "rejection_reason" text,
  "alamat" text,
  "jabatan_id" uuid,
  "tempat_lahir" text,
  "tanggal_lahir" date,
  "jenis_kelamin" text,
  "email" text,
  "full_name" text,
  "requested_role" app_role
);
CREATE TABLE IF NOT EXISTS public.push_subscription (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "endpoint" text NOT NULL,
  "p256dh" text NOT NULL,
  "auth" text NOT NULL,
  "user_agent" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.push_test_sink (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "sub_id" uuid NOT NULL,
  "headers" jsonb NOT NULL,
  "body_b64" text NOT NULL,
  "received_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.push_test_sub (
  "id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "priv_jwk" jsonb NOT NULL,
  "p256dh" text NOT NULL,
  "auth" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.rate_limit (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "identifier" text NOT NULL,
  "bucket" text NOT NULL,
  "window_start" timestamp with time zone DEFAULT now() NOT NULL,
  "count" integer DEFAULT 1 NOT NULL
);
CREATE TABLE IF NOT EXISTS public.rate_limit_bucket (
  "scope" text NOT NULL,
  "subject" text NOT NULL,
  "window_start" timestamp with time zone NOT NULL,
  "count" integer DEFAULT 0 NOT NULL
);
CREATE TABLE IF NOT EXISTS public.rate_limit_hits (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "scope" text NOT NULL,
  "subject" text NOT NULL,
  "window_start" timestamp with time zone NOT NULL,
  "count" integer DEFAULT 1 NOT NULL,
  "last_hit_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.rbac_audit (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "actor_id" uuid,
  "target_user_id" uuid,
  "action" text NOT NULL,
  "details" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.retention_policies (
  "entity" text NOT NULL,
  "retention_days" integer DEFAULT 365 NOT NULL,
  "enabled" boolean DEFAULT true NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_by" uuid,
  "last_run_at" timestamp with time zone,
  "last_deleted_count" integer DEFAULT 0 NOT NULL
);
CREATE TABLE IF NOT EXISTS public.retry_queue (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "job_name" text NOT NULL,
  "payload" jsonb DEFAULT '{}'::jsonb,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "attempts" integer DEFAULT 0 NOT NULL,
  "last_attempt_at" timestamp with time zone,
  "next_attempt_at" timestamp with time zone,
  "error" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "max_attempts" integer DEFAULT 5 NOT NULL,
  "next_run_at" timestamp with time zone,
  "last_error" text,
  "request_id" text,
  "locked_at" timestamp with time zone,
  "locked_by" text,
  "completed_at" timestamp with time zone
);
CREATE TABLE IF NOT EXISTS public.role_permissions (
  "permission_code" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.signature_delegations (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "signer_id" uuid NOT NULL,
  "from_user_id" uuid NOT NULL,
  "to_user_id" uuid NOT NULL,
  "reason" text,
  "status" text DEFAULT 'active'::text NOT NULL,
  "delegated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "revoked_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.signature_events (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "request_id" uuid NOT NULL,
  "signer_id" uuid,
  "event" text NOT NULL,
  "payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "actor" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.signature_providers (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "code" text NOT NULL,
  "name" text NOT NULL,
  "kind" text NOT NULL,
  "status" text DEFAULT 'active'::text NOT NULL,
  "config" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "webhook_secret" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.signature_request_signers (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "request_id" uuid NOT NULL,
  "order_index" integer DEFAULT 0 NOT NULL,
  "signer_type" text DEFAULT 'user'::text NOT NULL,
  "user_id" uuid,
  "role" text,
  "position" text,
  "opd_id" uuid,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "external_signer_id" text,
  "signed_at" timestamp with time zone,
  "rejected_at" timestamp with time zone,
  "reject_reason" text,
  "parallel" boolean DEFAULT false NOT NULL,
  "deadline_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.signature_requests (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "generated_document_id" uuid,
  "submission_id" uuid,
  "provider_id" uuid,
  "mode" text DEFAULT 'sequential'::text NOT NULL,
  "status" text DEFAULT 'draft'::text NOT NULL,
  "external_request_id" text,
  "file_hash" text,
  "current_step" integer DEFAULT 0 NOT NULL,
  "opd_id" uuid,
  "created_by" uuid,
  "sent_at" timestamp with time zone,
  "completed_at" timestamp with time zone,
  "cancelled_at" timestamp with time zone,
  "error" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.signed_documents (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "document_id" uuid NOT NULL,
  "document_hash" text NOT NULL,
  "verification_token" text NOT NULL,
  "signed_by" uuid NOT NULL,
  "signed_at" timestamp with time zone DEFAULT now() NOT NULL,
  "status" text DEFAULT 'signed'::text NOT NULL,
  "signed_file_path" text NOT NULL,
  "verification_count" integer DEFAULT 0 NOT NULL,
  "revoked_at" timestamp with time zone,
  "revoke_reason" text,
  "expires_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.signing_certificates (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "nip" text,
  "full_name" text NOT NULL,
  "position" text,
  "issued_at" timestamp with time zone DEFAULT now() NOT NULL,
  "expired_at" timestamp with time zone,
  "public_key" text,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "rotated_from" uuid,
  "revoke_reason" text
);
CREATE TABLE IF NOT EXISTS public.submission_assignments (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "submission_id" uuid,
  "assignee_id" uuid,
  "assigned_by" uuid,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "task_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "assigned_at" timestamp with time zone DEFAULT now(),
  "due_at" timestamp with time zone
);
CREATE TABLE IF NOT EXISTS public.submission_delegations (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "submission_id" uuid,
  "from_user" uuid,
  "to_user" uuid,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "reason" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "task_id" uuid,
  "from_user_id" uuid,
  "to_user_id" uuid
);
CREATE TABLE IF NOT EXISTS public.submission_dispositions (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "permohonan_id" uuid NOT NULL,
  "from_user" uuid NOT NULL,
  "to_user" uuid NOT NULL,
  "level" text NOT NULL,
  "note" text,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "acted_at" timestamp with time zone
);
CREATE TABLE IF NOT EXISTS public.submission_escalations (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "submission_id" uuid,
  "task_id" uuid,
  "level" integer DEFAULT 1 NOT NULL,
  "reason" text,
  "escalated_to" uuid,
  "escalated_by" uuid,
  "status" text DEFAULT 'open'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "resolved_at" timestamp with time zone
);
CREATE TABLE IF NOT EXISTS public.submission_sequences (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "scope" text NOT NULL,
  "tahun" integer NOT NULL,
  "last_number" integer DEFAULT 0 NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.submission_sla_events (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "permohonan_id" uuid NOT NULL,
  "event_type" text NOT NULL,
  "started_at" timestamp with time zone DEFAULT now() NOT NULL,
  "ended_at" timestamp with time zone,
  "duration_seconds" integer,
  "reason" text,
  "actor" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.submission_tasks (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "submission_id" uuid,
  "assignee_id" uuid,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "due_at" timestamp with time zone,
  "completed_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "task_id" uuid,
  "opd_id" uuid,
  "payload" jsonb DEFAULT '{}'::jsonb,
  "result" jsonb,
  "notes" text,
  "sla_hours" integer,
  "node_type" text,
  "node_key" text,
  "workflow_version_id" uuid
);
CREATE TABLE IF NOT EXISTS public.submission_values (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "submission_id" uuid NOT NULL,
  "field_kode" text NOT NULL,
  "value" jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.submission_versions (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "submission_id" uuid NOT NULL,
  "version_number" integer DEFAULT 1 NOT NULL,
  "data" jsonb DEFAULT '{}'::jsonb,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "values" jsonb,
  "reason" text
);
CREATE TABLE IF NOT EXISTS public.uat_results (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "scenario_id" uuid NOT NULL,
  "status" text NOT NULL,
  "catatan" text,
  "run_at" timestamp with time zone DEFAULT now() NOT NULL,
  "run_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.uat_scenarios (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "role" text NOT NULL,
  "modul" text NOT NULL,
  "description" text NOT NULL,
  "steps" text[] DEFAULT '{}'::text[],
  "enabled" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "code" text,
  "judul" text,
  "expected" text
);
CREATE TABLE IF NOT EXISTS public.user_permissions (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "permission_code" text NOT NULL,
  "granted" boolean DEFAULT true NOT NULL,
  "expires_at" timestamp with time zone,
  "reason" text,
  "granted_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "revoked_at" timestamp with time zone
);
CREATE TABLE IF NOT EXISTS public.user_roles (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "role" app_role DEFAULT 'warga'::app_role NOT NULL
);
CREATE TABLE IF NOT EXISTS public.verification_logs (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "target_type" text NOT NULL,
  "target_id" uuid NOT NULL,
  "actor_id" uuid,
  "action" text NOT NULL,
  "catatan" text,
  "meta" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.verification_token (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "token" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "expires_at" timestamp with time zone DEFAULT (now() + '30 days'::interval) NOT NULL,
  "used_at" timestamp with time zone,
  "used_by" uuid
);
CREATE TABLE IF NOT EXISTS public.work_schedule (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "nama" text NOT NULL,
  "opd_id" uuid,
  "hari_kerja" integer[] DEFAULT '{1,2,3,4,5}'::integer[] NOT NULL,
  "jam_masuk" time without time zone NOT NULL,
  "jam_pulang" time without time zone NOT NULL,
  "toleransi_menit" integer DEFAULT 15 NOT NULL,
  "aktif" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.work_schedule_assignment (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "schedule_id" uuid NOT NULL,
  "berlaku_dari" date DEFAULT CURRENT_DATE NOT NULL,
  "berlaku_sampai" date,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.workflow_audit_logs (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "workflow_id" uuid,
  "submission_id" uuid,
  "action" text NOT NULL,
  "actor" uuid,
  "payload" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "resource_type" text,
  "resource_id" text,
  "user_id" uuid,
  "metadata" jsonb DEFAULT '{}'::jsonb
);
CREATE TABLE IF NOT EXISTS public.workflow_definitions (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "code" text,
  "name" text NOT NULL,
  "description" text,
  "opd_id" uuid,
  "status" text DEFAULT 'draft'::text NOT NULL,
  "current_version_id" uuid,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "category" text,
  "opd_pemilik_id" uuid,
  "form_id" uuid,
  "archived_at" timestamp with time zone
);
CREATE TABLE IF NOT EXISTS public.workflow_edges (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "version_id" uuid,
  "source_node" text,
  "target_node" text,
  "condition" jsonb DEFAULT '{}'::jsonb,
  "label" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "workflow_version_id" uuid,
  "from_node" text,
  "to_node" text
);
CREATE TABLE IF NOT EXISTS public.workflow_instances (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "workflow_id" uuid,
  "submission_id" uuid,
  "current_node" text,
  "status" text DEFAULT 'running'::text NOT NULL,
  "context" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.workflow_nodes (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "version_id" uuid,
  "code" text,
  "label" text,
  "type" text,
  "config" jsonb DEFAULT '{}'::jsonb,
  "position" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "workflow_version_id" uuid,
  "node_key" text,
  "node_type" text,
  "sla_hours" integer
);
CREATE TABLE IF NOT EXISTS public.workflow_templates (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "code" text,
  "name" text NOT NULL,
  "description" text,
  "category" text,
  "definition" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "scope" text DEFAULT 'global'::text,
  "status" text DEFAULT 'draft'::text,
  "graph" jsonb DEFAULT '{}'::jsonb,
  "owner_opd_id" uuid,
  "allowed_employee_types" text[] DEFAULT '{}'::text[]
);
CREATE TABLE IF NOT EXISTS public.workflow_versions (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "workflow_id" uuid NOT NULL,
  "version_number" integer DEFAULT 1 NOT NULL,
  "definition" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "published_at" timestamp with time zone,
  "published_by" uuid,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "graph" jsonb DEFAULT '{}'::jsonb,
  "status" text DEFAULT 'draft'::text,
  "locked" boolean DEFAULT false,
  "submission_count" integer DEFAULT 0
);
CREATE TABLE IF NOT EXISTS public.workflows (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "nama" text NOT NULL,
  "opd_id" uuid,
  "definition" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "status" text DEFAULT 'draft'::text NOT NULL,
  "version" integer DEFAULT 1 NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "target_type" text
);

-- ---------- PRIMARY KEYS / UNIQUE / CHECK ----------
DO $$ BEGIN ALTER TABLE public.absensi_asn ADD CONSTRAINT absensi_asn_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.absensi_asn ADD CONSTRAINT absensi_asn_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.announcement_targets ADD CONSTRAINT announcement_targets_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.announcement_targets ADD CONSTRAINT announcement_targets_target_type_check CHECK ((target_type = ANY (ARRAY['role'::text, 'opd'::text, 'asn_type'::text, 'position'::text, 'individu'::text, 'unit_kerja'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.announcements ADD CONSTRAINT announcements_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.announcements ADD CONSTRAINT announcements_prioritas_check CHECK ((prioritas = ANY (ARRAY['info'::text, 'penting'::text, 'urgent'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.announcements ADD CONSTRAINT announcements_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'published'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.app_setting ADD CONSTRAINT app_setting_pkey PRIMARY KEY (key); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset ADD CONSTRAINT aset_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset ADD CONSTRAINT aset_kib_check CHECK (((kib IS NULL) OR (kib = ANY (ARRAY['A'::text, 'B'::text, 'C'::text, 'D'::text, 'E'::text, 'F'::text])))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset ADD CONSTRAINT aset_kode_key UNIQUE (kode); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset ADD CONSTRAINT aset_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_bast ADD CONSTRAINT aset_bast_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_bast ADD CONSTRAINT aset_bast_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_bast_items ADD CONSTRAINT aset_bast_items_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_bast_items ADD CONSTRAINT aset_bast_items_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_mutasi ADD CONSTRAINT aset_mutasi_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_mutasi ADD CONSTRAINT aset_mutasi_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_nilai_buku ADD CONSTRAINT aset_nilai_buku_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_opname ADD CONSTRAINT aset_opname_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_opname ADD CONSTRAINT aset_opname_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_opname_items ADD CONSTRAINT aset_opname_items_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_opname_items ADD CONSTRAINT aset_opname_items_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_pemeliharaan ADD CONSTRAINT aset_pemeliharaan_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_pemeliharaan ADD CONSTRAINT aset_pemeliharaan_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_penyusutan_history ADD CONSTRAINT aset_penyusutan_history_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_penyusutan_history ADD CONSTRAINT aset_penyusutan_history_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_riwayat ADD CONSTRAINT aset_riwayat_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_riwayat ADD CONSTRAINT aset_riwayat_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_verification_campaign ADD CONSTRAINT aset_verification_campaign_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_verification_campaign ADD CONSTRAINT aset_verification_campaign_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_verification_item ADD CONSTRAINT aset_verification_item_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_verification_item ADD CONSTRAINT aset_verification_item_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.attendance_shift_assignment ADD CONSTRAINT attendance_shift_assignment_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.attendance_shift_assignment ADD CONSTRAINT attendance_shift_assignment_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.attendance_shifts ADD CONSTRAINT attendance_shifts_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.attendance_shifts ADD CONSTRAINT attendance_shifts_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.audit_log ADD CONSTRAINT audit_log_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.audit_log ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.backup_snapshot ADD CONSTRAINT backup_snapshot_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.backup_snapshot ADD CONSTRAINT backup_snapshot_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.berita ADD CONSTRAINT berita_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.berita ADD CONSTRAINT berita_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.berita ADD CONSTRAINT berita_slug_key UNIQUE (slug); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.berita ADD CONSTRAINT berita_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'terbit'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.branding ADD CONSTRAINT branding_key_key UNIQUE (key); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.branding ADD CONSTRAINT branding_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.bukti_dokumen ADD CONSTRAINT bukti_dokumen_kind_check CHECK ((kind = ANY (ARRAY['permohonan'::text, 'aset'::text, 'izin_asn'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.bukti_dokumen ADD CONSTRAINT bukti_dokumen_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.bukti_dokumen ADD CONSTRAINT bukti_dokumen_status_check CHECK ((status = ANY (ARRAY['active'::text, 'revoked'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.bukti_dokumen ADD CONSTRAINT bukti_dokumen_token_key UNIQUE (token); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.bukti_nomor_seq ADD CONSTRAINT bukti_nomor_seq_pkey PRIMARY KEY (opd_id, kind, tahun, bulan); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.bukti_nomor_sequence ADD CONSTRAINT bukti_nomor_sequence_pkey PRIMARY KEY (kind, opd_id, tahun, bulan); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.bukti_template_override ADD CONSTRAINT bukti_template_override_kind_check CHECK ((kind = ANY (ARRAY['permohonan'::text, 'aset'::text, 'izin_asn'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.bukti_template_override ADD CONSTRAINT bukti_template_override_opd_id_kind_key UNIQUE (opd_id, kind); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.bukti_template_override ADD CONSTRAINT bukti_template_override_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.compliance_checklist ADD CONSTRAINT compliance_checklist_domain_kode_key UNIQUE (domain, kode); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.compliance_checklist ADD CONSTRAINT compliance_checklist_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.compliance_checklist ADD CONSTRAINT compliance_checklist_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.consent_log ADD CONSTRAINT consent_log_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.consent_log ADD CONSTRAINT consent_log_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.cron_history ADD CONSTRAINT cron_history_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.cron_history ADD CONSTRAINT cron_history_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.data_terpadu_item ADD CONSTRAINT data_terpadu_item_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.data_terpadu_item ADD CONSTRAINT data_terpadu_item_kategori_check CHECK ((kategori = ANY (ARRAY['kpi'::text, 'chart_layanan'::text, 'penduduk'::text, 'anggaran'::text, 'dataset'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.data_terpadu_item ADD CONSTRAINT data_terpadu_item_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dataset_submission ADD CONSTRAINT dataset_submission_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dataset_submission ADD CONSTRAINT dataset_submission_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dataset_submission_review ADD CONSTRAINT dataset_submission_review_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dataset_submission_review ADD CONSTRAINT dataset_submission_review_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dataset_template ADD CONSTRAINT dataset_template_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dataset_template ADD CONSTRAINT dataset_template_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dead_letter_jobs ADD CONSTRAINT dead_letter_jobs_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dead_letter_jobs ADD CONSTRAINT dead_letter_jobs_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.desa ADD CONSTRAINT desa_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.desa ADD CONSTRAINT desa_nama_key UNIQUE (nama); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.desa ADD CONSTRAINT desa_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.digital_signatures ADD CONSTRAINT digital_signatures_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.document_audit ADD CONSTRAINT document_audit_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.document_history ADD CONSTRAINT document_history_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.document_numbering_rules ADD CONSTRAINT document_numbering_rules_code_key UNIQUE (code); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.document_numbering_rules ADD CONSTRAINT document_numbering_rules_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.document_numbering_sequences ADD CONSTRAINT document_numbering_sequences_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.document_numbering_sequences ADD CONSTRAINT document_numbering_sequences_rule_id_scope_key_year_key UNIQUE (rule_id, scope_key, year); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.document_template_versions ADD CONSTRAINT document_template_versions_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.document_template_versions ADD CONSTRAINT document_template_versions_template_id_version_number_key UNIQUE (template_id, version_number); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.document_templates ADD CONSTRAINT document_templates_kind_chk CHECK ((kind = ANY (ARRAY['html'::text, 'docx'::text, 'pdf'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.document_templates ADD CONSTRAINT document_templates_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.documents ADD CONSTRAINT documents_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dokumen_verifikasi ADD CONSTRAINT dokumen_verifikasi_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.escalation_config ADD CONSTRAINT escalation_config_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.escalation_config ADD CONSTRAINT escalation_config_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.feature_flags ADD CONSTRAINT feature_flags_pkey PRIMARY KEY (key); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_assignments ADD CONSTRAINT form_assignments_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_assignments ADD CONSTRAINT form_assignments_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_audit_logs ADD CONSTRAINT form_audit_logs_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_fields ADD CONSTRAINT form_fields_form_id_kode_key UNIQUE (form_id, kode); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_fields ADD CONSTRAINT form_fields_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_fields ADD CONSTRAINT form_fields_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submission_comment ADD CONSTRAINT form_submission_comment_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submission_comment ADD CONSTRAINT form_submission_comment_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submission_files ADD CONSTRAINT form_submission_files_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submission_files ADD CONSTRAINT form_submission_files_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submission_versions ADD CONSTRAINT form_submission_versions_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submission_versions ADD CONSTRAINT form_submission_versions_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submissions ADD CONSTRAINT form_submissions_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submissions ADD CONSTRAINT form_submissions_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_targets ADD CONSTRAINT form_targets_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_targets ADD CONSTRAINT form_targets_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_templates ADD CONSTRAINT form_templates_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_versions ADD CONSTRAINT form_versions_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_wizard_drafts ADD CONSTRAINT form_wizard_drafts_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.forms ADD CONSTRAINT forms_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.forms ADD CONSTRAINT forms_publish_status_chk CHECK ((publish_status = ANY (ARRAY['draft'::text, 'requested'::text, 'approved'::text, 'rejected'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.forms ADD CONSTRAINT forms_slug_key UNIQUE (slug); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.generated_documents ADD CONSTRAINT generated_documents_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.geofence_audit ADD CONSTRAINT geofence_audit_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.geofence_audit ADD CONSTRAINT geofence_audit_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.hari_libur ADD CONSTRAINT hari_libur_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.hari_libur ADD CONSTRAINT hari_libur_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.hari_libur ADD CONSTRAINT hari_libur_tanggal_key UNIQUE (tanggal); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.ikm_responses ADD CONSTRAINT ikm_responses_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.ikm_responses ADD CONSTRAINT ikm_responses_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.ikm_responses ADD CONSTRAINT ikm_responses_u1_check CHECK (((u1 >= 1) AND (u1 <= 4))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.ikm_responses ADD CONSTRAINT ikm_responses_u2_check CHECK (((u2 >= 1) AND (u2 <= 4))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.ikm_responses ADD CONSTRAINT ikm_responses_u3_check CHECK (((u3 >= 1) AND (u3 <= 4))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.ikm_responses ADD CONSTRAINT ikm_responses_u4_check CHECK (((u4 >= 1) AND (u4 <= 4))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.ikm_responses ADD CONSTRAINT ikm_responses_u5_check CHECK (((u5 >= 1) AND (u5 <= 4))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.ikm_responses ADD CONSTRAINT ikm_responses_u6_check CHECK (((u6 >= 1) AND (u6 <= 4))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.ikm_responses ADD CONSTRAINT ikm_responses_u7_check CHECK (((u7 >= 1) AND (u7 <= 4))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.ikm_responses ADD CONSTRAINT ikm_responses_u8_check CHECK (((u8 >= 1) AND (u8 <= 4))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.ikm_responses ADD CONSTRAINT ikm_responses_u9_check CHECK (((u9 >= 1) AND (u9 <= 4))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.ikm_surveys ADD CONSTRAINT ikm_surveys_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.ikm_surveys ADD CONSTRAINT ikm_surveys_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.jabatan_permissions ADD CONSTRAINT jabatan_permissions_pkey PRIMARY KEY (jabatan_id, permission_code); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.job_queue ADD CONSTRAINT job_queue_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.job_queue ADD CONSTRAINT job_queue_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.kantor_qr ADD CONSTRAINT kantor_qr_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.kantor_qr ADD CONSTRAINT kantor_qr_opd_id_key UNIQUE (opd_id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.kantor_qr ADD CONSTRAINT kantor_qr_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.kantor_qr ADD CONSTRAINT kantor_qr_token_key UNIQUE (token); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.kategori_layanan ADD CONSTRAINT kategori_layanan_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.kategori_layanan ADD CONSTRAINT kategori_layanan_nama_key UNIQUE (nama); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.kategori_layanan ADD CONSTRAINT kategori_layanan_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.kategori_layanan ADD CONSTRAINT kategori_layanan_sla_hari_check CHECK (((sla_hari > 0) AND (sla_hari <= 365))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.kategori_layanan ADD CONSTRAINT kategori_layanan_slug_key UNIQUE (slug); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.laporan_masyarakat ADD CONSTRAINT laporan_masyarakat_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.laporan_masyarakat ADD CONSTRAINT laporan_masyarakat_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.laporan_ticket_sequence ADD CONSTRAINT laporan_ticket_sequence_pkey PRIMARY KEY (tahun); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.layanan_publik ADD CONSTRAINT layanan_publik_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.layanan_publik ADD CONSTRAINT layanan_publik_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.layanan_publik ADD CONSTRAINT layanan_publik_slug_key UNIQUE (slug); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.leave_balances ADD CONSTRAINT leave_balances_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.leave_balances ADD CONSTRAINT leave_balances_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.leave_balances ADD CONSTRAINT leave_balances_user_id_tahun_jenis_key UNIQUE (user_id, tahun, jenis); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.lokasi_gedung ADD CONSTRAINT lokasi_gedung_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.lokasi_gedung ADD CONSTRAINT lokasi_gedung_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.lokasi_lantai ADD CONSTRAINT lokasi_lantai_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.lokasi_lantai ADD CONSTRAINT lokasi_lantai_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.lokasi_ruangan ADD CONSTRAINT lokasi_ruangan_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.lokasi_ruangan ADD CONSTRAINT lokasi_ruangan_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.master_jabatan ADD CONSTRAINT master_jabatan_kode_key UNIQUE (kode); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.master_jabatan ADD CONSTRAINT master_jabatan_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.master_jabatan ADD CONSTRAINT master_jabatan_system_position_chk CHECK (((system_position IS NULL) OR (system_position = ANY (ARRAY['kepala_opd'::text, 'sekretaris'::text, 'kepala_bidang'::text, 'kepala_sekolah'::text, 'operator'::text, 'verifikator'::text, 'staff'::text, 'guru'::text, 'tenaga_teknis'::text, 'lainnya'::text])))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.nomor_surat_issued ADD CONSTRAINT nomor_surat_issued_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.nomor_surat_issued ADD CONSTRAINT nomor_surat_issued_nomor_key UNIQUE (nomor); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.nomor_surat_issued ADD CONSTRAINT nomor_surat_issued_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.nomor_surat_sequence ADD CONSTRAINT nomor_surat_sequence_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.nomor_surat_sequence ADD CONSTRAINT nomor_surat_sequence_opd_id_tahun_key UNIQUE (opd_id, tahun); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.nomor_surat_sequence ADD CONSTRAINT nomor_surat_sequence_opd_tahun_key UNIQUE (opd_id, tahun); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.nomor_surat_sequence ADD CONSTRAINT nomor_surat_sequence_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.notification_templates ADD CONSTRAINT notification_templates_channel_check CHECK ((channel = ANY (ARRAY['email'::text, 'push'::text, 'inapp'::text, 'wa'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.notification_templates ADD CONSTRAINT notification_templates_opd_id_channel_key_key UNIQUE (opd_id, channel, key); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.notification_templates ADD CONSTRAINT notification_templates_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.notifications ADD CONSTRAINT notifications_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.notifications ADD CONSTRAINT notifications_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.opd ADD CONSTRAINT opd_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.overtime_requests ADD CONSTRAINT overtime_requests_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.overtime_requests ADD CONSTRAINT overtime_requests_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.payroll_periods ADD CONSTRAINT payroll_periods_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.payroll_periods ADD CONSTRAINT payroll_periods_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.pejabat ADD CONSTRAINT pejabat_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.pejabat ADD CONSTRAINT pejabat_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.pengajuan_izin ADD CONSTRAINT pengajuan_izin_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.pengajuan_izin ADD CONSTRAINT pengajuan_izin_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permissions ADD CONSTRAINT permissions_code_key UNIQUE (code); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permissions ADD CONSTRAINT permissions_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permissions ADD CONSTRAINT permissions_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan ADD CONSTRAINT permohonan_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan ADD CONSTRAINT permohonan_kode_key UNIQUE (kode); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan ADD CONSTRAINT permohonan_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan ADD CONSTRAINT permohonan_prioritas_check CHECK ((prioritas = ANY (ARRAY['rendah'::text, 'normal'::text, 'tinggi'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan_berkas ADD CONSTRAINT permohonan_berkas_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan_berkas ADD CONSTRAINT permohonan_berkas_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan_rating ADD CONSTRAINT permohonan_rating_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan_rating ADD CONSTRAINT permohonan_rating_permohonan_id_user_id_key UNIQUE (permohonan_id, user_id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan_rating ADD CONSTRAINT permohonan_rating_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan_rating ADD CONSTRAINT permohonan_rating_skor_check CHECK (((skor >= 1) AND (skor <= 10))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan_riwayat ADD CONSTRAINT permohonan_riwayat_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan_riwayat ADD CONSTRAINT permohonan_riwayat_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.profiles ADD CONSTRAINT profiles_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.profiles ADD CONSTRAINT profiles_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.profiles ADD CONSTRAINT profiles_status_check CHECK ((status = ANY (ARRAY['active'::text, 'suspended'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.profiles ADD CONSTRAINT profiles_verification_method_chk CHECK (((verification_method IS NULL) OR (verification_method = ANY (ARRAY['qr'::text, 'manual'::text, 'superadmin'::text, 'admin_opd'::text, 'admin_desa'::text])))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.profiles ADD CONSTRAINT profiles_verification_status_chk CHECK (((verification_status IS NULL) OR (verification_status = ANY (ARRAY['pending_verification'::text, 'pending_superadmin_approval'::text, 'verified'::text, 'rejected'::text])))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.push_subscription ADD CONSTRAINT push_subscription_endpoint_key UNIQUE (endpoint); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.push_subscription ADD CONSTRAINT push_subscription_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.push_subscription ADD CONSTRAINT push_subscription_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.push_test_sink ADD CONSTRAINT push_test_sink_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.push_test_sub ADD CONSTRAINT push_test_sub_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.rate_limit ADD CONSTRAINT rate_limit_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.rate_limit_bucket ADD CONSTRAINT rate_limit_bucket_pkey PRIMARY KEY (scope, subject, window_start); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.rate_limit_hits ADD CONSTRAINT rate_limit_hits_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.rate_limit_hits ADD CONSTRAINT rate_limit_hits_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.rate_limit_hits ADD CONSTRAINT rate_limit_hits_scope_subject_window_start_key UNIQUE (scope, subject, window_start); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.rbac_audit ADD CONSTRAINT rbac_audit_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.rbac_audit ADD CONSTRAINT rbac_audit_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.retention_policies ADD CONSTRAINT retention_policies_pkey PRIMARY KEY (entity); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.retry_queue ADD CONSTRAINT retry_queue_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.retry_queue ADD CONSTRAINT retry_queue_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.signature_delegations ADD CONSTRAINT signature_delegations_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.signature_events ADD CONSTRAINT signature_events_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.signature_providers ADD CONSTRAINT signature_providers_code_key UNIQUE (code); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.signature_providers ADD CONSTRAINT signature_providers_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.signature_request_signers ADD CONSTRAINT signature_request_signers_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.signature_requests ADD CONSTRAINT signature_requests_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.signed_documents ADD CONSTRAINT signed_documents_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.signed_documents ADD CONSTRAINT signed_documents_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.signed_documents ADD CONSTRAINT signed_documents_verification_token_key UNIQUE (verification_token); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.signing_certificates ADD CONSTRAINT signing_certificates_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.signing_certificates ADD CONSTRAINT signing_certificates_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_assignments ADD CONSTRAINT submission_assignments_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_delegations ADD CONSTRAINT submission_delegations_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_dispositions ADD CONSTRAINT submission_dispositions_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_dispositions ADD CONSTRAINT submission_dispositions_level_check CHECK ((level = ANY (ARRAY['kepala_opd'::text, 'kabid'::text, 'staf'::text, 'review'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_dispositions ADD CONSTRAINT submission_dispositions_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_dispositions ADD CONSTRAINT submission_dispositions_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'done'::text, 'rejected'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_escalations ADD CONSTRAINT submission_escalations_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_sequences ADD CONSTRAINT submission_sequences_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_sequences ADD CONSTRAINT submission_sequences_scope_tahun_key UNIQUE (scope, tahun); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_sla_events ADD CONSTRAINT submission_sla_events_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_sla_events ADD CONSTRAINT submission_sla_events_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_tasks ADD CONSTRAINT submission_tasks_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_values ADD CONSTRAINT submission_values_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_versions ADD CONSTRAINT submission_versions_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.uat_results ADD CONSTRAINT uat_results_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.uat_results ADD CONSTRAINT uat_results_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.uat_scenarios ADD CONSTRAINT uat_scenarios_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.uat_scenarios ADD CONSTRAINT uat_scenarios_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.user_permissions ADD CONSTRAINT user_permissions_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.user_permissions ADD CONSTRAINT user_permissions_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.user_permissions ADD CONSTRAINT user_permissions_uk UNIQUE (user_id, permission_code); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.user_permissions ADD CONSTRAINT user_permissions_user_id_permission_code_key UNIQUE (user_id, permission_code); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.user_roles ADD CONSTRAINT user_roles_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.user_roles ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.verification_logs ADD CONSTRAINT verification_logs_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.verification_logs ADD CONSTRAINT verification_logs_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.verification_token ADD CONSTRAINT verification_token_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.verification_token ADD CONSTRAINT verification_token_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.verification_token ADD CONSTRAINT verification_token_token_key UNIQUE (token); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.verification_token ADD CONSTRAINT verification_token_user_id_key UNIQUE (user_id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.work_schedule ADD CONSTRAINT work_schedule_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.work_schedule ADD CONSTRAINT work_schedule_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.work_schedule_assignment ADD CONSTRAINT work_schedule_assignment_id_key UNIQUE (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.work_schedule_assignment ADD CONSTRAINT work_schedule_assignment_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.workflow_audit_logs ADD CONSTRAINT workflow_audit_logs_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.workflow_definitions ADD CONSTRAINT workflow_definitions_code_key UNIQUE (code); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.workflow_definitions ADD CONSTRAINT workflow_definitions_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.workflow_definitions ADD CONSTRAINT workflow_definitions_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'active'::text, 'archived'::text]))); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.workflow_edges ADD CONSTRAINT workflow_edges_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.workflow_instances ADD CONSTRAINT workflow_instances_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.workflow_nodes ADD CONSTRAINT workflow_nodes_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.workflow_templates ADD CONSTRAINT workflow_templates_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.workflow_versions ADD CONSTRAINT workflow_versions_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.workflows ADD CONSTRAINT workflows_pkey PRIMARY KEY (id); EXCEPTION WHEN duplicate_table OR duplicate_object OR invalid_table_definition THEN NULL; END $$;

-- ---------- FOREIGN KEYS ----------
DO $$ BEGIN ALTER TABLE public.absensi_asn ADD CONSTRAINT absensi_asn_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.absensi_asn ADD CONSTRAINT absensi_asn_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.announcement_targets ADD CONSTRAINT announcement_targets_announcement_id_fkey FOREIGN KEY (announcement_id) REFERENCES announcements(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.announcements ADD CONSTRAINT announcements_opd_pemilik_id_fkey FOREIGN KEY (opd_pemilik_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset ADD CONSTRAINT aset_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset ADD CONSTRAINT aset_pemegang_user_id_fkey FOREIGN KEY (pemegang_user_id) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_bast ADD CONSTRAINT aset_bast_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_bast ADD CONSTRAINT aset_bast_pemberi_user_fkey FOREIGN KEY (pemberi_user) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_bast ADD CONSTRAINT aset_bast_penerima_user_fkey FOREIGN KEY (penerima_user) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_bast_items ADD CONSTRAINT aset_bast_items_aset_id_fkey FOREIGN KEY (aset_id) REFERENCES aset(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_bast_items ADD CONSTRAINT aset_bast_items_bast_id_fkey FOREIGN KEY (bast_id) REFERENCES aset_bast(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_mutasi ADD CONSTRAINT aset_mutasi_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_mutasi ADD CONSTRAINT aset_mutasi_aset_id_fkey FOREIGN KEY (aset_id) REFERENCES aset(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_mutasi ADD CONSTRAINT aset_mutasi_dari_opd_fkey FOREIGN KEY (dari_opd) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_mutasi ADD CONSTRAINT aset_mutasi_dari_user_fkey FOREIGN KEY (dari_user) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_mutasi ADD CONSTRAINT aset_mutasi_ke_opd_fkey FOREIGN KEY (ke_opd) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_mutasi ADD CONSTRAINT aset_mutasi_ke_user_fkey FOREIGN KEY (ke_user) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_nilai_buku ADD CONSTRAINT aset_nilai_buku_aset_id_fkey FOREIGN KEY (aset_id) REFERENCES aset(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_opname ADD CONSTRAINT aset_opname_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_opname_items ADD CONSTRAINT aset_opname_items_aset_id_fkey FOREIGN KEY (aset_id) REFERENCES aset(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_opname_items ADD CONSTRAINT aset_opname_items_opname_id_fkey FOREIGN KEY (opname_id) REFERENCES aset_opname(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_pemeliharaan ADD CONSTRAINT aset_pemeliharaan_aset_id_fkey FOREIGN KEY (aset_id) REFERENCES aset(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_pemeliharaan ADD CONSTRAINT aset_pemeliharaan_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_penyusutan_history ADD CONSTRAINT aset_penyusutan_history_aset_id_fkey FOREIGN KEY (aset_id) REFERENCES aset(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_riwayat ADD CONSTRAINT aset_riwayat_aset_id_fkey FOREIGN KEY (aset_id) REFERENCES aset(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_riwayat ADD CONSTRAINT aset_riwayat_oleh_fkey FOREIGN KEY (oleh) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_verification_campaign ADD CONSTRAINT aset_verification_campaign_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_verification_item ADD CONSTRAINT aset_verification_item_aset_id_fkey FOREIGN KEY (aset_id) REFERENCES aset(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_verification_item ADD CONSTRAINT aset_verification_item_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES aset_verification_campaign(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.aset_verification_item ADD CONSTRAINT aset_verification_item_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.attendance_shift_assignment ADD CONSTRAINT attendance_shift_assignment_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES attendance_shifts(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.attendance_shifts ADD CONSTRAINT attendance_shifts_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.audit_log ADD CONSTRAINT audit_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.bukti_dokumen ADD CONSTRAINT bukti_dokumen_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.bukti_nomor_seq ADD CONSTRAINT bukti_nomor_seq_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.bukti_template_override ADD CONSTRAINT bukti_template_override_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.consent_log ADD CONSTRAINT consent_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dataset_submission ADD CONSTRAINT dataset_submission_oleh_user_id_fkey FOREIGN KEY (oleh_user_id) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dataset_submission ADD CONSTRAINT dataset_submission_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dataset_submission ADD CONSTRAINT dataset_submission_template_id_fkey FOREIGN KEY (template_id) REFERENCES dataset_template(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dataset_submission ADD CONSTRAINT dataset_submission_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dataset_submission_review ADD CONSTRAINT dataset_submission_review_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES dataset_submission(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dataset_template ADD CONSTRAINT dataset_template_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dataset_template ADD CONSTRAINT dataset_template_opd_pemilik_id_fkey FOREIGN KEY (opd_pemilik_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.document_numbering_sequences ADD CONSTRAINT document_numbering_sequences_rule_id_fkey FOREIGN KEY (rule_id) REFERENCES document_numbering_rules(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.document_template_versions ADD CONSTRAINT document_template_versions_template_id_fkey FOREIGN KEY (template_id) REFERENCES document_templates(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.dokumen_verifikasi ADD CONSTRAINT dokumen_verifikasi_permohonan_id_fkey FOREIGN KEY (permohonan_id) REFERENCES permohonan(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.escalation_config ADD CONSTRAINT escalation_config_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_assignments ADD CONSTRAINT form_assignments_form_id_fkey FOREIGN KEY (form_id) REFERENCES forms(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_assignments ADD CONSTRAINT form_assignments_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_assignments ADD CONSTRAINT form_assignments_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_fields ADD CONSTRAINT form_fields_form_id_fkey FOREIGN KEY (form_id) REFERENCES forms(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submission_comment ADD CONSTRAINT form_submission_comment_oleh_fkey FOREIGN KEY (oleh) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submission_comment ADD CONSTRAINT form_submission_comment_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES form_submissions(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submission_files ADD CONSTRAINT form_submission_files_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES form_submissions(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submission_files ADD CONSTRAINT form_submission_files_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submission_versions ADD CONSTRAINT form_submission_versions_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submission_versions ADD CONSTRAINT form_submission_versions_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES form_submissions(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submissions ADD CONSTRAINT form_submissions_form_id_fkey FOREIGN KEY (form_id) REFERENCES forms(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submissions ADD CONSTRAINT form_submissions_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_submissions ADD CONSTRAINT form_submissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_targets ADD CONSTRAINT form_targets_form_id_fkey FOREIGN KEY (form_id) REFERENCES forms(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_versions ADD CONSTRAINT form_versions_form_id_fkey FOREIGN KEY (form_id) REFERENCES forms(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.form_wizard_drafts ADD CONSTRAINT form_wizard_drafts_form_id_fkey FOREIGN KEY (form_id) REFERENCES forms(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.forms ADD CONSTRAINT forms_opd_pemilik_id_fkey FOREIGN KEY (opd_pemilik_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.geofence_audit ADD CONSTRAINT geofence_audit_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.ikm_responses ADD CONSTRAINT ikm_responses_survey_id_fkey FOREIGN KEY (survey_id) REFERENCES ikm_surveys(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.ikm_surveys ADD CONSTRAINT ikm_surveys_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.jabatan_permissions ADD CONSTRAINT jabatan_permissions_jabatan_id_fkey FOREIGN KEY (jabatan_id) REFERENCES master_jabatan(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.jabatan_permissions ADD CONSTRAINT jabatan_permissions_permission_code_fkey FOREIGN KEY (permission_code) REFERENCES permissions(code) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.kantor_qr ADD CONSTRAINT kantor_qr_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.laporan_masyarakat ADD CONSTRAINT laporan_masyarakat_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.layanan_publik ADD CONSTRAINT layanan_publik_document_template_id_fkey FOREIGN KEY (document_template_id) REFERENCES document_templates(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.layanan_publik ADD CONSTRAINT layanan_publik_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.leave_balances ADD CONSTRAINT leave_balances_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.lokasi_gedung ADD CONSTRAINT lokasi_gedung_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.lokasi_lantai ADD CONSTRAINT lokasi_lantai_gedung_id_fkey FOREIGN KEY (gedung_id) REFERENCES lokasi_gedung(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.lokasi_ruangan ADD CONSTRAINT lokasi_ruangan_lantai_id_fkey FOREIGN KEY (lantai_id) REFERENCES lokasi_lantai(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.nomor_surat_issued ADD CONSTRAINT nomor_surat_issued_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.nomor_surat_issued ADD CONSTRAINT nomor_surat_issued_permohonan_id_fkey FOREIGN KEY (permohonan_id) REFERENCES permohonan(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.nomor_surat_sequence ADD CONSTRAINT nomor_surat_sequence_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.notifications ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.overtime_requests ADD CONSTRAINT overtime_requests_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.overtime_requests ADD CONSTRAINT overtime_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.payroll_periods ADD CONSTRAINT payroll_periods_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.pejabat ADD CONSTRAINT pejabat_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.pengajuan_izin ADD CONSTRAINT pengajuan_izin_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.pengajuan_izin ADD CONSTRAINT pengajuan_izin_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan ADD CONSTRAINT permohonan_current_disposition_id_fkey FOREIGN KEY (current_disposition_id) REFERENCES submission_dispositions(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan ADD CONSTRAINT permohonan_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE RESTRICT; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan ADD CONSTRAINT permohonan_pemohon_id_fkey FOREIGN KEY (pemohon_id) REFERENCES profiles(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan_berkas ADD CONSTRAINT permohonan_berkas_permohonan_id_fkey FOREIGN KEY (permohonan_id) REFERENCES permohonan(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan_berkas ADD CONSTRAINT permohonan_berkas_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan_rating ADD CONSTRAINT permohonan_rating_permohonan_id_fkey FOREIGN KEY (permohonan_id) REFERENCES permohonan(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan_rating ADD CONSTRAINT permohonan_rating_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan_riwayat ADD CONSTRAINT permohonan_riwayat_oleh_fkey FOREIGN KEY (oleh) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.permohonan_riwayat ADD CONSTRAINT permohonan_riwayat_permohonan_id_fkey FOREIGN KEY (permohonan_id) REFERENCES permohonan(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.profiles ADD CONSTRAINT profiles_jabatan_id_fkey FOREIGN KEY (jabatan_id) REFERENCES master_jabatan(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.profiles ADD CONSTRAINT profiles_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.profiles ADD CONSTRAINT profiles_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.push_subscription ADD CONSTRAINT push_subscription_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.push_test_sink ADD CONSTRAINT push_test_sink_sub_id_fkey FOREIGN KEY (sub_id) REFERENCES push_test_sub(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.rbac_audit ADD CONSTRAINT rbac_audit_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES profiles(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.role_permissions ADD CONSTRAINT role_permissions_permission_code_fkey FOREIGN KEY (permission_code) REFERENCES permissions(code) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.signature_delegations ADD CONSTRAINT signature_delegations_signer_id_fkey FOREIGN KEY (signer_id) REFERENCES signature_request_signers(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.signature_events ADD CONSTRAINT signature_events_request_id_fkey FOREIGN KEY (request_id) REFERENCES signature_requests(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.signature_request_signers ADD CONSTRAINT signature_request_signers_request_id_fkey FOREIGN KEY (request_id) REFERENCES signature_requests(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.signing_certificates ADD CONSTRAINT signing_certificates_rotated_from_fkey FOREIGN KEY (rotated_from) REFERENCES signing_certificates(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_assignments ADD CONSTRAINT submission_assignments_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES form_submissions(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_delegations ADD CONSTRAINT submission_delegations_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES form_submissions(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_dispositions ADD CONSTRAINT submission_dispositions_permohonan_id_fkey FOREIGN KEY (permohonan_id) REFERENCES permohonan(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_escalations ADD CONSTRAINT submission_escalations_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES form_submissions(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_sla_events ADD CONSTRAINT submission_sla_events_permohonan_id_fkey FOREIGN KEY (permohonan_id) REFERENCES permohonan(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_tasks ADD CONSTRAINT submission_tasks_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES form_submissions(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_values ADD CONSTRAINT submission_values_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES form_submissions(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.submission_versions ADD CONSTRAINT submission_versions_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES form_submissions(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.uat_results ADD CONSTRAINT uat_results_scenario_id_fkey FOREIGN KEY (scenario_id) REFERENCES uat_scenarios(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.user_permissions ADD CONSTRAINT user_permissions_permission_code_fkey FOREIGN KEY (permission_code) REFERENCES permissions(code) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.user_permissions ADD CONSTRAINT user_permissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.user_roles ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.work_schedule ADD CONSTRAINT work_schedule_opd_id_fkey FOREIGN KEY (opd_id) REFERENCES opd(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.work_schedule_assignment ADD CONSTRAINT work_schedule_assignment_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES work_schedule(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.work_schedule_assignment ADD CONSTRAINT wsa_schedule_fkey FOREIGN KEY (schedule_id) REFERENCES work_schedule(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.workflow_definitions ADD CONSTRAINT workflow_definitions_opd_pemilik_id_fkey FOREIGN KEY (opd_pemilik_id) REFERENCES opd(id) ON DELETE SET NULL NOT VALID; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.workflow_edges ADD CONSTRAINT workflow_edges_version_id_fkey FOREIGN KEY (version_id) REFERENCES workflow_versions(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.workflow_nodes ADD CONSTRAINT workflow_nodes_version_id_fkey FOREIGN KEY (version_id) REFERENCES workflow_versions(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.workflow_versions ADD CONSTRAINT workflow_versions_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES workflow_definitions(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ---------- INDEXES ----------
CREATE INDEX IF NOT EXISTS announcement_targets_ann_idx ON public.announcement_targets USING btree (announcement_id);
CREATE INDEX IF NOT EXISTS announcement_targets_type_val_idx ON public.announcement_targets USING btree (target_type, target_value);
CREATE INDEX IF NOT EXISTS announcements_opd_idx ON public.announcements USING btree (opd_pemilik_id);
CREATE INDEX IF NOT EXISTS announcements_status_idx ON public.announcements USING btree (status);
CREATE INDEX IF NOT EXISTS announcements_updated_at_idx ON public.announcements USING btree (updated_at DESC);
CREATE INDEX IF NOT EXISTS aset_bast_pemberi_user_idx ON public.aset_bast USING btree (pemberi_user);
CREATE INDEX IF NOT EXISTS aset_bast_penerima_user_idx ON public.aset_bast USING btree (penerima_user);
CREATE INDEX IF NOT EXISTS aset_mutasi_approved_by_idx ON public.aset_mutasi USING btree (approved_by);
CREATE INDEX IF NOT EXISTS aset_mutasi_dari_user_idx ON public.aset_mutasi USING btree (dari_user);
CREATE INDEX IF NOT EXISTS aset_mutasi_ke_user_idx ON public.aset_mutasi USING btree (ke_user);
CREATE INDEX IF NOT EXISTS aset_nilai_buku_aset_id_idx ON public.aset_nilai_buku USING btree (aset_id);
CREATE UNIQUE INDEX IF NOT EXISTS aset_penyusutan_history_aset_periode_uidx ON public.aset_penyusutan_history USING btree (aset_id, periode);
CREATE INDEX IF NOT EXISTS audit_log_user_id_idx ON public.audit_log USING btree (user_id);
CREATE INDEX IF NOT EXISTS bukti_dokumen_created_idx ON public.bukti_dokumen USING btree (created_at DESC);
CREATE INDEX IF NOT EXISTS bukti_dokumen_entity_idx ON public.bukti_dokumen USING btree (kind, entity_id);
CREATE INDEX IF NOT EXISTS bukti_dokumen_hash_idx ON public.bukti_dokumen USING btree (hash);
CREATE INDEX IF NOT EXISTS bukti_dokumen_kind_entity_idx ON public.bukti_dokumen USING btree (kind, entity_id);
CREATE INDEX IF NOT EXISTS bukti_dokumen_opd_idx ON public.bukti_dokumen USING btree (opd_id);
CREATE INDEX IF NOT EXISTS bukti_nomor_seq_opd_id_idx ON public.bukti_nomor_seq USING btree (opd_id);
CREATE UNIQUE INDEX IF NOT EXISTS bukti_template_override_kind_opd_uniq ON public.bukti_template_override USING btree (kind, COALESCE(opd_id, '00000000-0000-0000-0000-000000000000'::uuid));
CREATE INDEX IF NOT EXISTS consent_log_user_id_idx ON public.consent_log USING btree (user_id);
CREATE INDEX IF NOT EXISTS dataset_submission_oleh_user_id_idx ON public.dataset_submission USING btree (oleh_user_id);
CREATE INDEX IF NOT EXISTS dataset_submission_user_id_idx ON public.dataset_submission USING btree (user_id);
CREATE UNIQUE INDEX IF NOT EXISTS dataset_template_kode_uidx ON public.dataset_template USING btree (kode) WHERE (kode IS NOT NULL);
CREATE INDEX IF NOT EXISTS dataset_template_opd_pemilik_id_idx ON public.dataset_template USING btree (opd_pemilik_id);
CREATE UNIQUE INDEX IF NOT EXISTS digital_signatures_one_active_per_user ON public.digital_signatures USING btree (user_id) WHERE ((is_active = true) AND (revoked_at IS NULL));
CREATE INDEX IF NOT EXISTS digital_signatures_user_idx ON public.digital_signatures USING btree (user_id);
CREATE INDEX IF NOT EXISTS document_audit_actor_idx ON public.document_audit USING btree (actor);
CREATE INDEX IF NOT EXISTS document_audit_document_idx ON public.document_audit USING btree (document_id, created_at DESC);
CREATE INDEX IF NOT EXISTS document_numbering_sequences_rule_id_idx ON public.document_numbering_sequences USING btree (rule_id);
CREATE INDEX IF NOT EXISTS document_template_versions_template_id_idx ON public.document_template_versions USING btree (template_id);
CREATE INDEX IF NOT EXISTS documents_created_by_idx ON public.documents USING btree (created_by);
CREATE INDEX IF NOT EXISTS documents_opd_idx ON public.documents USING btree (opd_id);
CREATE INDEX IF NOT EXISTS documents_source_idx ON public.documents USING btree (source_module, source_ref_id);
CREATE INDEX IF NOT EXISTS dokumen_verifikasi_permohonan_id_idx ON public.dokumen_verifikasi USING btree (permohonan_id);
CREATE INDEX IF NOT EXISTS form_submission_comment_oleh_idx ON public.form_submission_comment USING btree (oleh);
CREATE INDEX IF NOT EXISTS form_submission_files_uploaded_by_idx ON public.form_submission_files USING btree (uploaded_by);
CREATE INDEX IF NOT EXISTS form_submission_versions_created_by_idx ON public.form_submission_versions USING btree (created_by);
CREATE INDEX IF NOT EXISTS form_submissions_user_id_idx ON public.form_submissions USING btree (user_id);
CREATE INDEX IF NOT EXISTS form_versions_form_id_idx ON public.form_versions USING btree (form_id);
CREATE INDEX IF NOT EXISTS form_wizard_drafts_form_id_idx ON public.form_wizard_drafts USING btree (form_id);
CREATE INDEX IF NOT EXISTS form_wizard_drafts_form_idx ON public.form_wizard_drafts USING btree (form_id) WHERE (form_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS form_wizard_drafts_user_idx ON public.form_wizard_drafts USING btree (user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS forms_open_data_idx ON public.forms USING btree (show_in_open_data) WHERE (show_in_open_data = true);
CREATE UNIQUE INDEX IF NOT EXISTS hari_libur_tanggal_uidx ON public.hari_libur USING btree (tanggal);
CREATE INDEX IF NOT EXISTS idx_absensi_asn_user_waktu ON public.absensi_asn USING btree (user_id, waktu DESC);
CREATE INDEX IF NOT EXISTS idx_ann_targets_ann ON public.announcement_targets USING btree (announcement_id);
CREATE INDEX IF NOT EXISTS idx_announcements_opd ON public.announcements USING btree (opd_pemilik_id);
CREATE INDEX IF NOT EXISTS idx_announcements_status_published ON public.announcements USING btree (status, published_at DESC);
CREATE INDEX IF NOT EXISTS idx_aset_kib ON public.aset USING btree (kib) WHERE (kib IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_aset_nilai_buku_nilai_buku ON public.aset_nilai_buku USING btree (nilai_buku DESC);
CREATE INDEX IF NOT EXISTS idx_aset_nilai_buku_opd_id ON public.aset_nilai_buku USING btree (opd_id);
CREATE INDEX IF NOT EXISTS idx_aset_opd ON public.aset USING btree (opd_id);
CREATE INDEX IF NOT EXISTS idx_aset_opd_status_active ON public.aset USING btree (opd_id, status) WHERE (status <> 'dihapuskan'::text);
CREATE INDEX IF NOT EXISTS idx_audit_log_created ON public.audit_log USING btree (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_entitas ON public.audit_log USING btree (entitas, entitas_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_user ON public.audit_log USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_user_created ON public.audit_log USING btree (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_backup_snapshot_created_at ON public.backup_snapshot USING btree (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_berita_status_pub ON public.berita USING btree (status, published_at DESC);
CREATE INDEX IF NOT EXISTS idx_data_terpadu_kat_urut ON public.data_terpadu_item USING btree (kategori, urutan);
CREATE INDEX IF NOT EXISTS idx_form_assignments_form_id ON public.form_assignments USING btree (form_id);
CREATE INDEX IF NOT EXISTS idx_form_assignments_user_assigned_at ON public.form_assignments USING btree (user_id, assigned_at DESC);
CREATE INDEX IF NOT EXISTS idx_form_fields_form ON public.form_fields USING btree (form_id, urutan);
CREATE INDEX IF NOT EXISTS idx_form_submission_files_submission ON public.form_submission_files USING btree (submission_id);
CREATE INDEX IF NOT EXISTS idx_form_submissions_form_status ON public.form_submissions USING btree (form_id, status);
CREATE INDEX IF NOT EXISTS idx_form_targets_form_id ON public.form_targets USING btree (form_id);
CREATE INDEX IF NOT EXISTS idx_forms_deleted_at ON public.forms USING btree (deleted_at);
CREATE INDEX IF NOT EXISTS idx_forms_public_published ON public.forms USING btree (status, is_public, published_at DESC) WHERE ((status = 'published'::text) AND (is_public = true));
CREATE INDEX IF NOT EXISTS idx_forms_search_trgm_title ON public.forms USING gin (judul gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_generated_documents_submission ON public.generated_documents USING btree (submission_id);
CREATE INDEX IF NOT EXISTS idx_jabatan_permissions_jabatan ON public.jabatan_permissions USING btree (jabatan_id);
CREATE INDEX IF NOT EXISTS idx_laporan_created ON public.laporan_masyarakat USING btree (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_laporan_masyarakat_pelapor_id ON public.laporan_masyarakat USING btree (pelapor_id);
CREATE INDEX IF NOT EXISTS idx_laporan_opd ON public.laporan_masyarakat USING btree (opd_id);
CREATE INDEX IF NOT EXISTS idx_laporan_status ON public.laporan_masyarakat USING btree (status);
CREATE INDEX IF NOT EXISTS idx_layanan_publik_template ON public.layanan_publik USING btree (document_template_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications USING btree (user_id, created_at DESC) WHERE (dibaca = false);
CREATE INDEX IF NOT EXISTS idx_pejabat_pimpinan_type ON public.pejabat USING btree (pimpinan_type) WHERE (pimpinan_type IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_pejabat_user_id ON public.pejabat USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_permohonan_berkas_permohonan ON public.permohonan_berkas USING btree (permohonan_id);
CREATE INDEX IF NOT EXISTS idx_permohonan_opd ON public.permohonan USING btree (opd_id);
CREATE INDEX IF NOT EXISTS idx_permohonan_opd_id ON public.permohonan USING btree (opd_id);
CREATE INDEX IF NOT EXISTS idx_permohonan_pemohon ON public.permohonan USING btree (pemohon_id);
CREATE INDEX IF NOT EXISTS idx_permohonan_pemohon_id ON public.permohonan USING btree (pemohon_id);
CREATE INDEX IF NOT EXISTS idx_permohonan_rating_permohonan ON public.permohonan_rating USING btree (permohonan_id);
CREATE INDEX IF NOT EXISTS idx_permohonan_riwayat_permohonan ON public.permohonan_riwayat USING btree (permohonan_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_push_subscription_user ON public.push_subscription USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_push_test_sink_sub ON public.push_test_sink USING btree (sub_id, received_at DESC);
CREATE INDEX IF NOT EXISTS idx_push_test_sub_user ON public.push_test_sub USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_rate_limit_hits_window ON public.rate_limit_hits USING btree (scope, subject, window_start);
CREATE INDEX IF NOT EXISTS idx_rate_limit_lookup ON public.rate_limit USING btree (identifier, bucket, window_start DESC);
CREATE INDEX IF NOT EXISTS idx_rbac_audit_actor ON public.rbac_audit USING btree (actor_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_rbac_audit_target ON public.rbac_audit USING btree (target_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_riwayat_permohonan ON public.permohonan_riwayat USING btree (permohonan_id);
CREATE INDEX IF NOT EXISTS idx_sigevt_req ON public.signature_events USING btree (request_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_signature_events_created ON public.signature_events USING btree (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_signature_events_event ON public.signature_events USING btree (event, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_signature_events_event_created ON public.signature_events USING btree (event, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_signature_requests_status ON public.signature_requests USING btree (status);
CREATE INDEX IF NOT EXISTS idx_sigreq_doc ON public.signature_requests USING btree (generated_document_id);
CREATE INDEX IF NOT EXISTS idx_sigreq_opd ON public.signature_requests USING btree (opd_id);
CREATE INDEX IF NOT EXISTS idx_sigreq_provider ON public.signature_requests USING btree (provider_id);
CREATE INDEX IF NOT EXISTS idx_sigreq_status ON public.signature_requests USING btree (status);
CREATE INDEX IF NOT EXISTS idx_sigsigner_req ON public.signature_request_signers USING btree (request_id);
CREATE INDEX IF NOT EXISTS idx_subdisp_from_user ON public.submission_dispositions USING btree (from_user);
CREATE INDEX IF NOT EXISTS idx_subdisp_permohonan ON public.submission_dispositions USING btree (permohonan_id);
CREATE INDEX IF NOT EXISTS idx_subdisp_to_user ON public.submission_dispositions USING btree (to_user, status);
CREATE INDEX IF NOT EXISTS idx_submission_assignments_assignee ON public.submission_assignments USING btree (assignee_id, status);
CREATE INDEX IF NOT EXISTS idx_submission_tasks_sub_status ON public.submission_tasks USING btree (submission_id, status);
CREATE INDEX IF NOT EXISTS idx_verification_logs_created ON public.verification_logs USING btree (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_verification_token_token ON public.verification_token USING btree (token);
CREATE INDEX IF NOT EXISTS idx_work_schedule_opd_id ON public.work_schedule USING btree (opd_id);
CREATE INDEX IF NOT EXISTS idx_workflow_audit_resource ON public.workflow_audit_logs USING btree (resource_type, resource_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_workflow_definitions_opd_pemilik_id ON public.workflow_definitions USING btree (opd_pemilik_id);
CREATE INDEX IF NOT EXISTS ix_form_audit_resource ON public.form_audit_logs USING btree (resource_type, resource_id, created_at DESC);
CREATE INDEX IF NOT EXISTS ix_form_audit_user_created ON public.form_audit_logs USING btree (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS ix_form_submissions_opd_status_created ON public.form_submissions USING btree (opd_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS ix_form_submissions_workflow_node ON public.form_submissions USING btree (workflow_version_id, current_workflow_node);
CREATE INDEX IF NOT EXISTS ix_forms_allowed_emp_gin ON public.forms USING gin (allowed_employee_types);
CREATE INDEX IF NOT EXISTS ix_forms_owner_status ON public.forms USING btree (opd_pemilik_id, status) WHERE (deleted_at IS NULL);
CREATE INDEX IF NOT EXISTS ix_master_jabatan_system_position ON public.master_jabatan USING btree (system_position) WHERE (system_position IS NOT NULL);
CREATE INDEX IF NOT EXISTS ix_submission_assignments_assignee ON public.submission_assignments USING btree (assignee_id, status);
CREATE INDEX IF NOT EXISTS ix_submission_delegations_task ON public.submission_delegations USING btree (task_id);
CREATE INDEX IF NOT EXISTS ix_submission_escalations_task ON public.submission_escalations USING btree (task_id);
CREATE INDEX IF NOT EXISTS ix_submission_tasks_due ON public.submission_tasks USING btree (due_at) WHERE (status = ANY (ARRAY['pending'::text, 'in_progress'::text]));
CREATE INDEX IF NOT EXISTS ix_submission_tasks_sub_status ON public.submission_tasks USING btree (submission_id, status);
CREATE INDEX IF NOT EXISTS ix_submission_values_submission ON public.submission_values USING btree (submission_id);
CREATE UNIQUE INDEX IF NOT EXISTS laporan_masyarakat_ticket_code_key ON public.laporan_masyarakat USING btree (ticket_code) WHERE (ticket_code IS NOT NULL);
CREATE UNIQUE INDEX IF NOT EXISTS laporan_ticket_code_uidx ON public.laporan_masyarakat USING btree (ticket_code);
CREATE INDEX IF NOT EXISTS leave_balances_user_id_idx ON public.leave_balances USING btree (user_id);
CREATE UNIQUE INDEX IF NOT EXISTS nomor_surat_sequence_opd_year_key ON public.nomor_surat_sequence USING btree (opd_id, tahun);
CREATE INDEX IF NOT EXISTS notifications_user_id_idx ON public.notifications USING btree (user_id);
CREATE INDEX IF NOT EXISTS overtime_requests_user_id_idx ON public.overtime_requests USING btree (user_id);
CREATE UNIQUE INDEX IF NOT EXISTS payroll_periods_unique_idx ON public.payroll_periods USING btree (COALESCE(opd_id, '00000000-0000-0000-0000-000000000000'::uuid), tahun, bulan);
CREATE INDEX IF NOT EXISTS pejabat_pimpinan_type_idx ON public.pejabat USING btree (pimpinan_type) WHERE (pimpinan_type IS NOT NULL);
CREATE INDEX IF NOT EXISTS pejabat_user_id_idx ON public.pejabat USING btree (user_id) WHERE (user_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS pengajuan_izin_user_id_idx ON public.pengajuan_izin USING btree (user_id);
CREATE INDEX IF NOT EXISTS permohonan_berkas_uploaded_by_idx ON public.permohonan_berkas USING btree (uploaded_by);
CREATE UNIQUE INDEX IF NOT EXISTS permohonan_bukti_token_key ON public.permohonan USING btree (bukti_token) WHERE (bukti_token IS NOT NULL);
CREATE UNIQUE INDEX IF NOT EXISTS permohonan_kode_uniq ON public.permohonan USING btree (kode);
CREATE INDEX IF NOT EXISTS permohonan_pemohon_id_idx ON public.permohonan USING btree (pemohon_id);
CREATE INDEX IF NOT EXISTS permohonan_rating_user_id_idx ON public.permohonan_rating USING btree (user_id);
CREATE INDEX IF NOT EXISTS permohonan_riwayat_oleh_idx ON public.permohonan_riwayat USING btree (oleh);
CREATE UNIQUE INDEX IF NOT EXISTS profiles_username_lower_idx ON public.profiles USING btree (lower(username));
CREATE INDEX IF NOT EXISTS profiles_username_lower_uidx ON public.profiles USING btree (lower(username)) WHERE (username IS NOT NULL);
CREATE UNIQUE INDEX IF NOT EXISTS profiles_username_lower_uniq ON public.profiles USING btree (lower(username)) WHERE (username IS NOT NULL);
CREATE INDEX IF NOT EXISTS profiles_verified_by_idx ON public.profiles USING btree (verified_by);
CREATE INDEX IF NOT EXISTS push_subscription_user_id_idx ON public.push_subscription USING btree (user_id);
CREATE UNIQUE INDEX IF NOT EXISTS rate_limit_hits_scope_subject_window_uq ON public.rate_limit_hits USING btree (scope, subject, window_start);
CREATE INDEX IF NOT EXISTS rbac_audit_actor_id_idx ON public.rbac_audit USING btree (actor_id);
CREATE INDEX IF NOT EXISTS signature_events_request_id_idx ON public.signature_events USING btree (request_id);
CREATE INDEX IF NOT EXISTS signature_request_signers_request_id_idx ON public.signature_request_signers USING btree (request_id);
CREATE INDEX IF NOT EXISTS signed_documents_document_idx ON public.signed_documents USING btree (document_id);
CREATE INDEX IF NOT EXISTS signed_documents_hash_idx ON public.signed_documents USING btree (document_hash);
CREATE INDEX IF NOT EXISTS signed_documents_signed_by_idx ON public.signed_documents USING btree (signed_by);
CREATE INDEX IF NOT EXISTS signed_documents_status_idx ON public.signed_documents USING btree (status);
CREATE INDEX IF NOT EXISTS signing_certificates_active_idx ON public.signing_certificates USING btree (user_id) WHERE (is_active = true);
CREATE INDEX IF NOT EXISTS signing_certificates_user_idx ON public.signing_certificates USING btree (user_id);
CREATE INDEX IF NOT EXISTS submission_assignments_submission_id_idx ON public.submission_assignments USING btree (submission_id);
CREATE INDEX IF NOT EXISTS submission_delegations_submission_id_idx ON public.submission_delegations USING btree (submission_id);
CREATE INDEX IF NOT EXISTS submission_escalations_submission_id_idx ON public.submission_escalations USING btree (submission_id);
CREATE INDEX IF NOT EXISTS submission_tasks_submission_id_idx ON public.submission_tasks USING btree (submission_id);
CREATE INDEX IF NOT EXISTS submission_values_submission_id_idx ON public.submission_values USING btree (submission_id);
CREATE INDEX IF NOT EXISTS submission_versions_submission_id_idx ON public.submission_versions USING btree (submission_id);
CREATE INDEX IF NOT EXISTS user_permissions_user_id_idx ON public.user_permissions USING btree (user_id);
CREATE UNIQUE INDEX IF NOT EXISTS user_roles_user_id_role_key ON public.user_roles USING btree (user_id, role);
CREATE INDEX IF NOT EXISTS ux_form_submissions_code ON public.form_submissions USING btree (code) WHERE (code IS NOT NULL);
CREATE INDEX IF NOT EXISTS ux_forms_code ON public.forms USING btree (code) WHERE ((code IS NOT NULL) AND (deleted_at IS NULL));
CREATE INDEX IF NOT EXISTS workflow_audit_logs_resource_idx ON public.workflow_audit_logs USING btree (resource_type, resource_id, created_at DESC);
CREATE INDEX IF NOT EXISTS workflow_edges_version_id_idx ON public.workflow_edges USING btree (version_id);
CREATE INDEX IF NOT EXISTS workflow_nodes_version_id_idx ON public.workflow_nodes USING btree (version_id);
CREATE INDEX IF NOT EXISTS workflow_versions_workflow_id_idx ON public.workflow_versions USING btree (workflow_id);
CREATE INDEX IF NOT EXISTS workflow_versions_workflow_idx ON public.workflow_versions USING btree (workflow_id, version_number DESC);

-- ---------- FUNCTIONS ----------
CREATE OR REPLACE FUNCTION public._admin_exec(_sql text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN EXECUTE _sql; END; $function$;

CREATE OR REPLACE FUNCTION public._bulk_exec(sql text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$ BEGIN EXECUTE sql; END $function$;

CREATE OR REPLACE FUNCTION public._lovable_bootstrap_exec(p_sql text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ BEGIN EXECUTE p_sql; END $function$;

CREATE OR REPLACE FUNCTION public._lovable_request_uid()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT COALESCE(NULLIF(current_setting('request.jwt.claim.sub', true), ''),
    NULLIF(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')::uuid;
$function$;

CREATE OR REPLACE FUNCTION public.announcements_set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN NEW.updated_at = now(); RETURN NEW; END $function$;

CREATE OR REPLACE FUNCTION public.aset_compliance(_opd_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::jsonb) FROM (
    SELECT o.id AS opd_id, o.nama AS opd_nama,
      COUNT(a.id)::int AS total_aset,
      COUNT(a.id) FILTER (WHERE a.lifecycle_status='aktif')::int AS aktif,
      COUNT(a.id) FILTER (WHERE a.qr_token IS NOT NULL)::int AS terverifikasi_qr
    FROM public.opd o
    LEFT JOIN public.aset a ON a.opd_id = o.id
    WHERE (_opd_id IS NULL OR o.id = _opd_id)
    GROUP BY o.id, o.nama
    ORDER BY total_aset DESC
  ) t
$function$;

CREATE OR REPLACE FUNCTION public.aset_due_warranty(_opd_id uuid DEFAULT NULL::uuid, _days integer DEFAULT 30, _opd uuid DEFAULT NULL::uuid)
 RETURNS TABLE(aset_id uuid, kode text, nama text, opd_id uuid, jenis text, due_date date)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT a.id, a.kode, a.nama, a.opd_id, 'garansi'::text, a.garansi_sampai
  FROM public.aset a
  WHERE a.garansi_sampai IS NOT NULL
    AND a.garansi_sampai <= CURRENT_DATE + COALESCE(_days, 30)
    AND (COALESCE(_opd_id, _opd) IS NULL OR a.opd_id = COALESCE(_opd_id, _opd))
  UNION ALL
  SELECT a.id, a.kode, a.nama, a.opd_id, 'kalibrasi'::text, a.kalibrasi_berikut
  FROM public.aset a
  WHERE a.kalibrasi_berikut IS NOT NULL
    AND a.kalibrasi_berikut <= CURRENT_DATE + COALESCE(_days, 30)
    AND (COALESCE(_opd_id, _opd) IS NULL OR a.opd_id = COALESCE(_opd_id, _opd))
$function$;

CREATE OR REPLACE FUNCTION public.aset_set_qr_token()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
  IF NEW.qr_token IS NULL THEN
    NEW.qr_token := encode(extensions.gen_random_bytes(16), 'hex');
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.attendance_compliance(_from date DEFAULT NULL::date, _to date DEFAULT NULL::date)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ SELECT '[]'::jsonb $function$;

CREATE OR REPLACE FUNCTION public.attendance_compliance(_opd uuid DEFAULT NULL::uuid, _from date DEFAULT NULL::date, _to date DEFAULT NULL::date, _days integer DEFAULT NULL::integer, _user_id uuid DEFAULT NULL::uuid, _opd_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT jsonb_build_object(
    'total', COUNT(*),
    'late', COUNT(*) FILTER (WHERE is_late),
    'late_minutes', COALESCE(SUM(late_minutes), 0)
  )
  FROM public.absensi_asn a
  WHERE (_user_id IS NULL OR a.user_id = _user_id)
    AND (COALESCE(_opd, _opd_id) IS NULL OR a.opd_id = COALESCE(_opd, _opd_id))
    AND (_from IS NULL OR a.waktu::date >= _from)
    AND (_to IS NULL OR a.waktu::date <= _to)
    AND (_days IS NULL OR a.waktu >= now() - make_interval(days => _days))
$function$;

CREATE OR REPLACE FUNCTION public.attendance_device_alert(_days integer DEFAULT 30, _opd uuid DEFAULT NULL::uuid, _opd_id uuid DEFAULT NULL::uuid, _hours integer DEFAULT NULL::integer)
 RETURNS TABLE(user_id uuid, device_fingerprint_hash text, total bigint, last_seen timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT a.user_id, a.device_fingerprint_hash, COUNT(*)::bigint, MAX(a.waktu)
  FROM public.absensi_asn a
  WHERE a.device_fingerprint_hash IS NOT NULL
    AND a.waktu >= now() - make_interval(days => COALESCE(_days, 30), hours => COALESCE(_hours, 0))
    AND (COALESCE(_opd, _opd_id) IS NULL OR a.opd_id = COALESCE(_opd, _opd_id))
  GROUP BY a.user_id, a.device_fingerprint_hash
  HAVING COUNT(*) > 1
$function$;

CREATE OR REPLACE FUNCTION public.attendance_rekap_bulanan(_user_id uuid DEFAULT NULL::uuid, _year integer DEFAULT NULL::integer, _month integer DEFAULT NULL::integer, _opd uuid DEFAULT NULL::uuid, _tahun integer DEFAULT NULL::integer, _bulan integer DEFAULT NULL::integer, _opd_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT jsonb_build_object(
    'hadir', COUNT(*),
    'late', COUNT(*) FILTER (WHERE is_late),
    'late_minutes', COALESCE(SUM(late_minutes), 0)
  )
  FROM public.absensi_asn a
  WHERE (_user_id IS NULL OR a.user_id = _user_id)
    AND (COALESCE(_opd, _opd_id) IS NULL OR a.opd_id = COALESCE(_opd, _opd_id))
    AND (COALESCE(_year, _tahun) IS NULL OR EXTRACT(YEAR FROM a.waktu) = COALESCE(_year, _tahun))
    AND (COALESCE(_month, _bulan) IS NULL OR EXTRACT(MONTH FROM a.waktu) = COALESCE(_month, _bulan))
$function$;

CREATE OR REPLACE FUNCTION public.check_signed_document_status(_id uuid)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT CASE
    WHEN s.status = 'revoked' THEN 'REVOKED'
    WHEN s.expires_at IS NOT NULL AND s.expires_at < now() THEN 'EXPIRED'
    WHEN s.status = 'signed' THEN 'VALID'
    ELSE upper(s.status)
  END
  FROM public.signed_documents s
  WHERE s.id = _id;
$function$;

CREATE OR REPLACE FUNCTION public.count_permohonan_bulan_ini()
 RETURNS integer
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  result_count integer := 0;
BEGIN
  IF to_regclass('public.permohonan') IS NULL THEN
    RETURN 0;
  END IF;

  EXECUTE $sql$
    SELECT count(*)::integer
    FROM public.permohonan
    WHERE created_at >= date_trunc('month', now())
  $sql$ INTO result_count;

  RETURN COALESCE(result_count, 0);
END;
$function$;

CREATE OR REPLACE FUNCTION public.derive_system_position_from_jabatan(_kode text, _nama text, _kategori text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT CASE
    WHEN lower(COALESCE(_kode,'')) ~ '(kepala_dinas|kepala_badan|kaban|kadis|kepala_opd)'
      OR lower(COALESCE(_nama,'')) LIKE 'kepala dinas%'
      OR lower(COALESCE(_nama,'')) LIKE 'kepala badan%'
      THEN 'kepala_opd'
    WHEN lower(COALESCE(_kode,'')) ~ '(sekretaris|sekdis|sekban)'
      OR lower(COALESCE(_nama,'')) LIKE 'sekretaris%'
      THEN 'sekretaris'
    WHEN lower(COALESCE(_kode,'')) ~ '(kabid|kepala_bidang|kepala_sub_bidang|kasubbid)'
      OR lower(COALESCE(_nama,'')) LIKE 'kepala bidang%'
      OR lower(COALESCE(_nama,'')) LIKE 'kepala sub bidang%'
      THEN 'kepala_bidang'
    WHEN lower(COALESCE(_kode,'')) ~ '(kepala_sekolah|kasek)'
      OR lower(COALESCE(_nama,'')) LIKE 'kepala sekolah%'
      THEN 'kepala_sekolah'
    WHEN lower(COALESCE(_kode,'')) ~ '(operator|admin_layanan|admin_data)'
      OR lower(COALESCE(_nama,'')) LIKE '%operator%'
      THEN 'operator'
    WHEN lower(COALESCE(_kode,'')) ~ '(verifikator|validator|pemeriksa)'
      OR lower(COALESCE(_nama,'')) LIKE '%verifikator%'
      OR lower(COALESCE(_nama,'')) LIKE '%validator%'
      THEN 'verifikator'
    WHEN lower(COALESCE(_kode,'')) ~ '(guru|pengawas_sekolah)'
      OR lower(COALESCE(_nama,'')) LIKE '%guru%'
      OR lower(COALESCE(_nama,'')) LIKE '%pengawas sekolah%'
      THEN 'guru'
    WHEN lower(COALESCE(_kode,'')) ~ '(dokter|perawat|bidan|penyuluh|analis|pranata|arsiparis|bendahara|teknis|fungsional)'
      OR lower(COALESCE(_kategori,'')) LIKE '%fungsional%'
      THEN 'tenaga_teknis'
    WHEN lower(COALESCE(_kode,'')) ~ '(staf|staff|pelaksana|pengadministrasi|pengelola)'
      OR lower(COALESCE(_nama,'')) LIKE '%staf%'
      OR lower(COALESCE(_nama,'')) LIKE '%staff%'
      OR lower(COALESCE(_nama,'')) LIKE '%pelaksana%'
      THEN 'staff'
    ELSE 'lainnya'
  END
$function$;

CREATE OR REPLACE FUNCTION public.executive_summary()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT jsonb_build_object(
    'total_permohonan', (SELECT COUNT(*) FROM public.permohonan),
    'permohonan_bulan_ini', public.count_permohonan_bulan_ini(),
    'permohonan_selesai', (SELECT COUNT(*) FROM public.permohonan WHERE status='selesai'),
    'permohonan_diproses', (SELECT COUNT(*) FROM public.permohonan WHERE status='diproses'),
    'permohonan_baru', (SELECT COUNT(*) FROM public.permohonan WHERE status='baru'),
    'total_opd', (SELECT COUNT(*) FROM public.opd),
    'total_layanan', (SELECT COUNT(*) FROM public.layanan_publik WHERE COALESCE(aktif,true)),
    'total_user', (SELECT COUNT(*) FROM public.profiles),
    'avg_rating', COALESCE((SELECT AVG(skor)::numeric(10,2) FROM public.permohonan_rating), 0),
    'generated_at', now()
  )
$function$;

CREATE OR REPLACE FUNCTION public.fn_approve_user(_target_user_id uuid, _role app_role, _method text DEFAULT 'manual'::text)
 RETURNS TABLE(ok boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  UPDATE public.profiles
  SET verification_status = 'verified',
      status = COALESCE(status, 'active'),
      verified_at = now(),
      verified_by = auth.uid(),
      requested_role = COALESCE(_role, requested_role),
      verification_method = _method
  WHERE id = _target_user_id;

  IF _role IS NOT NULL THEN
    INSERT INTO public.user_roles(user_id, role)
    VALUES (_target_user_id, _role)
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN QUERY SELECT true;
END $function$;

CREATE OR REPLACE FUNCTION public.fn_complete_disposition(_disposition_id uuid, _note text DEFAULT NULL::text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE _caller uuid := auth.uid(); _row record;
BEGIN
  IF _caller IS NULL THEN RAISE EXCEPTION 'Tidak terautentikasi'; END IF;
  SELECT * INTO _row FROM public.submission_dispositions WHERE id = _disposition_id;
  IF _row IS NULL THEN RAISE EXCEPTION 'Disposisi tidak ditemukan'; END IF;
  IF NOT (
    _row.to_user = _caller
    OR _row.from_user = _caller
    OR public.has_role(_caller,'super_admin'::app_role)
    OR public.has_role(_caller,'admin_pemda'::app_role)
  ) THEN
    RAISE EXCEPTION 'Tidak berwenang menyelesaikan disposisi';
  END IF;
  UPDATE public.submission_dispositions
    SET status = 'done', acted_at = now(), note = COALESCE(_note, note)
    WHERE id = _disposition_id;
  INSERT INTO public.audit_log(user_id, aksi, entitas, entitas_id, data_sesudah)
  VALUES (_caller, 'permohonan.disposition.completed', 'permohonan', _row.permohonan_id::text,
    jsonb_build_object('disposition_id', _disposition_id, 'note', _note));
  RETURN true;
END $function$;

CREATE OR REPLACE FUNCTION public.fn_create_disposition(_permohonan_id uuid, _to_user uuid, _note text DEFAULT NULL::text, _level text DEFAULT 'staff'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  _caller uuid := auth.uid();
  _opd_caller uuid;
  _opd_target uuid;
  _opd_perm uuid;
  _id uuid;
BEGIN
  IF _caller IS NULL THEN RAISE EXCEPTION 'Tidak terautentikasi'; END IF;
  -- Validasi: caller harus super_admin / admin_opd OPD pemilik / admin_pemda
  SELECT opd_id INTO _opd_perm FROM public.permohonan WHERE id = _permohonan_id;
  IF _opd_perm IS NULL THEN RAISE EXCEPTION 'Permohonan tidak ditemukan'; END IF;
  SELECT opd_id INTO _opd_caller FROM public.profiles WHERE id = _caller;
  SELECT opd_id INTO _opd_target FROM public.profiles WHERE id = _to_user;

  IF NOT (
    public.has_role(_caller,'super_admin'::app_role)
    OR public.has_role(_caller,'admin_pemda'::app_role)
    OR (public.has_role(_caller,'admin_opd'::app_role) AND _opd_caller = _opd_perm)
  ) THEN
    RAISE EXCEPTION 'Anda tidak berwenang mendisposisikan permohonan ini';
  END IF;

  IF _opd_target IS DISTINCT FROM _opd_perm AND NOT public.has_role(_caller,'super_admin'::app_role) THEN
    RAISE EXCEPTION 'Penerima disposisi harus dari OPD yang sama';
  END IF;

  INSERT INTO public.submission_dispositions(permohonan_id, from_user, to_user, level, note, status)
  VALUES (_permohonan_id, _caller, _to_user, COALESCE(_level,'staff'), _note, 'open')
  RETURNING id INTO _id;

  -- Audit log
  INSERT INTO public.audit_log(user_id, aksi, entitas, entitas_id, data_sesudah)
  VALUES (_caller, 'permohonan.disposition.created', 'permohonan', _permohonan_id::text,
    jsonb_build_object('to_user', _to_user, 'level', _level, 'note', _note));

  -- Notifikasi (best-effort)
  BEGIN
    INSERT INTO public.notifications(user_id, tipe, judul, body, link, meta)
    VALUES (_to_user, 'disposisi', 'Disposisi permohonan baru',
      'Anda menerima disposisi permohonan',
      '/admin/permohonan/' || _permohonan_id::text,
      jsonb_build_object('permohonan_id', _permohonan_id, 'disposition_id', _id));
  EXCEPTION WHEN OTHERS THEN NULL; END;

  RETURN _id;
END $function$;

CREATE OR REPLACE FUNCTION public.fn_doc_next_number(_opd_id uuid, _tahun integer, _permohonan_id uuid DEFAULT NULL::uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE seq_row public.nomor_surat_sequence%ROWTYPE; next_num integer; BEGIN
  SELECT * INTO seq_row FROM public.nomor_surat_sequence WHERE opd_id = _opd_id AND tahun = _tahun FOR UPDATE;
  IF NOT FOUND THEN
    INSERT INTO public.nomor_surat_sequence (opd_id, tahun, last_number) VALUES (_opd_id, _tahun, 1) RETURNING last_number INTO next_num;
  ELSE
    UPDATE public.nomor_surat_sequence SET last_number = last_number + 1, updated_at = now() WHERE id = seq_row.id RETURNING last_number INTO next_num;
  END IF;
  RETURN lpad(next_num::text, 5, '0');
END $function$;

CREATE OR REPLACE FUNCTION public.fn_doc_next_number(_rule_id uuid, _opd_id uuid DEFAULT NULL::uuid, _category text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE _seq bigint; _scope text; _year int; BEGIN
  _scope := COALESCE(_opd_id::text,'') || '|' || COALESCE(_category,'');
  _year := extract(year from now())::int;
  INSERT INTO public.document_numbering_sequences(rule_id, scope_key, year, last_number, updated_at)
  VALUES (_rule_id, _scope, _year, 1, now())
  ON CONFLICT (rule_id, scope_key, year)
  DO UPDATE SET last_number = public.document_numbering_sequences.last_number + 1, updated_at = now()
  RETURNING last_number INTO _seq;
  RETURN lpad(_seq::text, 4, '0');
END $function$;

CREATE OR REPLACE FUNCTION public.fn_doc_next_number(_rule_code text, _scope_key text DEFAULT ''::text, _year integer DEFAULT NULL::integer)
 RETURNS text
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT public.fn_next_number(_rule_code, _scope_key, _year);
$function$;

CREATE OR REPLACE FUNCTION public.fn_expire_signed_document_tokens()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE _n int := 0;
BEGIN
  UPDATE public.signed_documents
     SET status = 'expired'
   WHERE status = 'signed'
     AND expires_at IS NOT NULL
     AND expires_at < now();
  GET DIAGNOSTICS _n = ROW_COUNT;
  RETURN jsonb_build_object('expired', _n, 'at', now());
END $function$;

CREATE OR REPLACE FUNCTION public.fn_fb_generate_submission_code(_format text, _scope text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  _tahun integer := EXTRACT(YEAR FROM now())::integer;
  _seq integer;
BEGIN
  INSERT INTO public.submission_sequences (scope, tahun, last_number)
  VALUES (_scope, _tahun, 1)
  ON CONFLICT (scope, tahun) DO UPDATE SET last_number = public.submission_sequences.last_number + 1, updated_at = now()
  RETURNING last_number INTO _seq;
  RETURN replace(replace(_format, '{YEAR}', _tahun::text), '{SEQ}', lpad(_seq::text, 6, '0'));
END $function$;

CREATE OR REPLACE FUNCTION public.fn_generate_laporan_ticket()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  y integer := EXTRACT(YEAR FROM now())::int;
  s integer;
BEGIN
  INSERT INTO public.laporan_ticket_sequence(tahun, last_seq)
    VALUES (y, 1)
  ON CONFLICT (tahun) DO UPDATE
    SET last_seq = public.laporan_ticket_sequence.last_seq + 1,
        updated_at = now()
  RETURNING last_seq INTO s;
  RETURN 'LAPOR-' || y::text || '-' || lpad(s::text, 6, '0');
END $function$;

CREATE OR REPLACE FUNCTION public.fn_generate_nomor_surat(_opd_id uuid, _permohonan_id uuid DEFAULT NULL::uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE y int := EXTRACT(YEAR FROM now())::int; n int; s text; code text; fmt text;
BEGIN
  INSERT INTO public.nomor_surat_sequence(opd_id,tahun,last_number) VALUES (_opd_id,y,1)
  ON CONFLICT DO NOTHING;
  UPDATE public.nomor_surat_sequence SET last_number=last_number+1, updated_at=now() WHERE opd_id IS NOT DISTINCT FROM _opd_id AND tahun=y RETURNING last_number INTO n;
  SELECT COALESCE(nomor_surat_kode,'470'), COALESCE(nomor_surat_format,'{kode}/{seq}/{singkatan}/{tahun}') INTO code, fmt FROM public.opd WHERE id=_opd_id;
  s := replace(replace(replace(fmt,'{kode}',COALESCE(code,'470')),'{seq}',lpad(COALESCE(n,1)::text,4,'0')),'{tahun}',y::text);
  RETURN s;
END $function$;

CREATE OR REPLACE FUNCTION public.fn_ikm_dashboard(_from date DEFAULT NULL::date, _to date DEFAULT NULL::date, _opd_id uuid DEFAULT NULL::uuid, _survey_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ SELECT '{}'::jsonb $function$;

CREATE OR REPLACE FUNCTION public.fn_ikm_dashboard(_survey_id uuid DEFAULT NULL::uuid, _opd_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  WITH r AS (
    SELECT * FROM public.ikm_responses
    WHERE (_survey_id IS NULL OR survey_id = _survey_id)
  ),
  agg AS (
    SELECT COUNT(*)::int AS total,
      AVG((COALESCE(u1,0)+COALESCE(u2,0)+COALESCE(u3,0)+COALESCE(u4,0)+COALESCE(u5,0)+COALESCE(u6,0)+COALESCE(u7,0)+COALESCE(u8,0)+COALESCE(u9,0))::numeric / 9.0) AS rata
    FROM r
  )
  SELECT jsonb_build_object(
    'total', total,
    'rata', ROUND(COALESCE(rata,0), 2),
    'nilai_ikm', ROUND(COALESCE(rata,0) * 25, 2)
  )
  FROM agg
$function$;

CREATE OR REPLACE FUNCTION public.fn_next_number(_rule_code text, _scope_key text DEFAULT ''::text, _year integer DEFAULT NULL::integer)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE r public.document_numbering_rules%ROWTYPE; yr int; n int; out_text text;
BEGIN
  SELECT * INTO r FROM public.document_numbering_rules WHERE code = _rule_code AND status='active';
  IF NOT FOUND THEN RAISE EXCEPTION 'Numbering rule % not found', _rule_code; END IF;
  yr := COALESCE(_year, EXTRACT(YEAR FROM now())::int);
  INSERT INTO public.document_numbering_sequences(rule_id, scope_key, year, last_number)
    VALUES (r.id, COALESCE(_scope_key,''), yr, 1)
    ON CONFLICT (rule_id, scope_key, year) DO UPDATE SET last_number = public.document_numbering_sequences.last_number + 1, updated_at=now()
    RETURNING last_number INTO n;
  out_text := replace(replace(replace(r.format,'{{seq}}', lpad(n::text, r.padding, '0')),'{{year}}', yr::text),'{{scope}}', COALESCE(_scope_key,''));
  RETURN out_text;
END $function$;

CREATE OR REPLACE FUNCTION public.fn_permohonan_effective_sla_seconds(_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
DECLARE _start timestamptz; _pause int; _now timestamptz; BEGIN
  SELECT tanggal_masuk, COALESCE(sla_total_pause_seconds,0), now()
    INTO _start, _pause, _now FROM public.permohonan WHERE id = _id;
  IF _start IS NULL THEN RETURN 0; END IF;
  RETURN GREATEST(0, EXTRACT(EPOCH FROM (_now - _start))::int - _pause);
END $function$;

CREATE OR REPLACE FUNCTION public.fn_reject_user(_target_user_id uuid, _reason text DEFAULT NULL::text)
 RETURNS TABLE(ok boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  UPDATE public.profiles
  SET verification_status = 'rejected',
      status = COALESCE(status, 'rejected'),
      rejection_reason = _reason
  WHERE id = _target_user_id;

  RETURN QUERY SELECT true;
END $function$;

CREATE OR REPLACE FUNCTION public.fn_retention_cleanup()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  _audit int := 0; _verif int := 0; _rl int := 0; _notif int := 0;
BEGIN
  DELETE FROM public.audit_log WHERE created_at < now() - interval '365 days';
  GET DIAGNOSTICS _audit = ROW_COUNT;

  DELETE FROM public.verification_logs WHERE created_at < now() - interval '180 days';
  GET DIAGNOSTICS _verif = ROW_COUNT;

  DELETE FROM public.rate_limit_hits WHERE last_hit_at < now() - interval '7 days';
  GET DIAGNOSTICS _rl = ROW_COUNT;

  DELETE FROM public.notifications WHERE dibaca = true AND created_at < now() - interval '90 days';
  GET DIAGNOSTICS _notif = ROW_COUNT;

  RETURN jsonb_build_object('audit_log', _audit, 'verification_logs', _verif, 'rate_limit_hits', _rl, 'notifications', _notif, 'executed_at', now());
END;
$function$;

CREATE OR REPLACE FUNCTION public.fn_susut_bulanan_run(_periode text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN jsonb_build_object('inserted', 0, 'skipped', 0, 'periode', _periode);
END $function$;

CREATE OR REPLACE FUNCTION public.fwd_set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_default_permissions(_user_id uuid)
 RETURNS TABLE(permission_code text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  _roles text[] := ARRAY[]::text[];
  _asn_type text;
  _system_position text;
  _jabatan_kode text;
BEGIN
  SELECT COALESCE(array_agg(role::text), ARRAY[]::text[])
    INTO _roles
  FROM public.user_roles
  WHERE user_id = _user_id;

  SELECT p.asn_type,
         COALESCE(p.system_position, mj.system_position, public.derive_system_position_from_jabatan(mj.kode, COALESCE(mj.nama, p.jabatan), mj.kategori)),
         mj.kode
    INTO _asn_type, _system_position, _jabatan_kode
  FROM public.profiles p
  LEFT JOIN public.master_jabatan mj ON mj.id = p.jabatan_id
  WHERE p.id = _user_id
  LIMIT 1;

  IF 'super_admin' = ANY(_roles) THEN
    RETURN QUERY SELECT code FROM public.permissions;
    RETURN;
  END IF;

  IF 'admin_pemda' = ANY(_roles) THEN
    RETURN QUERY SELECT DISTINCT v.permission_code FROM (VALUES
      ('pemda.view'),('pemda.manage'),('pemda.monitor'),
      ('view_all_opd'),('view_all_submissions'),('view_all_attendance'),('view_all_assets'),
      ('view_all_datasets'),('view_all_reports'),('view_all_performance'),('view_all_surveys'),
      ('view_kabupaten_dashboard'),('view_executive_dashboard'),('view_cross_opd_analytics'),
      ('executive.view'),
      ('can_manage_users'),('can_manage_opd'),('can_view_audit_logs'),('can_export_data'),
      ('can_manage_forms'),('can_publish_form'),('can_verify_submission'),('can_approve_registration'),
      ('can_request_data'),('can_approve_data_request'),
      ('can_view_sensitive_document'),('can_download_document'),('can_share_document')
    ) AS v(permission_code);
  END IF;

  IF 'pimpinan' = ANY(_roles) THEN
    RETURN QUERY SELECT DISTINCT v.permission_code FROM (VALUES
      ('view_all_opd'),('view_all_submissions'),('view_all_attendance'),('view_all_assets'),
      ('view_all_datasets'),('view_all_reports'),('view_all_performance'),('view_all_surveys'),
      ('view_kabupaten_dashboard'),('view_executive_dashboard'),('view_cross_opd_analytics'),
      ('executive.view'),('can_export_data'),('can_download_document')
    ) AS v(permission_code);

    IF public.is_bupati(_user_id) THEN
      RETURN QUERY SELECT DISTINCT v.permission_code FROM (VALUES
        ('executive.approve'),('executive.sign'),('executive.disposition')
      ) AS v(permission_code);
    END IF;
  END IF;

  IF 'admin_bkpsdm' = ANY(_roles) THEN
    RETURN QUERY SELECT DISTINCT v.permission_code FROM (VALUES
      ('can_manage_users'),('can_approve_registration'),('can_view_audit_logs'),('can_export_data'),
      ('view_all_performance'),('view_all_attendance'),('view_all_reports'),
      ('can_request_data'),('can_approve_data_request'),
      ('can_view_sensitive_document'),('can_download_document'),('can_share_document')
    ) AS v(permission_code);
  END IF;

  IF 'kepala_bkpsdm' = ANY(_roles) THEN
    RETURN QUERY SELECT DISTINCT v.permission_code FROM (VALUES
      ('executive.view'),('view_executive_dashboard'),('view_all_performance'),('view_all_attendance'),
      ('view_all_reports'),('can_approve_registration'),('can_approve_data_request'),
      ('can_view_sensitive_document'),('can_download_document'),('can_export_data')
    ) AS v(permission_code);
  END IF;

  IF 'admin_opd' = ANY(_roles) THEN
    RETURN QUERY SELECT DISTINCT v.permission_code FROM (VALUES
      ('can_manage_forms'),('can_create_form'),('can_edit_form'),('can_publish_form'),('can_assign_form'),
      ('can_verify_submission'),('can_approve_submission'),('can_reject_submission'),('can_request_revision'),
      ('can_request_data'),('can_approve_data_request'),
      ('can_view_sensitive_document'),('can_download_document'),('can_share_document'),('can_request_document'),
      ('can_export_data')
    ) AS v(permission_code);
  END IF;

  IF 'admin_desa' = ANY(_roles) THEN
    RETURN QUERY SELECT DISTINCT v.permission_code FROM (VALUES
      ('can_approve_registration'),('can_verify_submission'),('can_request_revision'),
      ('can_request_document'),('can_download_document'),('can_share_document')
    ) AS v(permission_code);
  END IF;

  IF 'asn' = ANY(_roles) THEN
    RETURN QUERY SELECT DISTINCT v.permission_code FROM (VALUES
      ('can_request_document'),('can_download_document'),('can_share_document')
    ) AS v(permission_code);

    IF _asn_type IN ('pns','pppk_penuh_waktu') THEN
      RETURN QUERY SELECT DISTINCT v.permission_code FROM (VALUES
        ('can_request_data')
      ) AS v(permission_code);
    END IF;

    IF _system_position IN ('operator','verifikator') THEN
      RETURN QUERY SELECT DISTINCT v.permission_code FROM (VALUES
        ('can_verify_submission'),('can_request_revision')
      ) AS v(permission_code);
    END IF;

    IF _system_position IN ('kepala_bidang','sekretaris','kepala_opd','kepala_sekolah') THEN
      RETURN QUERY SELECT DISTINCT v.permission_code FROM (VALUES
        ('can_approve_submission'),('can_reject_submission'),('can_request_revision'),('can_view_sensitive_document')
      ) AS v(permission_code);
    END IF;

    IF _system_position = 'kepala_opd' THEN
      RETURN QUERY SELECT DISTINCT v.permission_code FROM (VALUES
        ('can_publish_form'),('can_manage_forms'),('can_approve_data_request')
      ) AS v(permission_code);
    END IF;

    IF _system_position IN ('guru','tenaga_teknis','staff','lainnya') THEN
      RETURN QUERY SELECT DISTINCT v.permission_code FROM (VALUES
        ('can_create_form')
      ) AS v(permission_code);
    END IF;
  END IF;

  IF 'warga' = ANY(_roles) THEN
    RETURN QUERY SELECT DISTINCT v.permission_code FROM (VALUES
      ('can_request_document')
    ) AS v(permission_code);
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_effective_permissions(_user_id uuid)
 RETURNS text[]
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT COALESCE(
    ARRAY_AGG(permission_code) FILTER (
      WHERE granted = true
        AND revoked_at IS NULL
        AND (expires_at IS NULL OR expires_at > now())
    ),
    ARRAY[]::text[]
  )
  FROM public.user_permissions
  WHERE user_id = _user_id
$function$;

CREATE OR REPLACE FUNCTION public.get_user_desa(_user_id uuid)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ SELECT desa FROM public.profiles WHERE id = _user_id LIMIT 1; $function$;

CREATE OR REPLACE FUNCTION public.get_user_opd(_user_id uuid)
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT opd_id FROM public.profiles WHERE id = _user_id LIMIT 1
$function$;

CREATE OR REPLACE FUNCTION public.governance_inventory()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  _uid uuid := auth.uid();
  _result jsonb;
BEGIN
  IF _uid IS NULL OR NOT (
    public.has_role(_uid, 'super_admin') OR public.has_role(_uid, 'admin_pemda')
  ) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  SELECT jsonb_build_object(
    'nomor_surat_total', (SELECT COUNT(*) FROM public.nomor_surat_issued),
    'nomor_surat_tahun_ini', (SELECT COUNT(*) FROM public.nomor_surat_issued WHERE tahun = EXTRACT(YEAR FROM now())::int),
    'share_paket_aktif', (SELECT COUNT(*) FROM public.share_paket WHERE status IS DISTINCT FROM 'dibatalkan'),
    'verification_logs_30d', (SELECT COUNT(*) FROM public.verification_logs WHERE created_at > now() - interval '30 days'),
    'data_request_pending', (SELECT COUNT(*) FROM public.data_requests WHERE status IN ('baru','review')),
    'legacy_submission_total', (SELECT COUNT(*) FROM public.submissions),
    'legacy_submission_unmigrated', (SELECT COUNT(*) FROM public.submissions s
       WHERE NOT EXISTS (SELECT 1 FROM public.form_submissions fs WHERE fs.legacy_submission_id = s.id)),
    'dataset_template_total', (SELECT COUNT(*) FROM public.dataset_template),
    'dataset_template_aktif', (SELECT COUNT(*) FROM public.dataset_template WHERE aktif),
    'unit_kerja_total', (SELECT COUNT(*) FROM public.unit_kerja),
    'rate_limit_hits_24h', (SELECT COUNT(*) FROM public.rate_limit_hits WHERE last_hit_at > now() - interval '24 hours')
  ) INTO _result;
  RETURN _result;
EXCEPTION WHEN undefined_column THEN
  -- legacy_submission_id belum ada di form_submissions: fallback tanpa hubungan migrasi
  SELECT jsonb_build_object(
    'nomor_surat_total', (SELECT COUNT(*) FROM public.nomor_surat_issued),
    'nomor_surat_tahun_ini', (SELECT COUNT(*) FROM public.nomor_surat_issued WHERE tahun = EXTRACT(YEAR FROM now())::int),
    'share_paket_aktif', (SELECT COUNT(*) FROM public.share_paket),
    'verification_logs_30d', (SELECT COUNT(*) FROM public.verification_logs WHERE created_at > now() - interval '30 days'),
    'data_request_pending', (SELECT COUNT(*) FROM public.data_requests),
    'legacy_submission_total', (SELECT COUNT(*) FROM public.submissions),
    'legacy_submission_unmigrated', (SELECT COUNT(*) FROM public.submissions),
    'dataset_template_total', (SELECT COUNT(*) FROM public.dataset_template),
    'dataset_template_aktif', (SELECT COUNT(*) FROM public.dataset_template WHERE aktif),
    'unit_kerja_total', (SELECT COUNT(*) FROM public.unit_kerja),
    'rate_limit_hits_24h', (SELECT COUNT(*) FROM public.rate_limit_hits WHERE last_hit_at > now() - interval '24 hours')
  ) INTO _result;
  RETURN _result;
END $function$;

CREATE OR REPLACE FUNCTION public.governance_summary()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT jsonb_build_object(
    'audit_log_count', (SELECT COUNT(*) FROM public.audit_log),
    'audit_log_24h', (SELECT COUNT(*) FROM public.audit_log WHERE created_at > now() - interval '24 hours'),
    'rbac_audit_count', (SELECT COUNT(*) FROM public.rbac_audit),
    'pending_users', (SELECT COUNT(*) FROM public.profiles WHERE status='pending'),
    'active_users', (SELECT COUNT(*) FROM public.profiles WHERE status='active'),
    'compliance_open', (SELECT COUNT(*) FROM public.compliance_checklist WHERE COALESCE(status,'open')='open')
  )
$function$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.profiles (
    id, nama_lengkap, no_hp, nik, desa, alamat,
    verification_status, requested_role
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nama_lengkap', ''),
    NEW.raw_user_meta_data->>'no_hp',
    NEW.raw_user_meta_data->>'nik',
    NEW.raw_user_meta_data->>'desa',
    NEW.raw_user_meta_data->>'alamat',
    'pending_verification',
    COALESCE(
      NULLIF(NEW.raw_user_meta_data->>'requested_role','')::public.app_role,
      'warga'::public.app_role
    )
  )
  ON CONFLICT (id) DO NOTHING;
  -- SENGAJA TIDAK INSERT ke user_roles. Role hanya diberikan via approval.
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.has_permission(_user_id uuid, _permission_code text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT public.has_role(_user_id, 'super_admin'::public.app_role)
      OR _permission_code = ANY (public.get_effective_permissions(_user_id));
$function$;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role app_role)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND role = _role
  )
$function$;

CREATE OR REPLACE FUNCTION public.is_admin_pemda(_uid uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT public.has_role(_uid,'super_admin'::app_role) OR public.has_role(_uid,'admin_pemda'::app_role);
$function$;

CREATE OR REPLACE FUNCTION public.is_bupati(_uid uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.pejabat
    WHERE user_id = _uid
      AND COALESCE(aktif, true) = true
      AND pimpinan_type = 'bupati'
  );
$function$;

CREATE OR REPLACE FUNCTION public.is_elevated_view(_uid uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT public.has_role(_uid,'super_admin'::app_role)
      OR public.has_role(_uid,'admin_pemda'::app_role)
      OR public.has_role(_uid,'pimpinan'::app_role);
$function$;

CREATE OR REPLACE FUNCTION public.is_executive(_uid uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT public.has_role(_uid,'super_admin'::app_role)
      OR public.has_role(_uid,'admin_pemda'::app_role)
      OR public.has_role(_uid,'pimpinan'::app_role);
$function$;

CREATE OR REPLACE FUNCTION public.is_pemohon_in_admin_desa(_admin_uid uuid, _pemohon_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles pr
    WHERE pr.id = _pemohon_id
      AND pr.desa IS NOT NULL
      AND pr.desa = public.get_user_desa(_admin_uid)
  );
$function$;

CREATE OR REPLACE FUNCTION public.is_pemohon_in_admin_desa(_pemohon_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = _pemohon_id
      AND p.desa IS NOT NULL
      AND p.desa = public.get_user_desa(auth.uid())
  )
$function$;

CREATE OR REPLACE FUNCTION public.is_pemohon_in_admin_opd(_admin_uid uuid, _pemohon_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.permohonan p
    WHERE p.pemohon_id = _pemohon_id
      AND p.opd_id = public.get_user_opd(_admin_uid)
  );
$function$;

CREATE OR REPLACE FUNCTION public.is_pimpinan(_uid uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT public.has_role(_uid,'pimpinan'::app_role);
$function$;

CREATE OR REPLACE FUNCTION public.is_profile_pemohon_in_admin_opd(_profile_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.permohonan pm
    WHERE pm.pemohon_id = _profile_id
      AND pm.opd_id = public.get_user_opd(auth.uid())
  )
$function$;

CREATE OR REPLACE FUNCTION public.layanan_kinerja_agg(_from date DEFAULT NULL::date, _to date DEFAULT NULL::date, _opd_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ SELECT '[]'::jsonb $function$;

CREATE OR REPLACE FUNCTION public.log_permohonan_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF TG_OP='UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO public.audit_log (user_id, aksi, entitas, entitas_id, data_sebelum, data_sesudah)
    VALUES (auth.uid(),'permohonan.status_changed','permohonan',NEW.id::text,
      jsonb_build_object('status',OLD.status), jsonb_build_object('status',NEW.status));
  END IF;
  RETURN NEW;
END; $function$;

CREATE OR REPLACE FUNCTION public.migrasi_dataset_ke_forms(_template_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ SELECT jsonb_build_object('ok', true) $function$;

CREATE OR REPLACE FUNCTION public.next_bukti_nomor(_kind text, _opd_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  _tahun int := EXTRACT(YEAR FROM now())::int;
  _bulan int := EXTRACT(MONTH FROM now())::int;
  _seq int;
  _singkatan text;
  _prefix text;
  _opd uuid := COALESCE(_opd_id, '00000000-0000-0000-0000-000000000000'::uuid);
BEGIN
  INSERT INTO public.bukti_nomor_sequence(kind, opd_id, tahun, bulan, last_number)
  VALUES (_kind, _opd, _tahun, _bulan, 1)
  ON CONFLICT (kind, opd_id, tahun, bulan)
  DO UPDATE SET last_number = public.bukti_nomor_sequence.last_number + 1, updated_at = now()
  RETURNING last_number INTO _seq;

  SELECT COALESCE(singkatan,'OPD') INTO _singkatan FROM public.opd WHERE id = _opd_id;
  _prefix := CASE _kind WHEN 'aset' THEN 'AST' WHEN 'izin_asn' THEN 'IZN' ELSE 'PMH' END;

  RETURN _prefix || '/' || LPAD(_seq::text,4,'0') || '/' || COALESCE(_singkatan,'OPD') || '/' || LPAD(_bulan::text,2,'0') || '/' || _tahun::text;
END;
$function$;

CREATE OR REPLACE FUNCTION public.opd_attendance_today(_opd_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(user_id uuid, nama_lengkap text, opd_id uuid, tipe text, waktu timestamp with time zone, is_late boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT a.user_id, COALESCE(p.nama_lengkap, ''), a.opd_id, a.tipe, a.waktu, a.is_late
  FROM public.absensi_asn a
  LEFT JOIN public.profiles p ON p.id = a.user_id
  WHERE a.waktu::date = CURRENT_DATE
    AND (_opd_id IS NULL OR a.opd_id = _opd_id)
$function$;

CREATE OR REPLACE FUNCTION public.opd_kategori_benchmark(_kategori text DEFAULT NULL::text)
 RETURNS TABLE(opd_id uuid, opd_nama text, opd_singkatan text, total bigint, selesai bigint, skor numeric)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT o.id,
    o.nama,
    o.singkatan,
    COUNT(p.id)::bigint,
    COUNT(p.id) FILTER (WHERE p.status = 'selesai')::bigint,
    LEAST(100, COUNT(p.id)::numeric)
  FROM public.opd o
  LEFT JOIN public.permohonan p ON p.opd_id = o.id AND (_kategori IS NULL OR p.kategori = _kategori)
  GROUP BY o.id, o.nama, o.singkatan
$function$;

CREATE OR REPLACE FUNCTION public.opd_kinerja_agg()
 RETURNS TABLE(opd_id uuid, status text, total bigint, total_hari_selesai numeric, jumlah_selesai bigint, tepat_waktu bigint, selesai_dengan_sla bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
SELECT p.opd_id, p.status::text, COUNT(*)::bigint,
  COALESCE(SUM(CASE WHEN p.status='selesai' AND p.tanggal_masuk IS NOT NULL AND p.updated_at IS NOT NULL THEN EXTRACT(EPOCH FROM (p.updated_at - p.tanggal_masuk))/86400.0 ELSE 0 END),0)::numeric,
  COUNT(*) FILTER (WHERE p.status='selesai' AND p.tanggal_masuk IS NOT NULL AND p.updated_at IS NOT NULL)::bigint,
  COUNT(*) FILTER (WHERE p.status='selesai' AND p.tenggat IS NOT NULL AND p.updated_at <= p.tenggat)::bigint,
  COUNT(*) FILTER (WHERE p.status='selesai' AND p.tenggat IS NOT NULL)::bigint
FROM public.permohonan p GROUP BY p.opd_id, p.status;
$function$;

CREATE OR REPLACE FUNCTION public.opd_kinerja_trend(_opd uuid DEFAULT NULL::uuid, _months integer DEFAULT 12, _opd_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(bulan text, masuk bigint, selesai bigint, on_time bigint, selesai_dengan_sla bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT to_char(date_trunc('month', p.tanggal_masuk), 'YYYY-MM') AS bulan,
    COUNT(*)::bigint AS masuk,
    COUNT(*) FILTER (WHERE p.status = 'selesai')::bigint AS selesai,
    COUNT(*) FILTER (WHERE p.status = 'selesai' AND (p.tenggat IS NULL OR p.updated_at <= p.tenggat))::bigint AS on_time,
    COUNT(*) FILTER (WHERE p.status = 'selesai' AND p.tenggat IS NOT NULL)::bigint AS selesai_dengan_sla
  FROM public.permohonan p
  WHERE p.tanggal_masuk >= date_trunc('month', now()) - make_interval(months => COALESCE(_months, 12))
    AND (COALESCE(_opd, _opd_id) IS NULL OR p.opd_id = COALESCE(_opd, _opd_id))
  GROUP BY date_trunc('month', p.tanggal_masuk)
  ORDER BY 1
$function$;

CREATE OR REPLACE FUNCTION public.opd_rating_agg()
 RETURNS TABLE(opd_id uuid, total_rating bigint, jumlah_rating bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
SELECT p.opd_id, COALESCE(SUM(r.skor),0)::bigint, COUNT(r.id)::bigint
FROM public.permohonan p JOIN public.permohonan_rating r ON r.permohonan_id = p.id
WHERE p.opd_id IS NOT NULL GROUP BY p.opd_id; $function$;

CREATE OR REPLACE FUNCTION public.opd_skor_komposit(_from date DEFAULT NULL::date, _to date DEFAULT NULL::date)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ SELECT '[]'::jsonb $function$;

CREATE OR REPLACE FUNCTION public.permohonan_autogen_kode()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  n bigint;
BEGIN
  IF NEW.kode IS NULL OR length(btrim(NEW.kode)) = 0 THEN
    n := nextval('public.permohonan_kode_seq');
    NEW.kode := 'PMH-' || to_char(now(), 'YYYYMM') || '-' || lpad(n::text, 6, '0');
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.permohonan_status_guard()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  allowed text[];
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.status IS DISTINCT FROM OLD.status THEN
    allowed := CASE OLD.status::text
      WHEN 'baru'             THEN ARRAY['diproses','menunggu_dokumen','ditolak']
      WHEN 'menunggu_dokumen' THEN ARRAY['diproses','ditolak']
      WHEN 'diproses'         THEN ARRAY['selesai','ditolak','menunggu_dokumen']
      WHEN 'selesai'          THEN ARRAY[]::text[]
      WHEN 'ditolak'          THEN ARRAY[]::text[]
      ELSE ARRAY[]::text[]
    END;
    IF NOT (NEW.status::text = ANY(allowed)) THEN
      RAISE EXCEPTION 'Transisi status permohonan tidak valid: % -> %', OLD.status, NEW.status
        USING ERRCODE = 'check_violation';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.prevent_self_role_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF auth.uid() IS NOT NULL AND NEW.user_id = auth.uid() THEN
    RAISE EXCEPTION 'Pengguna tidak diizinkan mengubah perannya sendiri';
  END IF;
  RETURN NEW;
END; $function$;

CREATE OR REPLACE FUNCTION public.prevent_unverified_role_insert()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  _status text;
BEGIN
  -- Role internal yang granted via menu RBAC (super_admin / admin_pemda / pimpinan):
  -- tetap diizinkan tanpa cek status (grant manual super_admin).
  IF NEW.role IN ('super_admin','admin_pemda','pimpinan') THEN
    RETURN NEW;
  END IF;

  SELECT verification_status INTO _status
  FROM public.profiles WHERE id = NEW.user_id;

  IF _status IS DISTINCT FROM 'verified' THEN
    RAISE EXCEPTION 'Role % tidak boleh diberikan: akun belum diverifikasi (status=%)',
      NEW.role, COALESCE(_status,'NULL')
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.production_health_score()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT jsonb_build_object(
    'score', 85,
    'cron_recent_success', (SELECT COUNT(*) FROM public.cron_history WHERE started_at > now() - interval '24 hours' AND COALESCE(status,'ok')='ok'),
    'cron_recent_fail', (SELECT COUNT(*) FROM public.cron_history WHERE started_at > now() - interval '24 hours' AND status='error'),
    'dead_letter_count', (SELECT COUNT(*) FROM public.dead_letter_jobs WHERE resolved_at IS NULL),
    'retry_queue_count', (SELECT COUNT(*) FROM public.retry_queue WHERE COALESCE(status,'pending')='pending'),
    'generated_at', now()
  )
$function$;

CREATE OR REPLACE FUNCTION public.protect_system_jabatan()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.is_system THEN
      RAISE EXCEPTION 'Jabatan sistem tidak dapat dihapus';
    END IF;
    RETURN OLD;
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.is_system THEN
    IF NEW.is_system = false THEN
      RAISE EXCEPTION 'Status jabatan sistem tidak dapat diubah';
    END IF;
    IF NEW.system_position IS DISTINCT FROM OLD.system_position THEN
      RAISE EXCEPTION 'Klasifikasi jabatan sistem tidak dapat diubah';
    END IF;
    IF NEW.kode IS DISTINCT FROM OLD.kode THEN
      RAISE EXCEPTION 'Kode jabatan sistem tidak dapat diubah';
    END IF;
  END IF;
  RETURN NEW;
END $function$;

CREATE OR REPLACE FUNCTION public.rate_limit_increment(_scope text, _subject text, _window_start timestamp with time zone)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE _c integer;
BEGIN
  INSERT INTO public.rate_limit_bucket(scope, subject, window_start, count)
  VALUES (_scope, _subject, _window_start, 1)
  ON CONFLICT (scope, subject, window_start)
  DO UPDATE SET count = public.rate_limit_bucket.count + 1
  RETURNING count INTO _c;
  RETURN _c;
END $function$;

CREATE OR REPLACE FUNCTION public.rate_limit_increment(_scope text, _subject text, _window_start timestamp with time zone, _limit integer DEFAULT 60)
 RETURNS TABLE(allowed boolean, count integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE c integer;
BEGIN
  INSERT INTO public.rate_limit_hits(scope, subject, window_start, count, last_hit_at) VALUES (_scope,_subject,_window_start,1,now())
  ON CONFLICT DO NOTHING;
  UPDATE public.rate_limit_hits SET count=rate_limit_hits.count+1, last_hit_at=now() WHERE scope=_scope AND subject=_subject AND window_start=_window_start RETURNING rate_limit_hits.count INTO c;
  RETURN QUERY SELECT COALESCE(c,1) <= COALESCE(_limit,60), COALESCE(c,1);
END $function$;

CREATE OR REPLACE FUNCTION public.rating_list_admin(_from timestamp with time zone DEFAULT NULL::timestamp with time zone, _to timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS TABLE(rating_id uuid, skor integer, komentar text, created_at timestamp with time zone, user_id uuid, pemohon_nama text, permohonan_id uuid, permohonan_kode text, permohonan_judul text, opd_id uuid, opd_singkatan text, opd_nama text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT
    r.id AS rating_id,
    r.skor,
    r.komentar,
    r.created_at,
    r.user_id,
    pr.nama_lengkap AS pemohon_nama,
    p.id AS permohonan_id,
    p.kode AS permohonan_kode,
    p.judul AS permohonan_judul,
    p.opd_id,
    o.singkatan AS opd_singkatan,
    o.nama AS opd_nama
  FROM public.permohonan_rating r
  LEFT JOIN public.permohonan p ON p.id = r.permohonan_id
  LEFT JOIN public.profiles pr ON pr.id = r.user_id
  LEFT JOIN public.opd o ON o.id = p.opd_id
  WHERE (public.has_role(auth.uid(), 'super_admin'::public.app_role)
      OR public.has_role(auth.uid(), 'admin_pemda'::public.app_role))
    AND (_from IS NULL OR r.created_at >= _from)
    AND (_to IS NULL OR r.created_at <= _to)
  ORDER BY r.created_at DESC
  LIMIT 1000;
$function$;

CREATE OR REPLACE FUNCTION public.riwayat_dengan_petugas(_permohonan_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ SELECT '[]'::jsonb $function$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ BEGIN NEW.updated_at = now(); RETURN NEW; END; $function$;

CREATE OR REPLACE FUNCTION public.sync_compliance_aliases()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.judul IS NULL THEN NEW.judul := NEW.label; END IF;
  IF NEW.label IS NULL THEN NEW.label := NEW.judul; END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.sync_dataset_review_aliases()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.aksi IS NULL THEN
    NEW.aksi := NEW.action;
  END IF;
  IF NEW.action IS NULL THEN
    NEW.action := NEW.aksi;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.sync_dataset_submission_aliases()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.oleh_user_id IS NULL THEN
    NEW.oleh_user_id := NEW.user_id;
  END IF;
  IF NEW.user_id IS NULL THEN
    NEW.user_id := NEW.oleh_user_id;
  END IF;
  IF NEW.review_note IS NULL THEN
    NEW.review_note := NEW.catatan_review;
  END IF;
  IF NEW.catatan_review IS NULL THEN
    NEW.catatan_review := NEW.review_note;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.sync_dataset_template_aliases()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.opd_pemilik_id IS NULL THEN
    NEW.opd_pemilik_id := NEW.opd_id;
  END IF;
  IF NEW.opd_id IS NULL THEN
    NEW.opd_id := NEW.opd_pemilik_id;
  END IF;
  IF NEW.kode IS NULL OR NEW.kode = '' THEN
    NEW.kode := 'DST-' || upper(substr(COALESCE(NEW.id, gen_random_uuid())::text, 1, 8));
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.sync_feature_flag_aliases()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.flag_key IS NULL THEN NEW.flag_key := NEW.key; END IF;
  IF NEW.key IS NULL THEN NEW.key := NEW.flag_key; END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.sync_uat_aliases()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.code IS NULL THEN NEW.code := upper(regexp_replace(COALESCE(NEW.modul, 'UAT') || '-' || substr(COALESCE(NEW.id, gen_random_uuid())::text, 1, 6), '[^A-Za-z0-9_-]', '-', 'g')); END IF;
  IF NEW.judul IS NULL THEN NEW.judul := NEW.description; END IF;
  IF NEW.expected IS NULL THEN NEW.expected := NEW.description; END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.tg_app_setting_public_visibility()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.key IN (
      'site_branding',
      'show_opd_directory',
      'permohonan_require_verification',
      'data_terpadu_visible_public',
      'kinerja_opd_visible_public'
     ) OR NEW.key LIKE 'flag.%' OR NEW.category IN ('public','feature_flag') THEN
    NEW.public_visible := true;
  END IF;
  RETURN NEW;
END $function$;

CREATE OR REPLACE FUNCTION public.tg_bump_version_number()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    NEW.version_number := COALESCE(OLD.version_number, 0) + 1;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.tg_fb_audit_immutable()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RAISE EXCEPTION 'form_audit_logs is immutable (operation %)', TG_OP;
END $function$;

CREATE OR REPLACE FUNCTION public.tg_pengajuan_izin_set_saldo_flag()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.jenis = 'cuti_tahunan' AND NEW.mengurangi_saldo IS DISTINCT FROM true THEN
    NEW.mengurangi_saldo := true;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.tg_signature_event_notify()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE _req record; _judul text; _body text;
BEGIN
  IF NEW.event NOT IN ('signed','rejected','expired','cancelled','failed') THEN RETURN NEW; END IF;
  SELECT sr.created_by, gd.name AS doc_name, gd.doc_number
    INTO _req
  FROM public.signature_requests sr
  LEFT JOIN public.generated_documents gd ON gd.id = sr.document_id
  WHERE sr.id = NEW.request_id;
  IF _req.created_by IS NULL THEN RETURN NEW; END IF;
  _judul := CASE NEW.event
              WHEN 'signed' THEN 'Dokumen telah ditandatangani'
              WHEN 'rejected' THEN 'Permintaan TTE ditolak'
              WHEN 'expired' THEN 'Permintaan TTE kedaluwarsa'
              WHEN 'cancelled' THEN 'Permintaan TTE dibatalkan'
              ELSE 'Permintaan TTE gagal' END;
  _body := COALESCE(_req.doc_number,'') || ' ' || COALESCE(_req.doc_name,'Dokumen');
  BEGIN
    INSERT INTO public.notifications (user_id, tipe, judul, body, link, meta)
    VALUES (_req.created_by, 'tte', _judul, _body,
            '/admin/signature/requests/' || NEW.request_id::text,
            jsonb_build_object('event', NEW.event, 'request_id', NEW.request_id));
  EXCEPTION WHEN OTHERS THEN NULL; END;
  RETURN NEW;
END $function$;

CREATE OR REPLACE FUNCTION public.tg_signature_events_immutable()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN RAISE EXCEPTION 'signature_events is immutable (operation %)', TG_OP; END $function$;

CREATE OR REPLACE FUNCTION public.tg_signed_documents_validate_revoke()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.status = 'revoked' THEN
    IF NEW.revoke_reason IS NULL OR length(btrim(NEW.revoke_reason)) < 10 THEN
      RAISE EXCEPTION 'revoke_reason wajib diisi minimal 10 karakter';
    END IF;
    IF NEW.revoked_at IS NULL THEN
      NEW.revoked_at := now();
    END IF;
  END IF;
  RETURN NEW;
END $function$;

CREATE OR REPLACE FUNCTION public.tg_sync_profile_asn_classification()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  _jabatan record;
BEGIN
  IF NEW.asn_type = 'honorer' THEN
    NEW.asn_type := 'pppk_paruh_waktu';
  END IF;

  IF NEW.jabatan_id IS NOT NULL THEN
    SELECT id, kode, nama, kategori, system_position
      INTO _jabatan
    FROM public.master_jabatan
    WHERE id = NEW.jabatan_id
    LIMIT 1;

    IF _jabatan.id IS NOT NULL THEN
      NEW.jabatan := _jabatan.nama;
      NEW.system_position := COALESCE(
        _jabatan.system_position,
        public.derive_system_position_from_jabatan(_jabatan.kode, _jabatan.nama, _jabatan.kategori),
        NEW.system_position
      );
    END IF;
  ELSIF NEW.jabatan IS NOT NULL AND (NEW.system_position IS NULL OR NEW.system_position = 'lainnya') THEN
    NEW.system_position := public.derive_system_position_from_jabatan(NULL, NEW.jabatan, NULL);
  END IF;

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.tg_touch_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN NEW.updated_at = now(); RETURN NEW; END $function$;

CREATE OR REPLACE FUNCTION public.trg_laporan_before_insert()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.ticket_code IS NULL OR NEW.ticket_code = '' THEN
    NEW.ticket_code := public.fn_generate_laporan_ticket();
  END IF;
  IF NEW.pelapor_id IS NULL THEN
    NEW.pelapor_id := auth.uid();
  END IF;
  RETURN NEW;
END $function$;

-- ---------- VIEWS ----------
CREATE OR REPLACE VIEW public.v_permohonan_overdue
WITH (security_invoker = on) AS
 SELECT id,
    kode,
    judul,
    opd_id,
    status,
    tanggal_masuk,
    tenggat,
    GREATEST(0::numeric, ceil(EXTRACT(epoch FROM now() - tenggat) / 86400.0))::integer AS overdue_days,
    GREATEST(0, EXTRACT(epoch FROM now() - tenggat)::integer) AS overdue_seconds
   FROM public.permohonan p
  WHERE tenggat IS NOT NULL AND tenggat < now() AND (status <> ALL (ARRAY['selesai'::text, 'ditolak'::text]));

-- ---------- TRIGGERS ----------
DROP TRIGGER IF EXISTS app_setting_public_visibility ON public.app_setting;
CREATE TRIGGER app_setting_public_visibility BEFORE INSERT OR UPDATE ON public.app_setting FOR EACH ROW EXECUTE FUNCTION tg_app_setting_public_visibility();
DROP TRIGGER IF EXISTS aset_updated_at ON public.aset;
CREATE TRIGGER aset_updated_at BEFORE UPDATE ON public.aset FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS bukti_dokumen_touch ON public.bukti_dokumen;
CREATE TRIGGER bukti_dokumen_touch BEFORE UPDATE ON public.bukti_dokumen FOR EACH ROW EXECUTE FUNCTION tg_touch_updated_at();
DROP TRIGGER IF EXISTS bukti_template_override_touch ON public.bukti_template_override;
CREATE TRIGGER bukti_template_override_touch BEFORE UPDATE ON public.bukti_template_override FOR EACH ROW EXECUTE FUNCTION tg_touch_updated_at();
DROP TRIGGER IF EXISTS fb_audit_no_delete ON public.form_audit_logs;
CREATE TRIGGER fb_audit_no_delete BEFORE DELETE ON public.form_audit_logs FOR EACH ROW EXECUTE FUNCTION tg_fb_audit_immutable();
DROP TRIGGER IF EXISTS fb_audit_no_update ON public.form_audit_logs;
CREATE TRIGGER fb_audit_no_update BEFORE UPDATE ON public.form_audit_logs FOR EACH ROW EXECUTE FUNCTION tg_fb_audit_immutable();
DROP TRIGGER IF EXISTS fwd_updated_at ON public.form_wizard_drafts;
CREATE TRIGGER fwd_updated_at BEFORE UPDATE ON public.form_wizard_drafts FOR EACH ROW EXECUTE FUNCTION fwd_set_updated_at();
DROP TRIGGER IF EXISTS kantor_qr_updated_at ON public.kantor_qr;
CREATE TRIGGER kantor_qr_updated_at BEFORE UPDATE ON public.kantor_qr FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS laporan_before_insert ON public.laporan_masyarakat;
CREATE TRIGGER laporan_before_insert BEFORE INSERT ON public.laporan_masyarakat FOR EACH ROW EXECUTE FUNCTION trg_laporan_before_insert();
DROP TRIGGER IF EXISTS set_leave_balances_updated_at ON public.leave_balances;
CREATE TRIGGER set_leave_balances_updated_at BEFORE UPDATE ON public.leave_balances FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS set_lokasi_gedung_updated_at ON public.lokasi_gedung;
CREATE TRIGGER set_lokasi_gedung_updated_at BEFORE UPDATE ON public.lokasi_gedung FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS set_lokasi_lantai_updated_at ON public.lokasi_lantai;
CREATE TRIGGER set_lokasi_lantai_updated_at BEFORE UPDATE ON public.lokasi_lantai FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS set_lokasi_ruangan_updated_at ON public.lokasi_ruangan;
CREATE TRIGGER set_lokasi_ruangan_updated_at BEFORE UPDATE ON public.lokasi_ruangan FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS set_updated_at ON public.workflow_definitions;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.workflow_definitions FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS set_updated_at ON public.submission_tasks;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.submission_tasks FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS set_updated_at ON public.document_templates;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.document_templates FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS set_updated_at ON public.form_templates;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.form_templates FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_announcements_updated ON public.announcements;
CREATE TRIGGER trg_announcements_updated BEFORE UPDATE ON public.announcements FOR EACH ROW EXECUTE FUNCTION announcements_set_updated_at();
DROP TRIGGER IF EXISTS trg_announcements_updated_at ON public.announcements;
CREATE TRIGGER trg_announcements_updated_at BEFORE UPDATE ON public.announcements FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_app_setting_updated_at ON public.app_setting;
CREATE TRIGGER trg_app_setting_updated_at BEFORE UPDATE ON public.app_setting FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_aset_bump_version ON public.aset;
CREATE TRIGGER trg_aset_bump_version BEFORE UPDATE ON public.aset FOR EACH ROW EXECUTE FUNCTION tg_bump_version_number();
DROP TRIGGER IF EXISTS trg_berita_updated ON public.berita;
CREATE TRIGGER trg_berita_updated BEFORE UPDATE ON public.berita FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_bukti_dok_updated ON public.bukti_dokumen;
CREATE TRIGGER trg_bukti_dok_updated BEFORE UPDATE ON public.bukti_dokumen FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_bukti_dokumen_updated ON public.bukti_dokumen;
CREATE TRIGGER trg_bukti_dokumen_updated BEFORE UPDATE ON public.bukti_dokumen FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_bukti_template_override_updated ON public.bukti_template_override;
CREATE TRIGGER trg_bukti_template_override_updated BEFORE UPDATE ON public.bukti_template_override FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_bukti_tpl_updated ON public.bukti_template_override;
CREATE TRIGGER trg_bukti_tpl_updated BEFORE UPDATE ON public.bukti_template_override FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_data_terpadu_updated_at ON public.data_terpadu_item;
CREATE TRIGGER trg_data_terpadu_updated_at BEFORE UPDATE ON public.data_terpadu_item FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_desa_updated ON public.desa;
CREATE TRIGGER trg_desa_updated BEFORE UPDATE ON public.desa FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_feature_flags_updated ON public.feature_flags;
CREATE TRIGGER trg_feature_flags_updated BEFORE UPDATE ON public.feature_flags FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_form_assignments_bump_version ON public.form_assignments;
CREATE TRIGGER trg_form_assignments_bump_version BEFORE UPDATE ON public.form_assignments FOR EACH ROW EXECUTE FUNCTION tg_bump_version_number();
DROP TRIGGER IF EXISTS trg_kategori_updated ON public.kategori_layanan;
CREATE TRIGGER trg_kategori_updated BEFORE UPDATE ON public.kategori_layanan FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_laporan_updated ON public.laporan_masyarakat;
CREATE TRIGGER trg_laporan_updated BEFORE UPDATE ON public.laporan_masyarakat FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_layanan_updated ON public.layanan_publik;
CREATE TRIGGER trg_layanan_updated BEFORE UPDATE ON public.layanan_publik FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_master_jabatan_updated_at ON public.master_jabatan;
CREATE TRIGGER trg_master_jabatan_updated_at BEFORE UPDATE ON public.master_jabatan FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_pejabat_updated ON public.pejabat;
CREATE TRIGGER trg_pejabat_updated BEFORE UPDATE ON public.pejabat FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_pengajuan_izin_saldo_flag ON public.pengajuan_izin;
CREATE TRIGGER trg_pengajuan_izin_saldo_flag BEFORE INSERT ON public.pengajuan_izin FOR EACH ROW EXECUTE FUNCTION tg_pengajuan_izin_set_saldo_flag();
DROP TRIGGER IF EXISTS trg_permohonan_audit ON public.permohonan;
CREATE TRIGGER trg_permohonan_audit AFTER UPDATE ON public.permohonan FOR EACH ROW EXECUTE FUNCTION log_permohonan_change();
DROP TRIGGER IF EXISTS trg_permohonan_autogen_kode ON public.permohonan;
CREATE TRIGGER trg_permohonan_autogen_kode BEFORE INSERT ON public.permohonan FOR EACH ROW EXECUTE FUNCTION permohonan_autogen_kode();
DROP TRIGGER IF EXISTS trg_permohonan_status_guard ON public.permohonan;
CREATE TRIGGER trg_permohonan_status_guard BEFORE UPDATE OF status ON public.permohonan FOR EACH ROW EXECUTE FUNCTION permohonan_status_guard();
DROP TRIGGER IF EXISTS trg_permohonan_updated ON public.permohonan;
CREATE TRIGGER trg_permohonan_updated BEFORE UPDATE ON public.permohonan FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_prevent_self_role_change ON public.user_roles;
CREATE TRIGGER trg_prevent_self_role_change BEFORE INSERT OR UPDATE ON public.user_roles FOR EACH ROW EXECUTE FUNCTION prevent_self_role_change();
DROP TRIGGER IF EXISTS trg_prevent_unverified_role_insert ON public.user_roles;
CREATE TRIGGER trg_prevent_unverified_role_insert BEFORE INSERT ON public.user_roles FOR EACH ROW EXECUTE FUNCTION prevent_unverified_role_insert();
DROP TRIGGER IF EXISTS trg_profiles_updated ON public.profiles;
CREATE TRIGGER trg_profiles_updated BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_protect_system_jabatan ON public.master_jabatan;
CREATE TRIGGER trg_protect_system_jabatan BEFORE DELETE OR UPDATE ON public.master_jabatan FOR EACH ROW EXECUTE FUNCTION protect_system_jabatan();
DROP TRIGGER IF EXISTS trg_push_sub_updated_at ON public.push_subscription;
CREATE TRIGGER trg_push_sub_updated_at BEFORE UPDATE ON public.push_subscription FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_sigevt_immutable ON public.signature_events;
CREATE TRIGGER trg_sigevt_immutable BEFORE DELETE OR UPDATE ON public.signature_events FOR EACH ROW EXECUTE FUNCTION tg_signature_events_immutable();
DROP TRIGGER IF EXISTS trg_signature_providers_updated ON public.signature_providers;
CREATE TRIGGER trg_signature_providers_updated BEFORE UPDATE ON public.signature_providers FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_sigreq_updated ON public.signature_requests;
CREATE TRIGGER trg_sigreq_updated BEFORE UPDATE ON public.signature_requests FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_sigsigner_updated ON public.signature_request_signers;
CREATE TRIGGER trg_sigsigner_updated BEFORE UPDATE ON public.signature_request_signers FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_sync_compliance_aliases ON public.compliance_checklist;
CREATE TRIGGER trg_sync_compliance_aliases BEFORE INSERT OR UPDATE ON public.compliance_checklist FOR EACH ROW EXECUTE FUNCTION sync_compliance_aliases();
DROP TRIGGER IF EXISTS trg_sync_dataset_review_aliases ON public.dataset_submission_review;
CREATE TRIGGER trg_sync_dataset_review_aliases BEFORE INSERT OR UPDATE ON public.dataset_submission_review FOR EACH ROW EXECUTE FUNCTION sync_dataset_review_aliases();
DROP TRIGGER IF EXISTS trg_sync_dataset_submission_aliases ON public.dataset_submission;
CREATE TRIGGER trg_sync_dataset_submission_aliases BEFORE INSERT OR UPDATE ON public.dataset_submission FOR EACH ROW EXECUTE FUNCTION sync_dataset_submission_aliases();
DROP TRIGGER IF EXISTS trg_sync_dataset_template_aliases ON public.dataset_template;
CREATE TRIGGER trg_sync_dataset_template_aliases BEFORE INSERT OR UPDATE ON public.dataset_template FOR EACH ROW EXECUTE FUNCTION sync_dataset_template_aliases();
DROP TRIGGER IF EXISTS trg_sync_feature_flag_aliases ON public.feature_flags;
CREATE TRIGGER trg_sync_feature_flag_aliases BEFORE INSERT OR UPDATE ON public.feature_flags FOR EACH ROW EXECUTE FUNCTION sync_feature_flag_aliases();
DROP TRIGGER IF EXISTS trg_sync_uat_aliases ON public.uat_scenarios;
CREATE TRIGGER trg_sync_uat_aliases BEFORE INSERT OR UPDATE ON public.uat_scenarios FOR EACH ROW EXECUTE FUNCTION sync_uat_aliases();
DROP TRIGGER IF EXISTS trg_workflow_templates_updated ON public.workflow_templates;
CREATE TRIGGER trg_workflow_templates_updated BEFORE UPDATE ON public.workflow_templates FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------- ROW LEVEL SECURITY ----------
ALTER TABLE public.absensi_asn ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_setting ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aset ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aset_bast ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aset_bast_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aset_mutasi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aset_nilai_buku ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aset_opname ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aset_opname_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aset_pemeliharaan ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aset_penyusutan_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aset_riwayat ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aset_verification_campaign ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aset_verification_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_shift_assignment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_snapshot ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.berita ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branding ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bukti_dokumen ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bukti_nomor_seq ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bukti_nomor_sequence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bukti_template_override ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compliance_checklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consent_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cron_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.data_terpadu_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dataset_submission ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dataset_submission_review ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dataset_template ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dead_letter_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.desa ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.digital_signatures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_numbering_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_numbering_sequences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_template_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dokumen_verifikasi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escalation_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_submission_comment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_submission_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_submission_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_wizard_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.generated_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.geofence_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hari_libur ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ikm_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ikm_surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jabatan_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kantor_qr ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kategori_layanan ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.laporan_masyarakat ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.laporan_ticket_sequence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.layanan_publik ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lokasi_gedung ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lokasi_lantai ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lokasi_ruangan ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.master_jabatan ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nomor_surat_issued ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nomor_surat_sequence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.opd ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.overtime_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pejabat ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pengajuan_izin ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permohonan ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permohonan_berkas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permohonan_rating ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permohonan_riwayat ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_subscription ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_test_sink ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_test_sub ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limit ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limit_bucket ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limit_hits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rbac_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.retention_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.retry_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.signature_delegations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.signature_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.signature_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.signature_request_signers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.signature_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.signed_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.signing_certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_delegations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_dispositions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_escalations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_sequences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_sla_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_values ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.uat_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.uat_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_token ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_schedule_assignment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workflow_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workflow_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workflow_edges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workflow_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workflow_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workflow_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workflow_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workflows ENABLE ROW LEVEL SECURITY;

-- ---------- POLICIES ----------
DROP POLICY IF EXISTS "ASN tambah absensi sendiri" ON public.absensi_asn;
CREATE POLICY "ASN tambah absensi sendiri" ON public.absensi_asn AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((auth.uid() = user_id));
DROP POLICY IF EXISTS "abs_ins" ON public.absensi_asn;
CREATE POLICY "abs_ins" ON public.absensi_asn AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((user_id = auth.uid()));
DROP POLICY IF EXISTS "ann_targets_all" ON public.announcement_targets;
CREATE POLICY "ann_targets_all" ON public.announcement_targets AS PERMISSIVE FOR ALL TO authenticated
  USING ((EXISTS ( SELECT 1
   FROM announcements a
  WHERE ((a.id = announcement_targets.announcement_id) AND (has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (a.created_by = auth.uid()) OR ((a.opd_pemilik_id IS NOT NULL) AND (a.opd_pemilik_id = get_user_opd(auth.uid()))))))))
  WITH CHECK ((EXISTS ( SELECT 1
   FROM announcements a
  WHERE ((a.id = announcement_targets.announcement_id) AND (has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (a.created_by = auth.uid()) OR ((a.opd_pemilik_id IS NOT NULL) AND (a.opd_pemilik_id = get_user_opd(auth.uid()))))))));
DROP POLICY IF EXISTS "announcement_targets_manage_admin" ON public.announcement_targets;
CREATE POLICY "announcement_targets_manage_admin" ON public.announcement_targets AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role)));
DROP POLICY IF EXISTS "announcement_targets_select_all" ON public.announcement_targets;
CREATE POLICY "announcement_targets_select_all" ON public.announcement_targets AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "announcements_manage_admin" ON public.announcements;
CREATE POLICY "announcements_manage_admin" ON public.announcements AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role)));
DROP POLICY IF EXISTS "announcements_read" ON public.announcements;
CREATE POLICY "announcements_read" ON public.announcements AS PERMISSIVE FOR SELECT TO authenticated
  USING (((status = 'published'::text) OR (created_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR ((opd_pemilik_id IS NOT NULL) AND (opd_pemilik_id = get_user_opd(auth.uid())))));
DROP POLICY IF EXISTS "announcements_select_published_all" ON public.announcements;
CREATE POLICY "announcements_select_published_all" ON public.announcements AS PERMISSIVE FOR SELECT TO authenticated
  USING (((status = 'published'::text) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role)));
DROP POLICY IF EXISTS "announcements_write" ON public.announcements;
CREATE POLICY "announcements_write" ON public.announcements AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR ((opd_pemilik_id IS NOT NULL) AND (opd_pemilik_id = get_user_opd(auth.uid())))))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR ((opd_pemilik_id IS NOT NULL) AND (opd_pemilik_id = get_user_opd(auth.uid())))));
DROP POLICY IF EXISTS "App setting publik baca" ON public.app_setting;
CREATE POLICY "App setting publik baca" ON public.app_setting AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING ((public_visible = true));
DROP POLICY IF EXISTS "app_setting public read (visible only)" ON public.app_setting;
CREATE POLICY "app_setting public read (visible only)" ON public.app_setting AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING ((public_visible = true));
DROP POLICY IF EXISTS "app_setting super admin insert" ON public.app_setting;
CREATE POLICY "app_setting super admin insert" ON public.app_setting AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (has_role(auth.uid(), 'super_admin'::app_role));
DROP POLICY IF EXISTS "app_setting super admin read" ON public.app_setting;
CREATE POLICY "app_setting super admin read" ON public.app_setting AS PERMISSIVE FOR SELECT TO authenticated
  USING (has_role(auth.uid(), 'super_admin'::app_role));
DROP POLICY IF EXISTS "app_setting super admin update" ON public.app_setting;
CREATE POLICY "app_setting super admin update" ON public.app_setting AS PERMISSIVE FOR UPDATE TO authenticated
  USING (has_role(auth.uid(), 'super_admin'::app_role))
  WITH CHECK (has_role(auth.uid(), 'super_admin'::app_role));
DROP POLICY IF EXISTS "app_setting_public_read_safety" ON public.app_setting;
CREATE POLICY "app_setting_public_read_safety" ON public.app_setting AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING ((public_visible = true));
DROP POLICY IF EXISTS "aset_read" ON public.aset;
CREATE POLICY "aset_read" ON public.aset AS PERMISSIVE FOR SELECT TO authenticated
  USING ((is_elevated_view(auth.uid()) OR (opd_id = get_user_opd(auth.uid())) OR (pemegang_user_id = auth.uid())));
DROP POLICY IF EXISTS "aset_bast_opd_read" ON public.aset_bast;
CREATE POLICY "aset_bast_opd_read" ON public.aset_bast AS PERMISSIVE FOR SELECT TO authenticated
  USING (((opd_id = get_user_opd(auth.uid())) OR (pemberi_user = auth.uid()) OR (penerima_user = auth.uid())));
DROP POLICY IF EXISTS "aset_mutasi_insert" ON public.aset_mutasi;
CREATE POLICY "aset_mutasi_insert" ON public.aset_mutasi AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((diajukan_oleh = auth.uid()));
DROP POLICY IF EXISTS "aset_mutasi_opd_select" ON public.aset_mutasi;
CREATE POLICY "aset_mutasi_opd_select" ON public.aset_mutasi AS PERMISSIVE FOR SELECT TO authenticated
  USING (((dari_opd = get_user_opd(auth.uid())) OR (ke_opd = get_user_opd(auth.uid())) OR (diajukan_oleh = auth.uid())));
DROP POLICY IF EXISTS "aset_nilai_buku admin read" ON public.aset_nilai_buku;
CREATE POLICY "aset_nilai_buku admin read" ON public.aset_nilai_buku AS PERMISSIVE FOR SELECT TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role)));
DROP POLICY IF EXISTS "aset_opname_opd" ON public.aset_opname;
CREATE POLICY "aset_opname_opd" ON public.aset_opname AS PERMISSIVE FOR ALL TO authenticated
  USING ((opd_id = get_user_opd(auth.uid())))
  WITH CHECK ((opd_id = get_user_opd(auth.uid())));
DROP POLICY IF EXISTS "aset_pemeliharaan_opd" ON public.aset_pemeliharaan;
CREATE POLICY "aset_pemeliharaan_opd" ON public.aset_pemeliharaan AS PERMISSIVE FOR ALL TO authenticated
  USING ((opd_id = get_user_opd(auth.uid())))
  WITH CHECK ((opd_id = get_user_opd(auth.uid())));
DROP POLICY IF EXISTS "aset_penyusutan_select_opd" ON public.aset_penyusutan_history;
CREATE POLICY "aset_penyusutan_select_opd" ON public.aset_penyusutan_history AS PERMISSIVE FOR SELECT TO authenticated
  USING ((EXISTS ( SELECT 1
   FROM aset a
  WHERE ((a.id = aset_penyusutan_history.aset_id) AND ((a.opd_id = get_user_opd(auth.uid())) OR (a.pemegang_user_id = auth.uid()))))));
DROP POLICY IF EXISTS "Riwayat aset baca login" ON public.aset_riwayat;
CREATE POLICY "Riwayat aset baca login" ON public.aset_riwayat AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "asr_read" ON public.aset_riwayat;
CREATE POLICY "asr_read" ON public.aset_riwayat AS PERMISSIVE FOR SELECT TO authenticated
  USING ((EXISTS ( SELECT 1
   FROM aset a
  WHERE ((a.id = aset_riwayat.aset_id) AND (is_elevated_view(auth.uid()) OR (a.opd_id = get_user_opd(auth.uid())) OR (a.pemegang_user_id = auth.uid()))))));
DROP POLICY IF EXISTS "aset_vc_opd" ON public.aset_verification_campaign;
CREATE POLICY "aset_vc_opd" ON public.aset_verification_campaign AS PERMISSIVE FOR ALL TO authenticated
  USING ((opd_id = get_user_opd(auth.uid())))
  WITH CHECK ((opd_id = get_user_opd(auth.uid())));
DROP POLICY IF EXISTS "att_shifts_select" ON public.attendance_shifts;
CREATE POLICY "att_shifts_select" ON public.attendance_shifts AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "User insert own audit log" ON public.audit_log;
CREATE POLICY "User insert own audit log" ON public.audit_log AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((auth.uid() = user_id));
DROP POLICY IF EXISTS "al_read" ON public.audit_log;
CREATE POLICY "al_read" ON public.audit_log AS PERMISSIVE FOR SELECT TO authenticated
  USING (is_admin_pemda(auth.uid()));
DROP POLICY IF EXISTS "Berita terbit publik" ON public.berita;
CREATE POLICY "Berita terbit publik" ON public.berita AS PERMISSIVE FOR SELECT TO public
  USING ((status = 'terbit'::text));
DROP POLICY IF EXISTS "berita_public_read_safety" ON public.berita;
CREATE POLICY "berita_public_read_safety" ON public.berita AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING ((status = ANY (ARRAY['terbit'::text, 'published'::text])));
DROP POLICY IF EXISTS "berita_read" ON public.berita;
CREATE POLICY "berita_read" ON public.berita AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING (((status = 'published'::text) OR (penulis_id = auth.uid()) OR is_elevated_view(auth.uid())));
DROP POLICY IF EXISTS "auth_read_branding" ON public.branding;
CREATE POLICY "auth_read_branding" ON public.branding AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "admins manage bukti" ON public.bukti_dokumen;
CREATE POLICY "admins manage bukti" ON public.bukti_dokumen AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (opd_id = get_user_opd(auth.uid())))))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (opd_id = get_user_opd(auth.uid())))));
DROP POLICY IF EXISTS "bukti_dokumen insert own" ON public.bukti_dokumen;
CREATE POLICY "bukti_dokumen insert own" ON public.bukti_dokumen AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((created_by = auth.uid()));
DROP POLICY IF EXISTS "bukti_dokumen update by owner or admin" ON public.bukti_dokumen;
CREATE POLICY "bukti_dokumen update by owner or admin" ON public.bukti_dokumen AS PERMISSIVE FOR UPDATE TO authenticated
  USING (((created_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (opd_id = get_user_opd(auth.uid())))))
  WITH CHECK (((created_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (opd_id = get_user_opd(auth.uid())))));
DROP POLICY IF EXISTS "creators and admins read bukti" ON public.bukti_dokumen;
CREATE POLICY "creators and admins read bukti" ON public.bukti_dokumen AS PERMISSIVE FOR SELECT TO authenticated
  USING (((created_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (opd_id = get_user_opd(auth.uid())))));
DROP POLICY IF EXISTS "bukti_nomor_seq read auth" ON public.bukti_nomor_seq;
CREATE POLICY "bukti_nomor_seq read auth" ON public.bukti_nomor_seq AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "bukti_nomor_seq write admin" ON public.bukti_nomor_seq;
CREATE POLICY "bukti_nomor_seq write admin" ON public.bukti_nomor_seq AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "service manages bukti sequence" ON public.bukti_nomor_seq;
CREATE POLICY "service manages bukti sequence" ON public.bukti_nomor_seq AS PERMISSIVE FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "service_only_seq" ON public.bukti_nomor_sequence;
CREATE POLICY "service_only_seq" ON public.bukti_nomor_sequence AS PERMISSIVE FOR ALL TO authenticated
  USING (false)
  WITH CHECK (false);
DROP POLICY IF EXISTS "auth_read_bukti_tpl" ON public.bukti_template_override;
CREATE POLICY "auth_read_bukti_tpl" ON public.bukti_template_override AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "bukti_template_override read auth" ON public.bukti_template_override;
CREATE POLICY "bukti_template_override read auth" ON public.bukti_template_override AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "template admins manage overrides" ON public.bukti_template_override;
CREATE POLICY "template admins manage overrides" ON public.bukti_template_override AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (opd_id = get_user_opd(auth.uid())))))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (opd_id = get_user_opd(auth.uid())))));
DROP POLICY IF EXISTS "compliance_checklist_select" ON public.compliance_checklist;
CREATE POLICY "compliance_checklist_select" ON public.compliance_checklist AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "consent_log_own" ON public.consent_log;
CREATE POLICY "consent_log_own" ON public.consent_log AS PERMISSIVE FOR ALL TO authenticated
  USING ((user_id = auth.uid()))
  WITH CHECK ((user_id = auth.uid()));
DROP POLICY IF EXISTS "data_terpadu_item_public_read_safety" ON public.data_terpadu_item;
CREATE POLICY "data_terpadu_item_public_read_safety" ON public.data_terpadu_item AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING ((aktif = true));
DROP POLICY IF EXISTS "dataset_submission_own" ON public.dataset_submission;
CREATE POLICY "dataset_submission_own" ON public.dataset_submission AS PERMISSIVE FOR ALL TO authenticated
  USING ((user_id = auth.uid()))
  WITH CHECK ((user_id = auth.uid()));
DROP POLICY IF EXISTS "dataset_template_select" ON public.dataset_template;
CREATE POLICY "dataset_template_select" ON public.dataset_template AS PERMISSIVE FOR SELECT TO authenticated
  USING (((aktif = true) OR (opd_id = get_user_opd(auth.uid()))));
DROP POLICY IF EXISTS "Desa publik baca" ON public.desa;
CREATE POLICY "Desa publik baca" ON public.desa AS PERMISSIVE FOR SELECT TO public
  USING (true);
DROP POLICY IF EXISTS "auth_read_desa" ON public.desa;
CREATE POLICY "auth_read_desa" ON public.desa AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "desa_pread" ON public.desa;
CREATE POLICY "desa_pread" ON public.desa AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING (true);
DROP POLICY IF EXISTS "ds_delete_admin" ON public.digital_signatures;
CREATE POLICY "ds_delete_admin" ON public.digital_signatures AS PERMISSIVE FOR DELETE TO authenticated
  USING (has_role(auth.uid(), 'super_admin'::app_role));
DROP POLICY IF EXISTS "ds_insert_own" ON public.digital_signatures;
CREATE POLICY "ds_insert_own" ON public.digital_signatures AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((user_id = auth.uid()));
DROP POLICY IF EXISTS "ds_select_own" ON public.digital_signatures;
CREATE POLICY "ds_select_own" ON public.digital_signatures AS PERMISSIVE FOR SELECT TO authenticated
  USING (((user_id = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "ds_update_own" ON public.digital_signatures;
CREATE POLICY "ds_update_own" ON public.digital_signatures AS PERMISSIVE FOR UPDATE TO authenticated
  USING (((user_id = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role)))
  WITH CHECK (((user_id = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role)));
DROP POLICY IF EXISTS "da_insert" ON public.document_audit;
CREATE POLICY "da_insert" ON public.document_audit AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (((actor = auth.uid()) OR (actor IS NULL)));
DROP POLICY IF EXISTS "da_select" ON public.document_audit;
CREATE POLICY "da_select" ON public.document_audit AS PERMISSIVE FOR SELECT TO authenticated
  USING (((actor = auth.uid()) OR (EXISTS ( SELECT 1
   FROM documents d
  WHERE ((d.id = document_audit.document_id) AND ((d.created_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (d.opd_id = get_user_opd(auth.uid())))))))));
DROP POLICY IF EXISTS "admin_write_document_history" ON public.document_history;
CREATE POLICY "admin_write_document_history" ON public.document_history AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "document_history admin read" ON public.document_history;
CREATE POLICY "document_history admin read" ON public.document_history AS PERMISSIVE FOR SELECT TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role)));
DROP POLICY IF EXISTS "admin_write_document_numbering_rules" ON public.document_numbering_rules;
CREATE POLICY "admin_write_document_numbering_rules" ON public.document_numbering_rules AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "auth_read_document_numbering_rules" ON public.document_numbering_rules;
CREATE POLICY "auth_read_document_numbering_rules" ON public.document_numbering_rules AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "admin_write_document_numbering_sequences" ON public.document_numbering_sequences;
CREATE POLICY "admin_write_document_numbering_sequences" ON public.document_numbering_sequences AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "auth_read_document_numbering_sequences" ON public.document_numbering_sequences;
CREATE POLICY "auth_read_document_numbering_sequences" ON public.document_numbering_sequences AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "admin_write_document_template_versions" ON public.document_template_versions;
CREATE POLICY "admin_write_document_template_versions" ON public.document_template_versions AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "auth_read_document_template_versions" ON public.document_template_versions;
CREATE POLICY "auth_read_document_template_versions" ON public.document_template_versions AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "admin_write_document_templates" ON public.document_templates;
CREATE POLICY "admin_write_document_templates" ON public.document_templates AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "auth_read_document_templates" ON public.document_templates;
CREATE POLICY "auth_read_document_templates" ON public.document_templates AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "documents_delete_admin" ON public.documents;
CREATE POLICY "documents_delete_admin" ON public.documents AS PERMISSIVE FOR DELETE TO authenticated
  USING (has_role(auth.uid(), 'super_admin'::app_role));
DROP POLICY IF EXISTS "documents_insert" ON public.documents;
CREATE POLICY "documents_insert" ON public.documents AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((created_by = auth.uid()));
DROP POLICY IF EXISTS "documents_select" ON public.documents;
CREATE POLICY "documents_select" ON public.documents AS PERMISSIVE FOR SELECT TO authenticated
  USING (((created_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (opd_id = get_user_opd(auth.uid())))));
DROP POLICY IF EXISTS "documents_update" ON public.documents;
CREATE POLICY "documents_update" ON public.documents AS PERMISSIVE FOR UPDATE TO authenticated
  USING (((created_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role)))
  WITH CHECK (((created_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role)));
DROP POLICY IF EXISTS "dokumen_verifikasi admin manage" ON public.dokumen_verifikasi;
CREATE POLICY "dokumen_verifikasi admin manage" ON public.dokumen_verifikasi AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "dokumen_verifikasi insert own" ON public.dokumen_verifikasi;
CREATE POLICY "dokumen_verifikasi insert own" ON public.dokumen_verifikasi AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (((created_by = auth.uid()) OR (diterbitkan_oleh = auth.uid())));
DROP POLICY IF EXISTS "dokumen_verifikasi select scoped" ON public.dokumen_verifikasi;
CREATE POLICY "dokumen_verifikasi select scoped" ON public.dokumen_verifikasi AS PERMISSIVE FOR SELECT TO authenticated
  USING (((created_by = auth.uid()) OR (diterbitkan_oleh = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (EXISTS ( SELECT 1
   FROM permohonan p
  WHERE ((p.id = dokumen_verifikasi.permohonan_id) AND ((p.pemohon_id = auth.uid()) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (p.opd_id = get_user_opd(auth.uid())))))))));
DROP POLICY IF EXISTS "auth_read_feature_flags" ON public.feature_flags;
CREATE POLICY "auth_read_feature_flags" ON public.feature_flags AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "feature_flags read all" ON public.feature_flags;
CREATE POLICY "feature_flags read all" ON public.feature_flags AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING (true);
DROP POLICY IF EXISTS "form_assignments_own" ON public.form_assignments;
CREATE POLICY "form_assignments_own" ON public.form_assignments AS PERMISSIVE FOR SELECT TO authenticated
  USING (((user_id = auth.uid()) OR (opd_id = get_user_opd(auth.uid()))));
DROP POLICY IF EXISTS "admin_write_form_audit_logs" ON public.form_audit_logs;
CREATE POLICY "admin_write_form_audit_logs" ON public.form_audit_logs AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "fal_insert" ON public.form_audit_logs;
CREATE POLICY "fal_insert" ON public.form_audit_logs AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((auth.uid() IS NOT NULL));
DROP POLICY IF EXISTS "form_audit_logs admin read" ON public.form_audit_logs;
CREATE POLICY "form_audit_logs admin read" ON public.form_audit_logs AS PERMISSIVE FOR SELECT TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role)));
DROP POLICY IF EXISTS "auth_read_form_fields" ON public.form_fields;
CREATE POLICY "auth_read_form_fields" ON public.form_fields AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "form_fields_select" ON public.form_fields;
CREATE POLICY "form_fields_select" ON public.form_fields AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "form_submission_comment_insert" ON public.form_submission_comment;
CREATE POLICY "form_submission_comment_insert" ON public.form_submission_comment AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((oleh = auth.uid()));
DROP POLICY IF EXISTS "form_submissions_own" ON public.form_submissions;
CREATE POLICY "form_submissions_own" ON public.form_submissions AS PERMISSIVE FOR ALL TO authenticated
  USING ((user_id = auth.uid()))
  WITH CHECK ((user_id = auth.uid()));
DROP POLICY IF EXISTS "admin_write_form_templates" ON public.form_templates;
CREATE POLICY "admin_write_form_templates" ON public.form_templates AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "auth_read_form_templates" ON public.form_templates;
CREATE POLICY "auth_read_form_templates" ON public.form_templates AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "admin_write_form_versions" ON public.form_versions;
CREATE POLICY "admin_write_form_versions" ON public.form_versions AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "auth_read_form_versions" ON public.form_versions;
CREATE POLICY "auth_read_form_versions" ON public.form_versions AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "admin_write_form_wizard_drafts" ON public.form_wizard_drafts;
CREATE POLICY "admin_write_form_wizard_drafts" ON public.form_wizard_drafts AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "auth_read_form_wizard_drafts" ON public.form_wizard_drafts;
CREATE POLICY "auth_read_form_wizard_drafts" ON public.form_wizard_drafts AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "wizard_drafts_owner_delete" ON public.form_wizard_drafts;
CREATE POLICY "wizard_drafts_owner_delete" ON public.form_wizard_drafts AS PERMISSIVE FOR DELETE TO authenticated
  USING ((auth.uid() = user_id));
DROP POLICY IF EXISTS "wizard_drafts_owner_insert" ON public.form_wizard_drafts;
CREATE POLICY "wizard_drafts_owner_insert" ON public.form_wizard_drafts AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((auth.uid() = user_id));
DROP POLICY IF EXISTS "wizard_drafts_owner_select" ON public.form_wizard_drafts;
CREATE POLICY "wizard_drafts_owner_select" ON public.form_wizard_drafts AS PERMISSIVE FOR SELECT TO authenticated
  USING ((auth.uid() = user_id));
DROP POLICY IF EXISTS "wizard_drafts_owner_update" ON public.form_wizard_drafts;
CREATE POLICY "wizard_drafts_owner_update" ON public.form_wizard_drafts AS PERMISSIVE FOR UPDATE TO authenticated
  USING ((auth.uid() = user_id))
  WITH CHECK ((auth.uid() = user_id));
DROP POLICY IF EXISTS "auth_read_forms" ON public.forms;
CREATE POLICY "auth_read_forms" ON public.forms AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "forms_public_select" ON public.forms;
CREATE POLICY "forms_public_select" ON public.forms AS PERMISSIVE FOR SELECT TO public
  USING (((is_public = true) OR (auth.uid() IS NOT NULL)));
DROP POLICY IF EXISTS "admin_write_generated_documents" ON public.generated_documents;
CREATE POLICY "admin_write_generated_documents" ON public.generated_documents AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "generated_documents scoped read" ON public.generated_documents;
CREATE POLICY "generated_documents scoped read" ON public.generated_documents AS PERMISSIVE FOR SELECT TO authenticated
  USING (((generated_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role)));
DROP POLICY IF EXISTS "geofence_audit_own" ON public.geofence_audit;
CREATE POLICY "geofence_audit_own" ON public.geofence_audit AS PERMISSIVE FOR SELECT TO authenticated
  USING ((user_id = auth.uid()));
DROP POLICY IF EXISTS "auth_read_hari_libur" ON public.hari_libur;
CREATE POLICY "auth_read_hari_libur" ON public.hari_libur AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "hari_libur_select_all" ON public.hari_libur;
CREATE POLICY "hari_libur_select_all" ON public.hari_libur AS PERMISSIVE FOR SELECT TO public
  USING (true);
DROP POLICY IF EXISTS "ikm_responses_insert" ON public.ikm_responses;
CREATE POLICY "ikm_responses_insert" ON public.ikm_responses AS PERMISSIVE FOR INSERT TO anon, authenticated
  WITH CHECK (((survey_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM ikm_surveys s
  WHERE ((s.id = ikm_responses.survey_id) AND COALESCE(s.aktif, true))))));
DROP POLICY IF EXISTS "ikm_surveys_select" ON public.ikm_surveys;
CREATE POLICY "ikm_surveys_select" ON public.ikm_surveys AS PERMISSIVE FOR SELECT TO public
  USING (true);
DROP POLICY IF EXISTS "jabatan_permissions_manage_admin" ON public.jabatan_permissions;
CREATE POLICY "jabatan_permissions_manage_admin" ON public.jabatan_permissions AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "jabatan_permissions_select_auth" ON public.jabatan_permissions;
CREATE POLICY "jabatan_permissions_select_auth" ON public.jabatan_permissions AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "job_queue admin write" ON public.job_queue;
CREATE POLICY "job_queue admin write" ON public.job_queue AS PERMISSIVE FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'super_admin'::app_role))
  WITH CHECK (has_role(auth.uid(), 'super_admin'::app_role));
DROP POLICY IF EXISTS "jq_admin" ON public.job_queue;
CREATE POLICY "jq_admin" ON public.job_queue AS PERMISSIVE FOR ALL TO authenticated
  USING (is_admin_pemda(auth.uid()))
  WITH CHECK (is_admin_pemda(auth.uid()));
DROP POLICY IF EXISTS "kqr_read" ON public.kantor_qr;
CREATE POLICY "kqr_read" ON public.kantor_qr AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "Kategori publik baca" ON public.kategori_layanan;
CREATE POLICY "Kategori publik baca" ON public.kategori_layanan AS PERMISSIVE FOR SELECT TO public
  USING (true);
DROP POLICY IF EXISTS "kategori_layanan_pread" ON public.kategori_layanan;
CREATE POLICY "kategori_layanan_pread" ON public.kategori_layanan AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING (true);
DROP POLICY IF EXISTS "Publik kirim laporan" ON public.laporan_masyarakat;
CREATE POLICY "Publik kirim laporan" ON public.laporan_masyarakat AS PERMISSIVE FOR INSERT TO anon, authenticated
  WITH CHECK (((status IS NULL) OR (status = 'baru'::text)));
DROP POLICY IF EXISTS "laporan_masyarakat_insert" ON public.laporan_masyarakat;
CREATE POLICY "laporan_masyarakat_insert" ON public.laporan_masyarakat AS PERMISSIVE FOR INSERT TO anon, authenticated
  WITH CHECK (((nama IS NOT NULL) AND (length(btrim(nama)) > 0) AND (email IS NOT NULL) AND (length(btrim(email)) > 0) AND (uraian IS NOT NULL) AND (length(btrim(uraian)) > 0) AND (kategori IS NOT NULL)));
DROP POLICY IF EXISTS "pelapor_read_own" ON public.laporan_masyarakat;
CREATE POLICY "pelapor_read_own" ON public.laporan_masyarakat AS PERMISSIVE FOR SELECT TO authenticated
  USING ((pelapor_id = auth.uid()));
DROP POLICY IF EXISTS "seq_service_only" ON public.laporan_ticket_sequence;
CREATE POLICY "seq_service_only" ON public.laporan_ticket_sequence AS PERMISSIVE FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "Layanan aktif publik" ON public.layanan_publik;
CREATE POLICY "Layanan aktif publik" ON public.layanan_publik AS PERMISSIVE FOR SELECT TO public
  USING ((aktif = true));
DROP POLICY IF EXISTS "layanan_publik_pread" ON public.layanan_publik;
CREATE POLICY "layanan_publik_pread" ON public.layanan_publik AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING (true);
DROP POLICY IF EXISTS "layanan_publik_public_read_safety" ON public.layanan_publik;
CREATE POLICY "layanan_publik_public_read_safety" ON public.layanan_publik AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING ((aktif = true));
DROP POLICY IF EXISTS "auth_read_master_jabatan" ON public.master_jabatan;
CREATE POLICY "auth_read_master_jabatan" ON public.master_jabatan AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "master_jabatan_read" ON public.master_jabatan;
CREATE POLICY "master_jabatan_read" ON public.master_jabatan AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING (true);
DROP POLICY IF EXISTS "master_jabatan_read_public" ON public.master_jabatan;
CREATE POLICY "master_jabatan_read_public" ON public.master_jabatan AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING (true);
DROP POLICY IF EXISTS "master_jabatan_write" ON public.master_jabatan;
CREATE POLICY "master_jabatan_write" ON public.master_jabatan AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "auth_read_notification_templates" ON public.notification_templates;
CREATE POLICY "auth_read_notification_templates" ON public.notification_templates AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "notif_tpl_admin_all" ON public.notification_templates;
CREATE POLICY "notif_tpl_admin_all" ON public.notification_templates AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role)));
DROP POLICY IF EXISTS "notif_tpl_read_all_auth" ON public.notification_templates;
CREATE POLICY "notif_tpl_read_all_auth" ON public.notification_templates AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "notifications_self" ON public.notifications;
CREATE POLICY "notifications_self" ON public.notifications AS PERMISSIVE FOR ALL TO authenticated
  USING ((user_id = auth.uid()))
  WITH CHECK ((user_id = auth.uid()));
DROP POLICY IF EXISTS "OPD readable by all" ON public.opd;
CREATE POLICY "OPD readable by all" ON public.opd AS PERMISSIVE FOR SELECT TO public
  USING (true);
DROP POLICY IF EXISTS "authenticated can read opd" ON public.opd;
CREATE POLICY "authenticated can read opd" ON public.opd AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "opd_pread" ON public.opd;
CREATE POLICY "opd_pread" ON public.opd AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING (true);
DROP POLICY IF EXISTS "opd_public_read_safety" ON public.opd;
CREATE POLICY "opd_public_read_safety" ON public.opd AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING (true);
DROP POLICY IF EXISTS "overtime_requests select scoped" ON public.overtime_requests;
CREATE POLICY "overtime_requests select scoped" ON public.overtime_requests AS PERMISSIVE FOR SELECT TO authenticated
  USING (((user_id = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR has_role(auth.uid(), 'admin_bkpsdm'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (opd_id = get_user_opd(auth.uid())))));
DROP POLICY IF EXISTS "payroll_periods admin read" ON public.payroll_periods;
CREATE POLICY "payroll_periods admin read" ON public.payroll_periods AS PERMISSIVE FOR SELECT TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR has_role(auth.uid(), 'admin_bkpsdm'::app_role)));
DROP POLICY IF EXISTS "Pejabat publik baca" ON public.pejabat;
CREATE POLICY "Pejabat publik baca" ON public.pejabat AS PERMISSIVE FOR SELECT TO public
  USING ((aktif = true));
DROP POLICY IF EXISTS "authenticated read pejabat" ON public.pejabat;
CREATE POLICY "authenticated read pejabat" ON public.pejabat AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "pejabat_pread" ON public.pejabat;
CREATE POLICY "pejabat_pread" ON public.pejabat AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING (true);
DROP POLICY IF EXISTS "pengajuan_izin_own" ON public.pengajuan_izin;
CREATE POLICY "pengajuan_izin_own" ON public.pengajuan_izin AS PERMISSIVE FOR ALL TO authenticated
  USING ((user_id = auth.uid()))
  WITH CHECK ((user_id = auth.uid()));
DROP POLICY IF EXISTS "auth_read_permissions" ON public.permissions;
CREATE POLICY "auth_read_permissions" ON public.permissions AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "permissions_select" ON public.permissions;
CREATE POLICY "permissions_select" ON public.permissions AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "Warga buat permohonan" ON public.permohonan;
CREATE POLICY "Warga buat permohonan" ON public.permohonan AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((auth.uid() = pemohon_id));
DROP POLICY IF EXISTS "perm_insert" ON public.permohonan;
CREATE POLICY "perm_insert" ON public.permohonan AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((pemohon_id = auth.uid()));
DROP POLICY IF EXISTS "read permohonan own or admin" ON public.permohonan;
CREATE POLICY "read permohonan own or admin" ON public.permohonan AS PERMISSIVE FOR SELECT TO authenticated
  USING (((auth.uid() = pemohon_id) OR (auth.uid() = petugas_id) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR has_role(auth.uid(), 'pimpinan'::app_role) OR has_role(auth.uid(), 'asn'::app_role) OR ((has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_desa'::app_role)) AND (opd_id = get_user_opd(auth.uid())))));
DROP POLICY IF EXISTS "update permohonan admin" ON public.permohonan;
CREATE POLICY "update permohonan admin" ON public.permohonan AS PERMISSIVE FOR UPDATE TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR has_role(auth.uid(), 'pimpinan'::app_role) OR has_role(auth.uid(), 'asn'::app_role) OR ((has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_desa'::app_role)) AND (opd_id = get_user_opd(auth.uid())))));
DROP POLICY IF EXISTS "berkas delete owner or admin" ON public.permohonan_berkas;
CREATE POLICY "berkas delete owner or admin" ON public.permohonan_berkas AS PERMISSIVE FOR DELETE TO authenticated
  USING (((uploaded_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (EXISTS ( SELECT 1
   FROM permohonan p
  WHERE ((p.id = permohonan_berkas.permohonan_id) AND (p.opd_id = get_user_opd(auth.uid()))))))));
DROP POLICY IF EXISTS "berkas insert own file" ON public.permohonan_berkas;
CREATE POLICY "berkas insert own file" ON public.permohonan_berkas AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (((uploaded_by = auth.uid()) AND ((EXISTS ( SELECT 1
   FROM permohonan p
  WHERE ((p.id = permohonan_berkas.permohonan_id) AND (p.pemohon_id = auth.uid())))) OR has_role(auth.uid(), 'super_admin'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (EXISTS ( SELECT 1
   FROM permohonan p
  WHERE ((p.id = permohonan_berkas.permohonan_id) AND (p.opd_id = get_user_opd(auth.uid())))))))));
DROP POLICY IF EXISTS "berkas select owner or admin" ON public.permohonan_berkas;
CREATE POLICY "berkas select owner or admin" ON public.permohonan_berkas AS PERMISSIVE FOR SELECT TO authenticated
  USING (((uploaded_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR (EXISTS ( SELECT 1
   FROM permohonan p
  WHERE ((p.id = permohonan_berkas.permohonan_id) AND ((p.pemohon_id = auth.uid()) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (p.opd_id = get_user_opd(auth.uid())))))))));
DROP POLICY IF EXISTS "Rating login baca" ON public.permohonan_rating;
CREATE POLICY "Rating login baca" ON public.permohonan_rating AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "User insert rating sendiri" ON public.permohonan_rating;
CREATE POLICY "User insert rating sendiri" ON public.permohonan_rating AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((auth.uid() = user_id));
DROP POLICY IF EXISTS "User update rating sendiri" ON public.permohonan_rating;
CREATE POLICY "User update rating sendiri" ON public.permohonan_rating AS PERMISSIVE FOR UPDATE TO authenticated
  USING ((auth.uid() = user_id))
  WITH CHECK ((auth.uid() = user_id));
DROP POLICY IF EXISTS "permohonan_rating_public_read_safety" ON public.permohonan_rating;
CREATE POLICY "permohonan_rating_public_read_safety" ON public.permohonan_rating AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING (true);
DROP POLICY IF EXISTS "rating_ins" ON public.permohonan_rating;
CREATE POLICY "rating_ins" ON public.permohonan_rating AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((user_id = auth.uid()));
DROP POLICY IF EXISTS "rating_read" ON public.permohonan_rating;
CREATE POLICY "rating_read" ON public.permohonan_rating AS PERMISSIVE FOR SELECT TO anon, authenticated
  USING (true);
DROP POLICY IF EXISTS "permohonan_riwayat scoped read" ON public.permohonan_riwayat;
CREATE POLICY "permohonan_riwayat scoped read" ON public.permohonan_riwayat AS PERMISSIVE FOR SELECT TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (EXISTS ( SELECT 1
   FROM permohonan p
  WHERE ((p.id = permohonan_riwayat.permohonan_id) AND ((p.pemohon_id = auth.uid()) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (p.opd_id = get_user_opd(auth.uid())))))))));
DROP POLICY IF EXISTS "profile_admin_select" ON public.profiles;
CREATE POLICY "profile_admin_select" ON public.profiles AS PERMISSIVE FOR SELECT TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR has_role(auth.uid(), 'pimpinan'::app_role) OR has_role(auth.uid(), 'asn'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_desa'::app_role)));
DROP POLICY IF EXISTS "profile_self_insert" ON public.profiles;
CREATE POLICY "profile_self_insert" ON public.profiles AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((id = auth.uid()));
DROP POLICY IF EXISTS "profile_self_select" ON public.profiles;
CREATE POLICY "profile_self_select" ON public.profiles AS PERMISSIVE FOR SELECT TO authenticated
  USING ((id = auth.uid()));
DROP POLICY IF EXISTS "profile_self_update" ON public.profiles;
CREATE POLICY "profile_self_update" ON public.profiles AS PERMISSIVE FOR UPDATE TO authenticated
  USING ((id = auth.uid()))
  WITH CHECK ((id = auth.uid()));
DROP POLICY IF EXISTS "push subscriptions owner can delete" ON public.push_subscription;
CREATE POLICY "push subscriptions owner can delete" ON public.push_subscription AS PERMISSIVE FOR DELETE TO authenticated
  USING (((auth.uid() = user_id) OR has_role(auth.uid(), 'super_admin'::app_role)));
DROP POLICY IF EXISTS "push subscriptions owner can insert" ON public.push_subscription;
CREATE POLICY "push subscriptions owner can insert" ON public.push_subscription AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((auth.uid() = user_id));
DROP POLICY IF EXISTS "push subscriptions owner can read" ON public.push_subscription;
CREATE POLICY "push subscriptions owner can read" ON public.push_subscription AS PERMISSIVE FOR SELECT TO authenticated
  USING (((auth.uid() = user_id) OR has_role(auth.uid(), 'super_admin'::app_role)));
DROP POLICY IF EXISTS "push subscriptions owner can update" ON public.push_subscription;
CREATE POLICY "push subscriptions owner can update" ON public.push_subscription AS PERMISSIVE FOR UPDATE TO authenticated
  USING ((auth.uid() = user_id))
  WITH CHECK ((auth.uid() = user_id));
DROP POLICY IF EXISTS "Deny all rate_limit" ON public.rate_limit;
CREATE POLICY "Deny all rate_limit" ON public.rate_limit AS PERMISSIVE FOR ALL TO anon, authenticated
  USING (false)
  WITH CHECK (false);
DROP POLICY IF EXISTS "rate_limit_hits super read" ON public.rate_limit_hits;
CREATE POLICY "rate_limit_hits super read" ON public.rate_limit_hits AS PERMISSIVE FOR SELECT TO authenticated
  USING (has_role(auth.uid(), 'super_admin'::app_role));
DROP POLICY IF EXISTS "rbac_audit admin read" ON public.rbac_audit;
CREATE POLICY "rbac_audit admin read" ON public.rbac_audit AS PERMISSIVE FOR SELECT TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "retention_policies super read" ON public.retention_policies;
CREATE POLICY "retention_policies super read" ON public.retention_policies AS PERMISSIVE FOR SELECT TO authenticated
  USING (has_role(auth.uid(), 'super_admin'::app_role));
DROP POLICY IF EXISTS "retry_queue super read" ON public.retry_queue;
CREATE POLICY "retry_queue super read" ON public.retry_queue AS PERMISSIVE FOR SELECT TO authenticated
  USING (has_role(auth.uid(), 'super_admin'::app_role));
DROP POLICY IF EXISTS "role_permissions_manage_super" ON public.role_permissions;
CREATE POLICY "role_permissions_manage_super" ON public.role_permissions AS PERMISSIVE FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'super_admin'::app_role))
  WITH CHECK (has_role(auth.uid(), 'super_admin'::app_role));
DROP POLICY IF EXISTS "role_permissions_read_all" ON public.role_permissions;
CREATE POLICY "role_permissions_read_all" ON public.role_permissions AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "signature_delegations scoped read" ON public.signature_delegations;
CREATE POLICY "signature_delegations scoped read" ON public.signature_delegations AS PERMISSIVE FOR SELECT TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "admin_write_signature_events" ON public.signature_events;
CREATE POLICY "admin_write_signature_events" ON public.signature_events AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "sigevt insert auth" ON public.signature_events;
CREATE POLICY "sigevt insert auth" ON public.signature_events AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (true);
DROP POLICY IF EXISTS "sigevt select via req" ON public.signature_events;
CREATE POLICY "sigevt select via req" ON public.signature_events AS PERMISSIVE FOR SELECT TO authenticated
  USING ((EXISTS ( SELECT 1
   FROM signature_requests r
  WHERE ((r.id = signature_events.request_id) AND ((r.created_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (r.opd_id = get_user_opd(auth.uid()))))))));
DROP POLICY IF EXISTS "admin_write_signature_providers" ON public.signature_providers;
CREATE POLICY "admin_write_signature_providers" ON public.signature_providers AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "auth_read_signature_providers" ON public.signature_providers;
CREATE POLICY "auth_read_signature_providers" ON public.signature_providers AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "providers manage super" ON public.signature_providers;
CREATE POLICY "providers manage super" ON public.signature_providers AS PERMISSIVE FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'super_admin'::app_role))
  WITH CHECK (has_role(auth.uid(), 'super_admin'::app_role));
DROP POLICY IF EXISTS "providers select auth" ON public.signature_providers;
CREATE POLICY "providers select auth" ON public.signature_providers AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "admin_write_signature_request_signers" ON public.signature_request_signers;
CREATE POLICY "admin_write_signature_request_signers" ON public.signature_request_signers AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "sigsigner select via req" ON public.signature_request_signers;
CREATE POLICY "sigsigner select via req" ON public.signature_request_signers AS PERMISSIVE FOR SELECT TO authenticated
  USING ((EXISTS ( SELECT 1
   FROM signature_requests r
  WHERE ((r.id = signature_request_signers.request_id) AND ((r.created_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (r.opd_id = get_user_opd(auth.uid()))) OR (signature_request_signers.user_id = auth.uid()))))));
DROP POLICY IF EXISTS "admin_write_signature_requests" ON public.signature_requests;
CREATE POLICY "admin_write_signature_requests" ON public.signature_requests AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "sigreq manage super" ON public.signature_requests;
CREATE POLICY "sigreq manage super" ON public.signature_requests AS PERMISSIVE FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'super_admin'::app_role))
  WITH CHECK (has_role(auth.uid(), 'super_admin'::app_role));
DROP POLICY IF EXISTS "sigreq select scoped" ON public.signature_requests;
CREATE POLICY "sigreq select scoped" ON public.signature_requests AS PERMISSIVE FOR SELECT TO authenticated
  USING (((created_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (opd_id = get_user_opd(auth.uid())))));
DROP POLICY IF EXISTS "sd_delete_admin" ON public.signed_documents;
CREATE POLICY "sd_delete_admin" ON public.signed_documents AS PERMISSIVE FOR DELETE TO authenticated
  USING (has_role(auth.uid(), 'super_admin'::app_role));
DROP POLICY IF EXISTS "sd_insert" ON public.signed_documents;
CREATE POLICY "sd_insert" ON public.signed_documents AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((signed_by = auth.uid()));
DROP POLICY IF EXISTS "sd_select" ON public.signed_documents;
CREATE POLICY "sd_select" ON public.signed_documents AS PERMISSIVE FOR SELECT TO authenticated
  USING (((signed_by = auth.uid()) OR (EXISTS ( SELECT 1
   FROM documents d
  WHERE ((d.id = signed_documents.document_id) AND ((d.created_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (has_role(auth.uid(), 'admin_opd'::app_role) AND (d.opd_id = get_user_opd(auth.uid())))))))));
DROP POLICY IF EXISTS "sd_update_admin" ON public.signed_documents;
CREATE POLICY "sd_update_admin" ON public.signed_documents AS PERMISSIVE FOR UPDATE TO authenticated
  USING (((signed_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role)))
  WITH CHECK (((signed_by = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role)));
DROP POLICY IF EXISTS "sc_delete_admin" ON public.signing_certificates;
CREATE POLICY "sc_delete_admin" ON public.signing_certificates AS PERMISSIVE FOR DELETE TO authenticated
  USING (has_role(auth.uid(), 'super_admin'::app_role));
DROP POLICY IF EXISTS "sc_insert_admin" ON public.signing_certificates;
CREATE POLICY "sc_insert_admin" ON public.signing_certificates AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "sc_select" ON public.signing_certificates;
CREATE POLICY "sc_select" ON public.signing_certificates AS PERMISSIVE FOR SELECT TO authenticated
  USING (((user_id = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "sc_update_admin" ON public.signing_certificates;
CREATE POLICY "sc_update_admin" ON public.signing_certificates AS PERMISSIVE FOR UPDATE TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "admin_write_submission_assignments" ON public.submission_assignments;
CREATE POLICY "admin_write_submission_assignments" ON public.submission_assignments AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "admin_write_submission_delegations" ON public.submission_delegations;
CREATE POLICY "admin_write_submission_delegations" ON public.submission_delegations AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "select_disposition_participants" ON public.submission_dispositions;
CREATE POLICY "select_disposition_participants" ON public.submission_dispositions AS PERMISSIVE FOR SELECT TO authenticated
  USING (((from_user = auth.uid()) OR (to_user = auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR (EXISTS ( SELECT 1
   FROM permohonan p
  WHERE ((p.id = submission_dispositions.permohonan_id) AND (p.opd_id = get_user_opd(auth.uid())))))));
DROP POLICY IF EXISTS "admin_write_submission_escalations" ON public.submission_escalations;
CREATE POLICY "admin_write_submission_escalations" ON public.submission_escalations AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "admin_write_submission_sequences" ON public.submission_sequences;
CREATE POLICY "admin_write_submission_sequences" ON public.submission_sequences AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "submission_sla_events admin read" ON public.submission_sla_events;
CREATE POLICY "submission_sla_events admin read" ON public.submission_sla_events AS PERMISSIVE FOR SELECT TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role)));
DROP POLICY IF EXISTS "admin_write_submission_tasks" ON public.submission_tasks;
CREATE POLICY "admin_write_submission_tasks" ON public.submission_tasks AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "admin_write_submission_values" ON public.submission_values;
CREATE POLICY "admin_write_submission_values" ON public.submission_values AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "admin_write_submission_versions" ON public.submission_versions;
CREATE POLICY "admin_write_submission_versions" ON public.submission_versions AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "uat_results super read" ON public.uat_results;
CREATE POLICY "uat_results super read" ON public.uat_results AS PERMISSIVE FOR SELECT TO authenticated
  USING (has_role(auth.uid(), 'super_admin'::app_role));
DROP POLICY IF EXISTS "auth_read_uat_scenarios" ON public.uat_scenarios;
CREATE POLICY "auth_read_uat_scenarios" ON public.uat_scenarios AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "user_permissions_own_select" ON public.user_permissions;
CREATE POLICY "user_permissions_own_select" ON public.user_permissions AS PERMISSIVE FOR SELECT TO authenticated
  USING ((user_id = auth.uid()));
DROP POLICY IF EXISTS "authenticated read roles" ON public.user_roles;
CREATE POLICY "authenticated read roles" ON public.user_roles AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "ur_read" ON public.user_roles;
CREATE POLICY "ur_read" ON public.user_roles AS PERMISSIVE FOR SELECT TO authenticated
  USING (((user_id = auth.uid()) OR is_elevated_view(auth.uid())));
DROP POLICY IF EXISTS "user_roles_self_select" ON public.user_roles;
CREATE POLICY "user_roles_self_select" ON public.user_roles AS PERMISSIVE FOR SELECT TO authenticated
  USING ((user_id = auth.uid()));
DROP POLICY IF EXISTS "auth_read_verification_logs" ON public.verification_logs;
CREATE POLICY "auth_read_verification_logs" ON public.verification_logs AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "warga insert token sendiri" ON public.verification_token;
CREATE POLICY "warga insert token sendiri" ON public.verification_token AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((auth.uid() = user_id));
DROP POLICY IF EXISTS "auth_read_work_schedule" ON public.work_schedule;
CREATE POLICY "auth_read_work_schedule" ON public.work_schedule AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "work_schedule_select" ON public.work_schedule;
CREATE POLICY "work_schedule_select" ON public.work_schedule AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "auth_read_work_schedule_assignment" ON public.work_schedule_assignment;
CREATE POLICY "auth_read_work_schedule_assignment" ON public.work_schedule_assignment AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "admin_write_workflow_audit_logs" ON public.workflow_audit_logs;
CREATE POLICY "admin_write_workflow_audit_logs" ON public.workflow_audit_logs AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "auth_read_workflow_audit_logs" ON public.workflow_audit_logs;
CREATE POLICY "auth_read_workflow_audit_logs" ON public.workflow_audit_logs AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "wal_insert" ON public.workflow_audit_logs;
CREATE POLICY "wal_insert" ON public.workflow_audit_logs AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK ((auth.uid() IS NOT NULL));
DROP POLICY IF EXISTS "admin_write_workflow_definitions" ON public.workflow_definitions;
CREATE POLICY "admin_write_workflow_definitions" ON public.workflow_definitions AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "auth_read_workflow_definitions" ON public.workflow_definitions;
CREATE POLICY "auth_read_workflow_definitions" ON public.workflow_definitions AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "admin_write_workflow_edges" ON public.workflow_edges;
CREATE POLICY "admin_write_workflow_edges" ON public.workflow_edges AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "auth_read_workflow_edges" ON public.workflow_edges;
CREATE POLICY "auth_read_workflow_edges" ON public.workflow_edges AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "we_all" ON public.workflow_edges;
CREATE POLICY "we_all" ON public.workflow_edges AS PERMISSIVE FOR ALL TO authenticated
  USING ((EXISTS ( SELECT 1
   FROM workflow_versions wv
  WHERE (wv.id = workflow_edges.workflow_version_id))))
  WITH CHECK ((EXISTS ( SELECT 1
   FROM workflow_versions wv
  WHERE (wv.id = workflow_edges.workflow_version_id))));
DROP POLICY IF EXISTS "auth_read_workflow_instances" ON public.workflow_instances;
CREATE POLICY "auth_read_workflow_instances" ON public.workflow_instances AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "admin_write_workflow_nodes" ON public.workflow_nodes;
CREATE POLICY "admin_write_workflow_nodes" ON public.workflow_nodes AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "auth_read_workflow_nodes" ON public.workflow_nodes;
CREATE POLICY "auth_read_workflow_nodes" ON public.workflow_nodes AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "wn_all" ON public.workflow_nodes;
CREATE POLICY "wn_all" ON public.workflow_nodes AS PERMISSIVE FOR ALL TO authenticated
  USING ((EXISTS ( SELECT 1
   FROM workflow_versions wv
  WHERE (wv.id = workflow_nodes.workflow_version_id))))
  WITH CHECK ((EXISTS ( SELECT 1
   FROM workflow_versions wv
  WHERE (wv.id = workflow_nodes.workflow_version_id))));
DROP POLICY IF EXISTS "admin_write_workflow_templates" ON public.workflow_templates;
CREATE POLICY "admin_write_workflow_templates" ON public.workflow_templates AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "auth_read_workflow_templates" ON public.workflow_templates;
CREATE POLICY "auth_read_workflow_templates" ON public.workflow_templates AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "admin_write_workflow_versions" ON public.workflow_versions;
CREATE POLICY "admin_write_workflow_versions" ON public.workflow_versions AS PERMISSIVE FOR ALL TO authenticated
  USING ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'super_admin'::app_role) OR has_role(auth.uid(), 'admin_opd'::app_role) OR has_role(auth.uid(), 'admin_pemda'::app_role)));
DROP POLICY IF EXISTS "auth_read_workflow_versions" ON public.workflow_versions;
CREATE POLICY "auth_read_workflow_versions" ON public.workflow_versions AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS "auth_read_workflows" ON public.workflows;
CREATE POLICY "auth_read_workflows" ON public.workflows AS PERMISSIVE FOR SELECT TO authenticated
  USING (true);

-- ---------- GRANTS ----------
GRANT INSERT, SELECT ON public.absensi_asn TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.absensi_asn TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.absensi_asn TO service_role;
GRANT SELECT ON public.announcement_targets TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.announcement_targets TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.announcement_targets TO service_role;
GRANT SELECT ON public.announcements TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.announcements TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.announcements TO service_role;
GRANT INSERT, SELECT ON public.app_setting TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.app_setting TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.app_setting TO service_role;
GRANT INSERT, SELECT ON public.aset TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.aset TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.aset TO service_role;
GRANT INSERT, SELECT ON public.aset_bast TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.aset_bast TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.aset_bast TO service_role;
GRANT INSERT, SELECT ON public.aset_bast_items TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.aset_bast_items TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.aset_bast_items TO service_role;
GRANT INSERT, SELECT ON public.aset_mutasi TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.aset_mutasi TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.aset_mutasi TO service_role;
GRANT INSERT, SELECT ON public.aset_nilai_buku TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.aset_nilai_buku TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.aset_nilai_buku TO service_role;
GRANT INSERT, SELECT ON public.aset_opname TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.aset_opname TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.aset_opname TO service_role;
GRANT INSERT, SELECT ON public.aset_opname_items TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.aset_opname_items TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.aset_opname_items TO service_role;
GRANT INSERT, SELECT ON public.aset_pemeliharaan TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.aset_pemeliharaan TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.aset_pemeliharaan TO service_role;
GRANT INSERT, SELECT ON public.aset_penyusutan_history TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.aset_penyusutan_history TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.aset_penyusutan_history TO service_role;
GRANT INSERT, SELECT ON public.aset_riwayat TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.aset_riwayat TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.aset_riwayat TO service_role;
GRANT INSERT, SELECT ON public.aset_verification_campaign TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.aset_verification_campaign TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.aset_verification_campaign TO service_role;
GRANT INSERT, SELECT ON public.aset_verification_item TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.aset_verification_item TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.aset_verification_item TO service_role;
GRANT INSERT, SELECT ON public.attendance_shift_assignment TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.attendance_shift_assignment TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.attendance_shift_assignment TO service_role;
GRANT INSERT, SELECT ON public.attendance_shifts TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.attendance_shifts TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.attendance_shifts TO service_role;
GRANT INSERT, SELECT ON public.audit_log TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.audit_log TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.audit_log TO service_role;
GRANT INSERT, SELECT ON public.backup_snapshot TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.backup_snapshot TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.backup_snapshot TO service_role;
GRANT INSERT, SELECT ON public.berita TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.berita TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.berita TO service_role;
GRANT INSERT, SELECT ON public.branding TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.branding TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.branding TO service_role;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.bukti_dokumen TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.bukti_dokumen TO service_role;
GRANT INSERT, SELECT ON public.bukti_nomor_seq TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.bukti_nomor_seq TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.bukti_nomor_seq TO service_role;
GRANT INSERT, SELECT ON public.bukti_nomor_sequence TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.bukti_nomor_sequence TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.bukti_nomor_sequence TO service_role;
GRANT INSERT, SELECT ON public.bukti_template_override TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.bukti_template_override TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.bukti_template_override TO service_role;
GRANT INSERT, SELECT ON public.compliance_checklist TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.compliance_checklist TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.compliance_checklist TO service_role;
GRANT INSERT, SELECT ON public.consent_log TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.consent_log TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.consent_log TO service_role;
GRANT INSERT, SELECT ON public.cron_history TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.cron_history TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.cron_history TO service_role;
GRANT INSERT, SELECT ON public.data_terpadu_item TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.data_terpadu_item TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.data_terpadu_item TO service_role;
GRANT INSERT, SELECT ON public.dataset_submission TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.dataset_submission TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.dataset_submission TO service_role;
GRANT INSERT, SELECT ON public.dataset_submission_review TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.dataset_submission_review TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.dataset_submission_review TO service_role;
GRANT INSERT, SELECT ON public.dataset_template TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.dataset_template TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.dataset_template TO service_role;
GRANT INSERT, SELECT ON public.dead_letter_jobs TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.dead_letter_jobs TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.dead_letter_jobs TO service_role;
GRANT INSERT, SELECT ON public.desa TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.desa TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.desa TO service_role;
GRANT SELECT ON public.digital_signatures TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.digital_signatures TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.digital_signatures TO service_role;
GRANT SELECT ON public.document_audit TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.document_audit TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.document_audit TO service_role;
GRANT SELECT ON public.document_history TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.document_history TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.document_history TO service_role;
GRANT SELECT ON public.document_numbering_rules TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.document_numbering_rules TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.document_numbering_rules TO service_role;
GRANT SELECT ON public.document_numbering_sequences TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.document_numbering_sequences TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.document_numbering_sequences TO service_role;
GRANT SELECT ON public.document_template_versions TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.document_template_versions TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.document_template_versions TO service_role;
GRANT INSERT, SELECT ON public.document_templates TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.document_templates TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.document_templates TO service_role;
GRANT SELECT ON public.documents TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.documents TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.documents TO service_role;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.dokumen_verifikasi TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.dokumen_verifikasi TO service_role;
GRANT INSERT, SELECT ON public.escalation_config TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.escalation_config TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.escalation_config TO service_role;
GRANT INSERT, SELECT ON public.feature_flags TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.feature_flags TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.feature_flags TO service_role;
GRANT INSERT, SELECT ON public.form_assignments TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.form_assignments TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.form_assignments TO service_role;
GRANT INSERT, SELECT ON public.form_audit_logs TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.form_audit_logs TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.form_audit_logs TO service_role;
GRANT INSERT, SELECT ON public.form_fields TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.form_fields TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.form_fields TO service_role;
GRANT INSERT, SELECT ON public.form_submission_comment TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.form_submission_comment TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.form_submission_comment TO service_role;
GRANT INSERT, SELECT ON public.form_submission_files TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.form_submission_files TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.form_submission_files TO service_role;
GRANT INSERT, SELECT ON public.form_submission_versions TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.form_submission_versions TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.form_submission_versions TO service_role;
GRANT INSERT, SELECT ON public.form_submissions TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.form_submissions TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.form_submissions TO service_role;
GRANT INSERT, SELECT ON public.form_targets TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.form_targets TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.form_targets TO service_role;
GRANT INSERT, SELECT ON public.form_templates TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.form_templates TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.form_templates TO service_role;
GRANT INSERT, SELECT ON public.form_versions TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.form_versions TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.form_versions TO service_role;
GRANT INSERT, SELECT ON public.form_wizard_drafts TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.form_wizard_drafts TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.form_wizard_drafts TO service_role;
GRANT INSERT, SELECT ON public.forms TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.forms TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.forms TO service_role;
GRANT SELECT ON public.generated_documents TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.generated_documents TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.generated_documents TO service_role;
GRANT INSERT, SELECT ON public.geofence_audit TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.geofence_audit TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.geofence_audit TO service_role;
GRANT INSERT, SELECT ON public.hari_libur TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.hari_libur TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.hari_libur TO service_role;
GRANT INSERT, SELECT ON public.ikm_responses TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.ikm_responses TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.ikm_responses TO service_role;
GRANT INSERT, SELECT ON public.ikm_surveys TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.ikm_surveys TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.ikm_surveys TO service_role;
GRANT SELECT ON public.jabatan_permissions TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.jabatan_permissions TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.jabatan_permissions TO service_role;
GRANT INSERT, SELECT ON public.job_queue TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.job_queue TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.job_queue TO service_role;
GRANT INSERT, SELECT ON public.kantor_qr TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.kantor_qr TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.kantor_qr TO service_role;
GRANT INSERT, SELECT ON public.kategori_layanan TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.kategori_layanan TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.kategori_layanan TO service_role;
GRANT INSERT, SELECT ON public.laporan_masyarakat TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.laporan_masyarakat TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.laporan_masyarakat TO service_role;
GRANT INSERT, SELECT ON public.laporan_ticket_sequence TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.laporan_ticket_sequence TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.laporan_ticket_sequence TO service_role;
GRANT INSERT, SELECT ON public.layanan_publik TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.layanan_publik TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.layanan_publik TO service_role;
GRANT INSERT, SELECT ON public.leave_balances TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.leave_balances TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.leave_balances TO service_role;
GRANT INSERT, SELECT ON public.lokasi_gedung TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.lokasi_gedung TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.lokasi_gedung TO service_role;
GRANT INSERT, SELECT ON public.lokasi_lantai TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.lokasi_lantai TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.lokasi_lantai TO service_role;
GRANT INSERT, SELECT ON public.lokasi_ruangan TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.lokasi_ruangan TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.lokasi_ruangan TO service_role;
GRANT INSERT, SELECT ON public.master_jabatan TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.master_jabatan TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.master_jabatan TO service_role;
GRANT INSERT, SELECT ON public.nomor_surat_issued TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.nomor_surat_issued TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.nomor_surat_issued TO service_role;
GRANT INSERT, SELECT ON public.nomor_surat_sequence TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.nomor_surat_sequence TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.nomor_surat_sequence TO service_role;
GRANT INSERT, SELECT ON public.notification_templates TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.notification_templates TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.notification_templates TO service_role;
GRANT INSERT, SELECT ON public.notifications TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.notifications TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.notifications TO service_role;
GRANT INSERT, SELECT ON public.opd TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.opd TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.opd TO service_role;
GRANT INSERT, SELECT ON public.overtime_requests TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.overtime_requests TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.overtime_requests TO service_role;
GRANT INSERT, SELECT ON public.payroll_periods TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.payroll_periods TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.payroll_periods TO service_role;
GRANT INSERT, SELECT ON public.pejabat TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.pejabat TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.pejabat TO service_role;
GRANT INSERT, SELECT ON public.pengajuan_izin TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.pengajuan_izin TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.pengajuan_izin TO service_role;
GRANT INSERT, SELECT ON public.permissions TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.permissions TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.permissions TO service_role;
GRANT INSERT, SELECT ON public.permohonan TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.permohonan TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.permohonan TO service_role;
GRANT INSERT, SELECT ON public.permohonan_berkas TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.permohonan_berkas TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.permohonan_berkas TO service_role;
GRANT INSERT, SELECT ON public.permohonan_rating TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.permohonan_rating TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.permohonan_rating TO service_role;
GRANT INSERT, SELECT ON public.permohonan_riwayat TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.permohonan_riwayat TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.permohonan_riwayat TO service_role;
GRANT INSERT, SELECT ON public.profiles TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.profiles TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.profiles TO postgres;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.profiles TO service_role;
GRANT INSERT, SELECT ON public.push_subscription TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.push_subscription TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.push_subscription TO service_role;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.push_test_sink TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.push_test_sink TO service_role;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.push_test_sub TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.push_test_sub TO service_role;
GRANT INSERT, SELECT ON public.rate_limit TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.rate_limit TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.rate_limit TO service_role;
GRANT SELECT ON public.rate_limit_bucket TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.rate_limit_bucket TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.rate_limit_bucket TO service_role;
GRANT INSERT, SELECT ON public.rate_limit_hits TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.rate_limit_hits TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.rate_limit_hits TO service_role;
GRANT INSERT, SELECT ON public.rbac_audit TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.rbac_audit TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.rbac_audit TO service_role;
GRANT INSERT, SELECT ON public.retention_policies TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.retention_policies TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.retention_policies TO service_role;
GRANT INSERT, SELECT ON public.retry_queue TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.retry_queue TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.retry_queue TO service_role;
GRANT SELECT ON public.role_permissions TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.role_permissions TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.role_permissions TO service_role;
GRANT SELECT ON public.signature_delegations TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.signature_delegations TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.signature_delegations TO service_role;
GRANT SELECT ON public.signature_events TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.signature_events TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.signature_events TO service_role;
GRANT SELECT ON public.signature_providers TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.signature_providers TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.signature_providers TO service_role;
GRANT SELECT ON public.signature_request_signers TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.signature_request_signers TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.signature_request_signers TO service_role;
GRANT SELECT ON public.signature_requests TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.signature_requests TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.signature_requests TO service_role;
GRANT SELECT ON public.signed_documents TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.signed_documents TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.signed_documents TO service_role;
GRANT SELECT ON public.signing_certificates TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.signing_certificates TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.signing_certificates TO service_role;
GRANT INSERT, SELECT ON public.submission_assignments TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.submission_assignments TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.submission_assignments TO service_role;
GRANT INSERT, SELECT ON public.submission_delegations TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.submission_delegations TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.submission_delegations TO service_role;
GRANT INSERT, SELECT ON public.submission_dispositions TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.submission_dispositions TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.submission_dispositions TO service_role;
GRANT INSERT, SELECT ON public.submission_escalations TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.submission_escalations TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.submission_escalations TO service_role;
GRANT INSERT, SELECT ON public.submission_sequences TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.submission_sequences TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.submission_sequences TO service_role;
GRANT INSERT, SELECT ON public.submission_sla_events TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.submission_sla_events TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.submission_sla_events TO service_role;
GRANT INSERT, SELECT ON public.submission_tasks TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.submission_tasks TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.submission_tasks TO service_role;
GRANT INSERT, SELECT ON public.submission_values TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.submission_values TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.submission_values TO service_role;
GRANT INSERT, SELECT ON public.submission_versions TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.submission_versions TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.submission_versions TO service_role;
GRANT INSERT, SELECT ON public.uat_results TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.uat_results TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.uat_results TO service_role;
GRANT INSERT, SELECT ON public.uat_scenarios TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.uat_scenarios TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.uat_scenarios TO service_role;
GRANT INSERT, SELECT ON public.user_permissions TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.user_permissions TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.user_permissions TO service_role;
GRANT INSERT, SELECT ON public.user_roles TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.user_roles TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.user_roles TO postgres;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.user_roles TO service_role;
GRANT SELECT ON public.v_permohonan_overdue TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.v_permohonan_overdue TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.v_permohonan_overdue TO service_role;
GRANT INSERT, SELECT ON public.verification_logs TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.verification_logs TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.verification_logs TO service_role;
GRANT INSERT, SELECT ON public.verification_token TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.verification_token TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.verification_token TO service_role;
GRANT INSERT, SELECT ON public.work_schedule TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.work_schedule TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.work_schedule TO service_role;
GRANT INSERT, SELECT ON public.work_schedule_assignment TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.work_schedule_assignment TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.work_schedule_assignment TO service_role;
GRANT INSERT, SELECT ON public.workflow_audit_logs TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.workflow_audit_logs TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.workflow_audit_logs TO service_role;
GRANT INSERT, SELECT ON public.workflow_definitions TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.workflow_definitions TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.workflow_definitions TO service_role;
GRANT INSERT, SELECT ON public.workflow_edges TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.workflow_edges TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.workflow_edges TO service_role;
GRANT INSERT, SELECT ON public.workflow_instances TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.workflow_instances TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.workflow_instances TO service_role;
GRANT INSERT, SELECT ON public.workflow_nodes TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.workflow_nodes TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.workflow_nodes TO service_role;
GRANT INSERT, SELECT ON public.workflow_templates TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.workflow_templates TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.workflow_templates TO service_role;
GRANT INSERT, SELECT ON public.workflow_versions TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.workflow_versions TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.workflow_versions TO service_role;
GRANT INSERT, SELECT ON public.workflows TO anon;
GRANT DELETE, INSERT, SELECT, UPDATE ON public.workflows TO authenticated;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON public.workflows TO service_role;

-- ---------- SEQUENCE GRANTS ----------
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

NOTIFY pgrst, 'reload schema';
