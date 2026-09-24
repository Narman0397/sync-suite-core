-- Fix executive_summary: permohonan has no completed_at column
CREATE OR REPLACE FUNCTION public.executive_summary()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_result jsonb;
BEGIN
  IF v_uid IS NULL OR NOT public.is_executive(v_uid) THEN
    RAISE EXCEPTION 'Forbidden: executive dashboard access required' USING ERRCODE = '42501';
  END IF;

  SELECT jsonb_build_object(
    'kabupaten', jsonb_build_object(
      'permohonan_total', (SELECT COUNT(*) FROM public.permohonan),
      'permohonan_bulan', (SELECT COUNT(*) FROM public.permohonan WHERE tanggal_masuk >= date_trunc('month', now())),
      'permohonan_selesai', (SELECT COUNT(*) FROM public.permohonan WHERE status = 'selesai'),
      'permohonan_overdue', (SELECT COUNT(*) FROM public.permohonan WHERE tenggat IS NOT NULL AND tenggat < now() AND status NOT IN ('selesai', 'ditolak')),
      'laporan_total', (SELECT COUNT(*) FROM public.laporan_masyarakat),
      'laporan_open', (SELECT COUNT(*) FROM public.laporan_masyarakat WHERE status NOT IN ('selesai', 'ditutup', 'closed')),
      'aset_total', (SELECT COUNT(*) FROM public.aset),
      'aset_rusak', (SELECT COUNT(*) FROM public.aset WHERE lower(COALESCE(kondisi, '')) LIKE 'rusak%' OR lower(COALESCE(status, '')) IN ('rusak', 'hilang')),
      'ikm_responses_30d', (SELECT COUNT(*) FROM public.ikm_responses WHERE created_at >= now() - interval '30 days'),
      'opd_count', (SELECT COUNT(*) FROM public.opd),
      'asn_count', (SELECT COUNT(*) FROM public.profiles WHERE nip IS NOT NULL AND btrim(nip) <> ''),
      'izin_pending', (SELECT COUNT(*) FROM public.pengajuan_izin WHERE status IN ('pending', 'menunggu', 'diajukan')),
      'dataset_template_active', (SELECT COUNT(*) FROM public.dataset_template WHERE aktif IS TRUE),
      'dataset_submission_active', (SELECT COUNT(*) FROM public.dataset_submission WHERE status NOT IN ('selesai', 'ditolak', 'approved', 'rejected')),
      'dataset_review_pending', (SELECT COUNT(*) FROM public.dataset_submission WHERE COALESCE(review_status, status) IN ('pending', 'menunggu', 'submitted', 'diajukan')),
      'sla_on_time_pct', COALESCE((SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'selesai' AND (tenggat IS NULL OR updated_at <= tenggat)) / NULLIF(COUNT(*) FILTER (WHERE status = 'selesai'), 0), 1) FROM public.permohonan), 0)
    ),
    'generated_at', now()
  ) INTO v_result;

  RETURN v_result;
END;
$function$

;
