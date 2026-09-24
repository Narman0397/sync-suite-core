DO $baseline$
DECLARE r record;
BEGIN
  FOR r IN SELECT part, sql FROM public._baseline_bootstrap ORDER BY part LOOP
    RAISE NOTICE 'applying baseline part %', r.part;
    EXECUTE r.sql;
  END LOOP;
END
$baseline$;
NOTIFY pgrst, 'reload schema';