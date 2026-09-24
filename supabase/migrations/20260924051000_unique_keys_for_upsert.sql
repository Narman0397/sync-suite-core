-- Kunci unik bagi operasi simpan "upsert" (ON CONFLICT).
--
-- Tanpa batasan unik ini, PostgreSQL menolak perintah upsert dengan galat:
--   "there is no unique or exclusion constraint matching the ON CONFLICT specification"
--
-- Tabel terdampak:
--   * public.asn_face_template  -> perekaman wajah ASN (satu template per ASN)
--   * public.payroll_periods    -> penguncian periode penggajian per OPD

-- Satu template wajah per ASN.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.asn_face_template'::regclass
      AND conname = 'asn_face_template_user_id_key'
  ) THEN
    ALTER TABLE public.asn_face_template
      ADD CONSTRAINT asn_face_template_user_id_key UNIQUE (user_id);
  END IF;
END
$$;

-- Satu periode penggajian per (OPD, tahun, bulan).
-- Indeks ekspresi payroll_periods_unique_idx tetap dipertahankan: ia menjaga
-- agar penguncian tingkat kabupaten (opd_id NULL) tidak terduplikasi.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.payroll_periods'::regclass
      AND conname = 'payroll_periods_opd_id_tahun_bulan_key'
  ) THEN
    ALTER TABLE public.payroll_periods
      ADD CONSTRAINT payroll_periods_opd_id_tahun_bulan_key UNIQUE (opd_id, tahun, bulan);
  END IF;
END
$$;
