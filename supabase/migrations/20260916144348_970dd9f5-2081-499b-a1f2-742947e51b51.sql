DO $storage$
DECLARE r record;
BEGIN
  FOR r IN SELECT part, sql FROM public._storage_bootstrap ORDER BY part LOOP
    RAISE NOTICE 'applying storage baseline part %', r.part;
    EXECUTE r.sql;
  END LOOP;
END
$storage$;
DROP TABLE IF EXISTS public._storage_bootstrap;
NOTIFY pgrst, 'reload schema';