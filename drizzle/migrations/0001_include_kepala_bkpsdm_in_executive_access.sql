CREATE OR REPLACE FUNCTION public.is_executive(_uid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.has_role(_uid, 'super_admin'::app_role)
      OR public.has_role(_uid, 'admin_pemda'::app_role)
      OR public.has_role(_uid, 'pimpinan'::app_role)
      OR public.has_role(_uid, 'kepala_bkpsdm'::app_role)
$$;

REVOKE ALL ON FUNCTION public.is_executive(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_executive(uuid) TO authenticated, service_role;