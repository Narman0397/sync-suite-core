CREATE OR REPLACE FUNCTION public.count_permohonan_bulan_ini()
RETURNS integer
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  result_count integer := 0;
  col text;
BEGIN
  IF to_regclass('public.permohonan') IS NULL THEN
    RETURN 0;
  END IF;

  SELECT c.column_name INTO col
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
    AND c.table_name = 'permohonan'
    AND c.column_name IN ('tanggal_masuk','created_at')
  ORDER BY CASE c.column_name WHEN 'tanggal_masuk' THEN 1 ELSE 2 END
  LIMIT 1;

  IF col IS NULL THEN
    RETURN 0;
  END IF;

  EXECUTE format(
    'SELECT count(*)::integer FROM public.permohonan WHERE %I >= date_trunc(''month'', now())',
    col
  ) INTO result_count;

  RETURN COALESCE(result_count, 0);
END;
$function$;