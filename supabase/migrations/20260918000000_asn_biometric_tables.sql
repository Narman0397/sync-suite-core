CREATE TABLE IF NOT EXISTS public.asn_webauthn_credential (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  credential_id text NOT NULL UNIQUE,
  public_key text NOT NULL,
  counter integer NOT NULL DEFAULT 0,
  transports text[],
  device_label text,
  finger_label text,
  aktif boolean NOT NULL DEFAULT true,
  enrolled_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  last_used_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.asn_webauthn_credential TO authenticated;
GRANT ALL ON public.asn_webauthn_credential TO service_role;
ALTER TABLE public.asn_webauthn_credential ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "asn_webauthn_credential_own" ON public.asn_webauthn_credential;
CREATE POLICY "asn_webauthn_credential_own" ON public.asn_webauthn_credential
  FOR ALL TO authenticated
  USING (user_id = auth.uid() OR public.has_role(auth.uid(),'super_admin'::public.app_role))
  WITH CHECK (user_id = auth.uid() OR public.has_role(auth.uid(),'super_admin'::public.app_role));

CREATE TABLE IF NOT EXISTS public.asn_webauthn_challenge (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  challenge text NOT NULL,
  tujuan text NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.asn_webauthn_challenge TO authenticated;
GRANT ALL ON public.asn_webauthn_challenge TO service_role;
ALTER TABLE public.asn_webauthn_challenge ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "asn_webauthn_challenge_own" ON public.asn_webauthn_challenge;
CREATE POLICY "asn_webauthn_challenge_own" ON public.asn_webauthn_challenge
  FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE TABLE IF NOT EXISTS public.asn_face_template (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  opd_id uuid REFERENCES public.opd(id) ON DELETE SET NULL,
  embedding double precision[] NOT NULL,
  samples integer NOT NULL DEFAULT 1,
  adapt_count integer NOT NULL DEFAULT 0,
  quality numeric,
  aktif boolean NOT NULL DEFAULT true,
  enrolled_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.asn_face_template TO authenticated;
GRANT ALL ON public.asn_face_template TO service_role;
ALTER TABLE public.asn_face_template ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "asn_face_template_own" ON public.asn_face_template;
CREATE POLICY "asn_face_template_own" ON public.asn_face_template
  FOR ALL TO authenticated
  USING (user_id = auth.uid() OR public.has_role(auth.uid(),'super_admin'::public.app_role))
  WITH CHECK (user_id = auth.uid() OR public.has_role(auth.uid(),'super_admin'::public.app_role));

CREATE TABLE IF NOT EXISTS public.asn_wfa_assignment (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  opd_id uuid REFERENCES public.opd(id) ON DELETE SET NULL,
  mulai date NOT NULL,
  selesai date NOT NULL,
  alasan text,
  nomor_surat text,
  status text NOT NULL DEFAULT 'approved',
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.asn_wfa_assignment TO authenticated;
GRANT ALL ON public.asn_wfa_assignment TO service_role;
ALTER TABLE public.asn_wfa_assignment ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "asn_wfa_assignment_read" ON public.asn_wfa_assignment;
CREATE POLICY "asn_wfa_assignment_read" ON public.asn_wfa_assignment
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin_pemda(auth.uid()) OR opd_id = public.get_user_opd(auth.uid()));
DROP POLICY IF EXISTS "asn_wfa_assignment_manage" ON public.asn_wfa_assignment;
CREATE POLICY "asn_wfa_assignment_manage" ON public.asn_wfa_assignment
  FOR ALL TO authenticated
  USING (public.is_admin_pemda(auth.uid()) OR public.has_role(auth.uid(),'admin_opd'::public.app_role))
  WITH CHECK (public.is_admin_pemda(auth.uid()) OR public.has_role(auth.uid(),'admin_opd'::public.app_role));
NOTIFY pgrst, 'reload schema';
