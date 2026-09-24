CREATE OR REPLACE FUNCTION public.dashboard_summary(_opd uuid DEFAULT NULL, _days integer DEFAULT 14)
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  _uid uuid := auth.uid();
  _is_super boolean;
  _scope_opd uuid;
  _since timestamptz := now() - make_interval(days => GREATEST(COALESCE(_days,14),1));
  _kpi jsonb; _trend jsonb; _kategori jsonb; _sla jsonb; _backlog jsonb;
BEGIN
  IF _uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;

  _is_super := public.has_role(_uid, 'super_admin'::public.app_role)
            OR public.has_role(_uid, 'admin_pemda'::public.app_role)
            OR public.has_role(_uid, 'pimpinan'::public.app_role);

  IF _is_super THEN
    _scope_opd := _opd;
  ELSE
    SELECT opd_id INTO _scope_opd FROM public.profiles WHERE id = _uid;
    IF _scope_opd IS NULL THEN
      RAISE EXCEPTION 'no opd scope for user' USING ERRCODE = '42501';
    END IF;
  END IF;

  WITH p AS (
    SELECT * FROM public.permohonan
    WHERE (_scope_opd IS NULL OR opd_id = _scope_opd)
      AND tanggal_masuk >= _since
  )
  SELECT jsonb_build_object(
    'baru',     COUNT(*) FILTER (WHERE status = 'baru'),
    'diproses', COUNT(*) FILTER (WHERE status NOT IN ('baru','selesai','ditolak')),
    'selesai',  COUNT(*) FILTER (WHERE status = 'selesai'),
    'ditolak',  COUNT(*) FILTER (WHERE status = 'ditolak'),
    'total',    COUNT(*)
  ) INTO _kpi FROM p;

  SELECT COALESCE(jsonb_agg(jsonb_build_object('key', d.key, 'masuk', d.masuk, 'selesai', d.selesai) ORDER BY d.key), '[]'::jsonb)
  INTO _trend
  FROM (
    SELECT to_char(g.day, 'YYYY-MM-DD') AS key,
           COUNT(pm.id) AS masuk,
           COUNT(ps.id) AS selesai
    FROM generate_series(date_trunc('day', _since), date_trunc('day', now()), interval '1 day') AS g(day)
    LEFT JOIN public.permohonan pm
      ON date_trunc('day', pm.tanggal_masuk) = g.day
     AND (_scope_opd IS NULL OR pm.opd_id = _scope_opd)
    LEFT JOIN public.permohonan ps
      ON date_trunc('day', ps.updated_at) = g.day
     AND ps.status = 'selesai'
     AND (_scope_opd IS NULL OR ps.opd_id = _scope_opd)
    GROUP BY g.day
  ) d;

  SELECT COALESCE(jsonb_agg(jsonb_build_object('nama', k.kategori, 'jumlah', k.jumlah) ORDER BY k.jumlah DESC), '[]'::jsonb)
  INTO _kategori
  FROM (
    SELECT COALESCE(NULLIF(kategori,''),'Lainnya') AS kategori, COUNT(*) AS jumlah
    FROM public.permohonan
    WHERE (_scope_opd IS NULL OR opd_id = _scope_opd) AND tanggal_masuk >= _since
    GROUP BY 1
  ) k;

  SELECT COALESCE(jsonb_agg(jsonb_build_object('nama', s.nama, 'total', s.total, 'on_time', s.on_time) ORDER BY s.total DESC), '[]'::jsonb)
  INTO _sla
  FROM (
    SELECT COALESCE(NULLIF(pm.kategori,''),'Lainnya') AS nama,
           COUNT(*) AS total,
           COUNT(*) FILTER (WHERE pm.tenggat IS NULL OR pm.updated_at <= pm.tenggat) AS on_time
    FROM public.permohonan pm
    WHERE (_scope_opd IS NULL OR pm.opd_id = _scope_opd)
      AND pm.tanggal_masuk >= _since
      AND pm.status = 'selesai'
    GROUP BY 1
  ) s;

  SELECT COALESCE(jsonb_agg(jsonb_build_object('opd_id', b.opd_id, 'singkatan', b.singkatan, 'nama', b.nama, 'baru', b.baru, 'diproses', b.diproses) ORDER BY (b.baru + b.diproses) DESC), '[]'::jsonb)
  INTO _backlog
  FROM (
    SELECT pm.opd_id, o.singkatan, o.nama,
           COUNT(*) FILTER (WHERE pm.status = 'baru') AS baru,
           COUNT(*) FILTER (WHERE pm.status NOT IN ('baru','selesai','ditolak')) AS diproses
    FROM public.permohonan pm
    LEFT JOIN public.opd o ON o.id = pm.opd_id
    WHERE (_scope_opd IS NULL OR pm.opd_id = _scope_opd)
      AND pm.status NOT IN ('selesai','ditolak')
    GROUP BY pm.opd_id, o.singkatan, o.nama
  ) b;

  RETURN jsonb_build_object(
    'scope', jsonb_build_object('opd_id', _scope_opd, 'is_super', _is_super, 'days', GREATEST(COALESCE(_days,14),1)),
    'kpi', _kpi, 'trend', _trend, 'kategori', _kategori, 'sla', _sla, 'backlog', _backlog
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.dashboard_summary(uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.dashboard_summary(uuid, integer) TO authenticated, service_role;