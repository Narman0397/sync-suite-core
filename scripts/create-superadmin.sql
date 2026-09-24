-- =====================================================================
-- Buat / perbarui akun SUPER ADMIN terverifikasi
-- Jalankan di: Supabase Dashboard -> SQL Editor -> New query -> Run
-- Idempoten: aman dijalankan berulang kali.
-- =====================================================================

-- Ubah 4 nilai di bawah ini sesuai kebutuhan

DO $$
DECLARE
  v_email    text := 'narman208@gmail.com';
  v_password text := 'Poogalampa97';
  v_username text := 'superadmin';
  v_nama     text := 'Super Administrator';
  v_user_id  uuid;
BEGIN
  -- pgcrypto diperlukan untuk hashing password bcrypt
  CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower(v_email);

  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid();

    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) VALUES (
      '00000000-0000-0000-0000-000000000000', v_user_id, 'authenticated', 'authenticated',
      lower(v_email), extensions.crypt(v_password, extensions.gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('nama_lengkap', v_nama, 'username', v_username, 'email_verified', true),
      '', '', '', ''
    );
  ELSE
    UPDATE auth.users
       SET encrypted_password = extensions.crypt(v_password, extensions.gen_salt('bf')),
           email_confirmed_at = COALESCE(email_confirmed_at, now()),
           banned_until       = NULL,
           deleted_at         = NULL,
           updated_at         = now(),
           raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb)
             || jsonb_build_object('nama_lengkap', v_nama, 'username', v_username, 'email_verified', true)
     WHERE id = v_user_id;
  END IF;

  -- Identity email (dibutuhkan agar login email/password konsisten)
  IF NOT EXISTS (
    SELECT 1 FROM auth.identities
     WHERE user_id = v_user_id AND provider = 'email'
  ) THEN
    INSERT INTO auth.identities (
      id, user_id, provider_id, provider, identity_data,
      last_sign_in_at, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), v_user_id, v_user_id::text, 'email',
      jsonb_build_object('sub', v_user_id::text, 'email', lower(v_email), 'email_verified', true),
      now(), now(), now()
    );
  END IF;

  -- Profil terverifikasi
  INSERT INTO public.profiles (
    id, nama_lengkap, full_name, email, username, status,
    verification_status, verification_method, verified_at, created_at, updated_at
  ) VALUES (
    v_user_id, v_nama, v_nama, lower(v_email), v_username, 'active',
    'verified', 'superadmin', now(), now(), now()
  )
  ON CONFLICT (id) DO UPDATE SET
    nama_lengkap        = EXCLUDED.nama_lengkap,
    full_name           = EXCLUDED.full_name,
    email               = EXCLUDED.email,
    username            = EXCLUDED.username,
    status              = 'active',
    verification_status = 'verified',
    verification_method = 'superadmin',
    verified_at         = COALESCE(public.profiles.verified_at, now()),
    updated_at          = now();

  -- Role super_admin
  INSERT INTO public.user_roles (user_id, role)
  VALUES (v_user_id, 'super_admin'::public.app_role)
  ON CONFLICT (user_id, role) DO NOTHING;

  RAISE NOTICE 'Super admin siap: % (id=%)', v_email, v_user_id;
END
$$;

-- Verifikasi hasil
SELECT u.email,
       u.email_confirmed_at IS NOT NULL AS email_terkonfirmasi,
       p.username,
       p.verification_status,
       r.role
  FROM auth.users u
  LEFT JOIN public.profiles p   ON p.id = u.id
  LEFT JOIN public.user_roles r ON r.user_id = u.id
 WHERE lower(u.email) = lower('narman208@gmail.com');
