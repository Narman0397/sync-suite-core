-- Storage baseline: consolidated storage.objects policies (rebuilt, idempotent)

DROP POLICY IF EXISTS signatures_owner_all ON storage.objects;

CREATE POLICY signatures_owner_all ON storage.objects FOR ALL TO authenticated
  USING (bucket_id = 'signatures' AND (auth.uid()::text = (storage.foldername(name))[1] OR public.has_role(auth.uid(),'super_admin')))
  WITH CHECK (bucket_id = 'signatures' AND (auth.uid()::text = (storage.foldername(name))[1] OR public.has_role(auth.uid(),'super_admin')));

DROP POLICY IF EXISTS documents_owner_all ON storage.objects;

CREATE POLICY documents_owner_all ON storage.objects FOR ALL TO authenticated
  USING (bucket_id = 'documents' AND (
    auth.uid()::text = (storage.foldername(name))[1]
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
  ))
  WITH CHECK (bucket_id = 'documents' AND (
    auth.uid()::text = (storage.foldername(name))[1]
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
  ));

DROP POLICY IF EXISTS signed_documents_admin ON storage.objects;

CREATE POLICY signed_documents_admin ON storage.objects FOR ALL TO authenticated
  USING (bucket_id = 'signed-documents' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR auth.uid()::text = (storage.foldername(name))[1]
  ))
  WITH CHECK (bucket_id = 'signed-documents' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR auth.uid()::text = (storage.foldername(name))[1]
  ));

DROP POLICY IF EXISTS verification_assets_read ON storage.objects;

CREATE POLICY verification_assets_read ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'verification-assets');

DROP POLICY IF EXISTS verification_assets_write ON storage.objects;

CREATE POLICY verification_assets_write ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'verification-assets' AND (
    public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
  ));

DROP POLICY IF EXISTS verification_assets_update ON storage.objects;

CREATE POLICY verification_assets_update ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'verification-assets' AND (
    public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
  ));

DROP POLICY IF EXISTS verification_assets_delete ON storage.objects;

CREATE POLICY verification_assets_delete ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'verification-assets' AND public.has_role(auth.uid(),'super_admin'));

DROP POLICY IF EXISTS "branding_read_all_auth" ON storage.objects;

CREATE POLICY "branding_read_all_auth" ON storage.objects FOR SELECT
TO authenticated USING (bucket_id = 'branding');

DROP POLICY IF EXISTS "branding_write_admin" ON storage.objects;

CREATE POLICY "branding_write_admin" ON storage.objects FOR INSERT
TO authenticated WITH CHECK (
  bucket_id = 'branding' AND (
    public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
  )
);

DROP POLICY IF EXISTS "branding_update_admin" ON storage.objects;

CREATE POLICY "branding_update_admin" ON storage.objects FOR UPDATE
TO authenticated USING (
  bucket_id = 'branding' AND (
    public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
  )
);

DROP POLICY IF EXISTS "branding_delete_admin" ON storage.objects;

CREATE POLICY "branding_delete_admin" ON storage.objects FOR DELETE
TO authenticated USING (
  bucket_id = 'branding' AND (
    public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
  )
);

DROP POLICY IF EXISTS "pejabat_read_all_auth" ON storage.objects;

CREATE POLICY "pejabat_read_all_auth" ON storage.objects FOR SELECT
TO authenticated USING (bucket_id = 'pejabat-foto');

DROP POLICY IF EXISTS "pejabat_write_admin" ON storage.objects;

CREATE POLICY "pejabat_write_admin" ON storage.objects FOR INSERT
TO authenticated WITH CHECK (
  bucket_id = 'pejabat-foto' AND (
    public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
  )
);

DROP POLICY IF EXISTS "pejabat_update_admin" ON storage.objects;

CREATE POLICY "pejabat_update_admin" ON storage.objects FOR UPDATE
TO authenticated USING (
  bucket_id = 'pejabat-foto' AND (
    public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
  )
);

DROP POLICY IF EXISTS "pejabat_delete_admin" ON storage.objects;

CREATE POLICY "pejabat_delete_admin" ON storage.objects FOR DELETE
TO authenticated USING (
  bucket_id = 'pejabat-foto' AND (
    public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
  )
);

DROP POLICY IF EXISTS "berkas_read_owner_or_admin" ON storage.objects;

CREATE POLICY "berkas_read_owner_or_admin" ON storage.objects FOR SELECT
TO authenticated USING (
  bucket_id = 'berkas-permohonan' AND (
    owner = auth.uid()
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_opd')
    OR public.has_role(auth.uid(),'admin_pemda')
  )
);

DROP POLICY IF EXISTS "berkas_insert_own_folder" ON storage.objects;

CREATE POLICY "berkas_insert_own_folder" ON storage.objects FOR INSERT
TO authenticated WITH CHECK (
  bucket_id = 'berkas-permohonan' AND auth.uid() IS NOT NULL
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "berkas_delete_owner_or_admin" ON storage.objects;

CREATE POLICY "berkas_delete_owner_or_admin" ON storage.objects FOR DELETE
TO authenticated USING (
  bucket_id = 'berkas-permohonan' AND (
    owner = auth.uid()
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_opd')
  )
);

DROP POLICY IF EXISTS "aset_read_auth" ON storage.objects;

CREATE POLICY "aset_read_auth" ON storage.objects FOR SELECT
TO authenticated USING (
  bucket_id = 'aset-foto' AND (
    owner = auth.uid()
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_opd')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'asn')
  )
);

DROP POLICY IF EXISTS "aset_insert_auth" ON storage.objects;

CREATE POLICY "aset_insert_auth" ON storage.objects FOR INSERT
TO authenticated WITH CHECK (
  bucket_id = 'aset-foto' AND auth.uid() IS NOT NULL
);

DROP POLICY IF EXISTS "aset_delete_owner_or_admin" ON storage.objects;

CREATE POLICY "aset_delete_owner_or_admin" ON storage.objects FOR DELETE
TO authenticated USING (
  bucket_id = 'aset-foto' AND (
    owner = auth.uid()
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_opd')
  )
);

DROP POLICY IF EXISTS "absensi_read_owner_or_admin" ON storage.objects;

CREATE POLICY "absensi_read_owner_or_admin" ON storage.objects FOR SELECT
TO authenticated USING (
  bucket_id = 'absensi-foto' AND (
    owner = auth.uid()
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_opd')
    OR public.has_role(auth.uid(),'admin_pemda')
  )
);

DROP POLICY IF EXISTS "absensi_insert_own_folder" ON storage.objects;

CREATE POLICY "absensi_insert_own_folder" ON storage.objects FOR INSERT
TO authenticated WITH CHECK (
  bucket_id = 'absensi-foto' AND auth.uid() IS NOT NULL
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "absensi_delete_admin" ON storage.objects;

CREATE POLICY "absensi_delete_admin" ON storage.objects FOR DELETE
TO authenticated USING (
  bucket_id = 'absensi-foto' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_opd')
  )
);

DROP POLICY IF EXISTS "form_uploads_read_owner_or_admin" ON storage.objects;

CREATE POLICY "form_uploads_read_owner_or_admin" ON storage.objects FOR SELECT
TO authenticated USING (
  bucket_id = 'form-uploads' AND (
    owner = auth.uid()
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_opd')
    OR public.has_role(auth.uid(),'admin_pemda')
  )
);

DROP POLICY IF EXISTS "form_uploads_insert_own_folder" ON storage.objects;

CREATE POLICY "form_uploads_insert_own_folder" ON storage.objects FOR INSERT
TO authenticated WITH CHECK (
  bucket_id = 'form-uploads' AND auth.uid() IS NOT NULL
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "form_uploads_delete_owner_or_admin" ON storage.objects;

CREATE POLICY "form_uploads_delete_owner_or_admin" ON storage.objects FOR DELETE
TO authenticated USING (
  bucket_id = 'form-uploads' AND (
    owner = auth.uid()
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_opd')
  )
);

DROP POLICY IF EXISTS "share_files_read_auth" ON storage.objects;

CREATE POLICY "share_files_read_auth" ON storage.objects FOR SELECT
TO authenticated USING (
  bucket_id = 'share-files' AND (
    owner = auth.uid()
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_opd')
    OR public.has_role(auth.uid(),'admin_pemda')
  )
);

DROP POLICY IF EXISTS "share_files_write_admin" ON storage.objects;

CREATE POLICY "share_files_write_admin" ON storage.objects FOR INSERT
TO authenticated WITH CHECK (
  bucket_id = 'share-files' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_opd')
    OR public.has_role(auth.uid(),'admin_pemda')
  )
);

DROP POLICY IF EXISTS "share_files_delete_admin" ON storage.objects;

CREATE POLICY "share_files_delete_admin" ON storage.objects FOR DELETE
TO authenticated USING (
  bucket_id = 'share-files' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_opd')
    OR public.has_role(auth.uid(),'admin_pemda')
  )
);

DROP POLICY IF EXISTS doc_tpl_select ON storage.objects;

DROP POLICY IF EXISTS doc_tpl_write  ON storage.objects;

DROP POLICY IF EXISTS doc_tpl_select ON storage.objects;

CREATE POLICY doc_tpl_select ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id='document-templates' AND (
    public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'admin_opd')));

DROP POLICY IF EXISTS doc_tpl_write ON storage.objects;

CREATE POLICY doc_tpl_write ON storage.objects FOR ALL TO authenticated
  USING (bucket_id='document-templates' AND (public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda') OR public.has_role(auth.uid(),'admin_opd')))
  WITH CHECK (bucket_id='document-templates' AND (public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda') OR public.has_role(auth.uid(),'admin_opd')));

DROP POLICY IF EXISTS doc_files_select ON storage.objects;

DROP POLICY IF EXISTS doc_files_select ON storage.objects;

CREATE POLICY doc_files_select ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id='documents' AND EXISTS(
    SELECT 1 FROM public.generated_documents g
    JOIN public.form_submissions s ON s.id = g.submission_id
    WHERE g.storage_path = storage.objects.name AND (
      public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
      OR s.user_id = auth.uid() OR s.opd_id = public.get_user_opd(auth.uid())
    )));

DROP POLICY IF EXISTS "berkas_permohonan_select" ON storage.objects;

DROP POLICY IF EXISTS "berkas_permohonan_insert" ON storage.objects;

DROP POLICY IF EXISTS "berkas_permohonan_delete" ON storage.objects;

DROP POLICY IF EXISTS "berkas_permohonan_select" ON storage.objects;

CREATE POLICY "berkas_permohonan_select" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'berkas-permohonan');

DROP POLICY IF EXISTS "berkas_permohonan_insert" ON storage.objects;

CREATE POLICY "berkas_permohonan_insert" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'berkas-permohonan');

DROP POLICY IF EXISTS "berkas_permohonan_delete" ON storage.objects;

CREATE POLICY "berkas_permohonan_delete" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'berkas-permohonan' AND (owner = auth.uid() OR public.has_role(auth.uid(),'admin_opd') OR public.has_role(auth.uid(),'super_admin')));

DROP POLICY IF EXISTS "signed_documents_select" ON storage.objects;

DROP POLICY IF EXISTS "signed_documents_insert" ON storage.objects;

DROP POLICY IF EXISTS "signed_documents_select" ON storage.objects;

CREATE POLICY "signed_documents_select" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'signed-documents');

DROP POLICY IF EXISTS "signed_documents_insert" ON storage.objects;

CREATE POLICY "signed_documents_insert" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'signed-documents');

DROP POLICY IF EXISTS "aset_foto_select" ON storage.objects;

DROP POLICY IF EXISTS "aset_foto_write" ON storage.objects;

DROP POLICY IF EXISTS "aset_foto_select" ON storage.objects;

CREATE POLICY "aset_foto_select" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'aset-foto');

DROP POLICY IF EXISTS "aset_foto_write" ON storage.objects;

CREATE POLICY "aset_foto_write" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'aset-foto');

DROP POLICY IF EXISTS "share_files_select" ON storage.objects;

DROP POLICY IF EXISTS "share_files_write" ON storage.objects;

DROP POLICY IF EXISTS "share_files_select" ON storage.objects;

CREATE POLICY "share_files_select" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'share-files');

DROP POLICY IF EXISTS "share_files_write" ON storage.objects;

CREATE POLICY "share_files_write" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'share-files');

DROP POLICY IF EXISTS "branding_select" ON storage.objects;

DROP POLICY IF EXISTS "branding_write" ON storage.objects;

DROP POLICY IF EXISTS "branding_select" ON storage.objects;

CREATE POLICY "branding_select" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'branding');

DROP POLICY IF EXISTS "branding_write" ON storage.objects;

CREATE POLICY "branding_write" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'branding' AND (public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')));

DROP POLICY IF EXISTS "pejabat_foto_select" ON storage.objects;

DROP POLICY IF EXISTS "pejabat_foto_write" ON storage.objects;

DROP POLICY IF EXISTS "pejabat_foto_select" ON storage.objects;

CREATE POLICY "pejabat_foto_select" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'pejabat-foto');

DROP POLICY IF EXISTS "pejabat_foto_write" ON storage.objects;

CREATE POLICY "pejabat_foto_write" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'pejabat-foto' AND (public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda') OR public.has_role(auth.uid(),'admin_opd')));

DROP POLICY IF EXISTS "user_upload_own_folder_permohonan" ON storage.objects;

DO $$ BEGIN
  CREATE POLICY "user_upload_own_folder_permohonan" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id IN ('berkas-permohonan','form-submissions')
                AND (storage.foldername(name))[1] = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DROP POLICY IF EXISTS "user_read_own_folder_permohonan" ON storage.objects;

DO $$ BEGIN
  CREATE POLICY "user_read_own_folder_permohonan" ON storage.objects
    FOR SELECT TO authenticated
    USING (bucket_id IN ('berkas-permohonan','form-submissions')
           AND ((storage.foldername(name))[1] = auth.uid()::text
                OR public.has_role(auth.uid(),'super_admin')
                OR public.has_role(auth.uid(),'admin_pemda')
                OR public.has_role(auth.uid(),'admin_opd')));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DROP POLICY IF EXISTS "user_delete_own_folder_permohonan" ON storage.objects;

DO $$ BEGIN
  CREATE POLICY "user_delete_own_folder_permohonan" ON storage.objects
    FOR DELETE TO authenticated
    USING (bucket_id IN ('berkas-permohonan','form-submissions')
           AND ((storage.foldername(name))[1] = auth.uid()::text
                OR public.has_role(auth.uid(),'super_admin')));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DROP POLICY IF EXISTS "admin_write_foto" ON storage.objects;

DO $$ BEGIN
  CREATE POLICY "admin_write_foto" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id IN ('aset-foto','pejabat-foto')
                AND (public.has_role(auth.uid(),'super_admin')
                     OR public.has_role(auth.uid(),'admin_pemda')
                     OR public.has_role(auth.uid(),'admin_opd')));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DROP POLICY IF EXISTS "auth_read_foto" ON storage.objects;

DO $$ BEGIN
  CREATE POLICY "auth_read_foto" ON storage.objects
    FOR SELECT TO authenticated
    USING (bucket_id IN ('aset-foto','pejabat-foto'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DROP POLICY IF EXISTS "admin_update_foto" ON storage.objects;

DO $$ BEGIN
  CREATE POLICY "admin_update_foto" ON storage.objects
    FOR UPDATE TO authenticated
    USING (bucket_id IN ('aset-foto','pejabat-foto')
           AND (public.has_role(auth.uid(),'super_admin')
                OR public.has_role(auth.uid(),'admin_pemda')
                OR public.has_role(auth.uid(),'admin_opd')));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DROP POLICY IF EXISTS "admin_delete_foto" ON storage.objects;

DO $$ BEGIN
  CREATE POLICY "admin_delete_foto" ON storage.objects
    FOR DELETE TO authenticated
    USING (bucket_id IN ('aset-foto','pejabat-foto')
           AND (public.has_role(auth.uid(),'super_admin')
                OR public.has_role(auth.uid(),'admin_pemda')
                OR public.has_role(auth.uid(),'admin_opd')));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT polname FROM pg_policy
    WHERE polrelid = 'storage.objects'::regclass
      AND polname LIKE 'lov_%'
  LOOP
    EXECUTE format('DROP POLICY %I ON storage.objects', r.polname);
  END LOOP;
END$$;

DROP POLICY IF EXISTS "lov_branding_read_all" ON storage.objects;

CREATE POLICY "lov_branding_read_all" ON storage.objects FOR SELECT
  USING (bucket_id = 'branding');

DROP POLICY IF EXISTS "lov_branding_write_admin" ON storage.objects;

CREATE POLICY "lov_branding_write_admin" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'branding' AND (
    public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
  ));

DROP POLICY IF EXISTS "lov_branding_update_admin" ON storage.objects;

CREATE POLICY "lov_branding_update_admin" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'branding' AND (
    public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
  ));

DROP POLICY IF EXISTS "lov_branding_delete_admin" ON storage.objects;

CREATE POLICY "lov_branding_delete_admin" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'branding' AND (
    public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
  ));

DROP POLICY IF EXISTS "lov_pejabat_read_all" ON storage.objects;

CREATE POLICY "lov_pejabat_read_all" ON storage.objects FOR SELECT
  USING (bucket_id = 'pejabat-foto');

DROP POLICY IF EXISTS "lov_pejabat_write_admin" ON storage.objects;

CREATE POLICY "lov_pejabat_write_admin" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'pejabat-foto' AND (
    public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
  ));

DROP POLICY IF EXISTS "lov_pejabat_update_admin" ON storage.objects;

CREATE POLICY "lov_pejabat_update_admin" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'pejabat-foto' AND (
    public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
  ));

DROP POLICY IF EXISTS "lov_pejabat_delete_admin" ON storage.objects;

CREATE POLICY "lov_pejabat_delete_admin" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'pejabat-foto' AND (
    public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')
  ));

DROP POLICY IF EXISTS "lov_berkas_read" ON storage.objects;

CREATE POLICY "lov_berkas_read" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'berkas-permohonan' AND (
    owner = auth.uid()
    OR (storage.foldername(name))[1] = auth.uid()::text
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'admin_opd')
    OR public.has_role(auth.uid(),'admin_desa')
  ));

DROP POLICY IF EXISTS "lov_berkas_insert" ON storage.objects;

CREATE POLICY "lov_berkas_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'berkas-permohonan' AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "lov_berkas_update_owner" ON storage.objects;

CREATE POLICY "lov_berkas_update_owner" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'berkas-permohonan' AND owner = auth.uid());

DROP POLICY IF EXISTS "lov_berkas_delete" ON storage.objects;

CREATE POLICY "lov_berkas_delete" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'berkas-permohonan' AND (
    owner = auth.uid()
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'admin_opd')
  ));

DROP POLICY IF EXISTS "lov_absensi_read" ON storage.objects;

CREATE POLICY "lov_absensi_read" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'absensi-foto' AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'admin_opd')
    OR public.has_role(auth.uid(),'admin_bkpsdm')
    OR public.has_role(auth.uid(),'kepala_bkpsdm')
  ));

DROP POLICY IF EXISTS "lov_absensi_insert" ON storage.objects;

CREATE POLICY "lov_absensi_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'absensi-foto' AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "lov_absensi_delete_admin" ON storage.objects;

CREATE POLICY "lov_absensi_delete_admin" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'absensi-foto' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
  ));

DROP POLICY IF EXISTS "lov_formsub_read" ON storage.objects;

CREATE POLICY "lov_formsub_read" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'form-submissions' AND (
    owner = auth.uid()
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'admin_opd')
  ));

DROP POLICY IF EXISTS "lov_formsub_insert" ON storage.objects;

CREATE POLICY "lov_formsub_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'form-submissions' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "lov_formsub_update_owner" ON storage.objects;

CREATE POLICY "lov_formsub_update_owner" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'form-submissions' AND owner = auth.uid());

DROP POLICY IF EXISTS "lov_formsub_delete" ON storage.objects;

CREATE POLICY "lov_formsub_delete" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'form-submissions' AND (
    owner = auth.uid()
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'admin_opd')
  ));

DROP POLICY IF EXISTS "lov_aset_read_admin" ON storage.objects;

CREATE POLICY "lov_aset_read_admin" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'aset-foto' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'admin_opd')
    OR public.has_role(auth.uid(),'asn')
  ));

DROP POLICY IF EXISTS "lov_aset_write_admin" ON storage.objects;

CREATE POLICY "lov_aset_write_admin" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'aset-foto' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'admin_opd')
  ));

DROP POLICY IF EXISTS "lov_aset_update_admin" ON storage.objects;

CREATE POLICY "lov_aset_update_admin" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'aset-foto' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'admin_opd')
  ));

DROP POLICY IF EXISTS "lov_aset_delete_admin" ON storage.objects;

CREATE POLICY "lov_aset_delete_admin" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'aset-foto' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'admin_opd')
  ));

DROP POLICY IF EXISTS "lov_share_admin_all" ON storage.objects;

CREATE POLICY "lov_share_admin_all" ON storage.objects FOR ALL TO authenticated
  USING (bucket_id = 'share-files' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'admin_opd')
  ))
  WITH CHECK (bucket_id = 'share-files' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'admin_opd')
  ));

DROP POLICY IF EXISTS "lov_sig_read" ON storage.objects;

CREATE POLICY "lov_sig_read" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'signatures' AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
  ));

DROP POLICY IF EXISTS "lov_sig_insert" ON storage.objects;

CREATE POLICY "lov_sig_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'signatures' AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "lov_sig_update_owner" ON storage.objects;

CREATE POLICY "lov_sig_update_owner" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'signatures' AND owner = auth.uid());

DROP POLICY IF EXISTS "lov_sig_delete" ON storage.objects;

CREATE POLICY "lov_sig_delete" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'signatures' AND (
    owner = auth.uid()
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
  ));

DROP POLICY IF EXISTS "lov_signed_read_admin" ON storage.objects;

CREATE POLICY "lov_signed_read_admin" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'signed-documents' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'admin_opd')
    OR public.has_role(auth.uid(),'asn')
    OR public.has_role(auth.uid(),'pimpinan')
  ));

DROP POLICY IF EXISTS "lov_signed_admin_write" ON storage.objects;

CREATE POLICY "lov_signed_admin_write" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'signed-documents' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'admin_opd')
    OR public.has_role(auth.uid(),'asn')
  ));

DROP POLICY IF EXISTS "lov_signed_admin_update" ON storage.objects;

CREATE POLICY "lov_signed_admin_update" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'signed-documents' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
  ));

DROP POLICY IF EXISTS "lov_signed_admin_delete" ON storage.objects;

CREATE POLICY "lov_signed_admin_delete" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'signed-documents' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
  ));

DROP POLICY IF EXISTS "lov_verif_read" ON storage.objects;

CREATE POLICY "lov_verif_read" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'verification-assets' AND (
    owner = auth.uid()
    OR public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
    OR public.has_role(auth.uid(),'admin_opd')
    OR public.has_role(auth.uid(),'admin_desa')
    OR public.has_role(auth.uid(),'admin_bkpsdm')
  ));

DROP POLICY IF EXISTS "lov_verif_insert" ON storage.objects;

CREATE POLICY "lov_verif_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'verification-assets' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "lov_verif_update_owner" ON storage.objects;

CREATE POLICY "lov_verif_update_owner" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'verification-assets' AND owner = auth.uid());

DROP POLICY IF EXISTS "lov_verif_delete_admin" ON storage.objects;

CREATE POLICY "lov_verif_delete_admin" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'verification-assets' AND (
    public.has_role(auth.uid(),'super_admin')
    OR public.has_role(auth.uid(),'admin_pemda')
  ));

DROP POLICY IF EXISTS "documents_bucket_read_internal" ON storage.objects;

DROP POLICY IF EXISTS "documents_bucket_write_internal" ON storage.objects;

DROP POLICY IF EXISTS "documents_bucket_update_internal" ON storage.objects;

DROP POLICY IF EXISTS "documents_bucket_delete_admin" ON storage.objects;

DROP POLICY IF EXISTS "documents_bucket_read_internal" ON storage.objects;

CREATE POLICY "documents_bucket_read_internal" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'documents' AND (
    public.has_role(auth.uid(), 'super_admin'::public.app_role)
    OR public.has_role(auth.uid(), 'admin_opd'::public.app_role)
    OR public.has_role(auth.uid(), 'admin_desa'::public.app_role)
    OR public.has_role(auth.uid(), 'asn'::public.app_role)
    OR public.has_role(auth.uid(), 'admin_bkpsdm'::public.app_role)
    OR public.has_role(auth.uid(), 'kepala_bkpsdm'::public.app_role)
    OR public.has_role(auth.uid(), 'admin_pemda'::public.app_role)
    OR public.has_role(auth.uid(), 'pimpinan'::public.app_role)
  )
);

DROP POLICY IF EXISTS "documents_bucket_write_internal" ON storage.objects;

CREATE POLICY "documents_bucket_write_internal" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'documents' AND (
    public.has_role(auth.uid(), 'super_admin'::public.app_role)
    OR public.has_role(auth.uid(), 'admin_opd'::public.app_role)
    OR public.has_role(auth.uid(), 'admin_desa'::public.app_role)
    OR public.has_role(auth.uid(), 'asn'::public.app_role)
    OR public.has_role(auth.uid(), 'admin_bkpsdm'::public.app_role)
    OR public.has_role(auth.uid(), 'kepala_bkpsdm'::public.app_role)
    OR public.has_role(auth.uid(), 'admin_pemda'::public.app_role)
  )
);

DROP POLICY IF EXISTS "documents_bucket_update_internal" ON storage.objects;

CREATE POLICY "documents_bucket_update_internal" ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id = 'documents' AND (
    public.has_role(auth.uid(), 'super_admin'::public.app_role)
    OR public.has_role(auth.uid(), 'admin_opd'::public.app_role)
  )
);

DROP POLICY IF EXISTS "documents_bucket_delete_admin" ON storage.objects;

CREATE POLICY "documents_bucket_delete_admin" ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'documents' AND (
    public.has_role(auth.uid(), 'super_admin'::public.app_role)
    OR public.has_role(auth.uid(), 'admin_opd'::public.app_role)
  )
);

DROP POLICY IF EXISTS "Private buckets owner read" ON storage.objects;

DROP POLICY IF EXISTS "Private buckets owner read" ON storage.objects;

CREATE POLICY "Private buckets owner read" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id IN ('berkas-permohonan','signatures','signed-documents','aset-foto','share-files','branding','pejabat-foto')
    AND owner = auth.uid()
  );

DROP POLICY IF EXISTS "Private buckets owner write" ON storage.objects;

DROP POLICY IF EXISTS "Private buckets owner write" ON storage.objects;

CREATE POLICY "Private buckets owner write" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id IN ('berkas-permohonan','signatures','signed-documents','aset-foto','share-files','branding','pejabat-foto')
    AND owner = auth.uid()
  );

DROP POLICY IF EXISTS "Private buckets owner update" ON storage.objects;

DROP POLICY IF EXISTS "Private buckets owner update" ON storage.objects;

CREATE POLICY "Private buckets owner update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id IN ('berkas-permohonan','signatures','signed-documents','aset-foto','share-files','branding','pejabat-foto')
    AND owner = auth.uid()
  )
  WITH CHECK (owner = auth.uid());

DROP POLICY IF EXISTS "Private buckets owner delete" ON storage.objects;

DROP POLICY IF EXISTS "Private buckets owner delete" ON storage.objects;

CREATE POLICY "Private buckets owner delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id IN ('berkas-permohonan','signatures','signed-documents','aset-foto','share-files','branding','pejabat-foto')
    AND owner = auth.uid()
  );

DROP POLICY IF EXISTS "Public read branding" ON storage.objects;

DROP POLICY IF EXISTS "Public read branding" ON storage.objects;

CREATE POLICY "Public read branding"
  ON storage.objects FOR SELECT
  USING (bucket_id IN ('branding','pejabat-foto'));

DROP POLICY IF EXISTS "Admins manage branding" ON storage.objects;

DROP POLICY IF EXISTS "Admins manage branding" ON storage.objects;

CREATE POLICY "Admins manage branding"
  ON storage.objects FOR ALL
  TO authenticated
  USING (
    bucket_id IN ('branding','pejabat-foto')
    AND (public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda') OR public.has_role(auth.uid(),'admin_opd'))
  )
  WITH CHECK (
    bucket_id IN ('branding','pejabat-foto')
    AND (public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda') OR public.has_role(auth.uid(),'admin_opd'))
  );

DROP POLICY IF EXISTS "branding_public_read" ON storage.objects;

CREATE POLICY "branding_public_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'branding');

DROP POLICY IF EXISTS "branding_admin_write" ON storage.objects;

CREATE POLICY "branding_admin_write" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'branding' AND (public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')));

DROP POLICY IF EXISTS "branding_admin_update" ON storage.objects;

CREATE POLICY "branding_admin_update" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'branding' AND (public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')));

DROP POLICY IF EXISTS "branding_admin_delete" ON storage.objects;

CREATE POLICY "branding_admin_delete" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'branding' AND (public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda')));

DROP POLICY IF EXISTS "pejabat_foto_public_read" ON storage.objects;

CREATE POLICY "pejabat_foto_public_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'pejabat-foto');

DROP POLICY IF EXISTS "pejabat_foto_admin_write" ON storage.objects;

CREATE POLICY "pejabat_foto_admin_write" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'pejabat-foto' AND (public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda') OR public.has_role(auth.uid(),'admin_opd')));

DROP POLICY IF EXISTS "pejabat_foto_admin_update" ON storage.objects;

CREATE POLICY "pejabat_foto_admin_update" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'pejabat-foto' AND (public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda') OR public.has_role(auth.uid(),'admin_opd')));

DROP POLICY IF EXISTS "pejabat_foto_admin_delete" ON storage.objects;

CREATE POLICY "pejabat_foto_admin_delete" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'pejabat-foto' AND (public.has_role(auth.uid(),'super_admin') OR public.has_role(auth.uid(),'admin_pemda') OR public.has_role(auth.uid(),'admin_opd')));

DROP POLICY IF EXISTS "berkas_permohonan_read" ON storage.objects;

CREATE POLICY "berkas_permohonan_read" ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'berkas-permohonan' AND EXISTS (
      SELECT 1 FROM public.permohonan p
      WHERE p.id::text = (storage.foldername(name))[1]
        AND (
          p.pemohon_id = auth.uid()
          OR public.has_role(auth.uid(),'super_admin')
          OR (public.has_role(auth.uid(),'admin_opd') AND p.opd_id = public.get_user_opd(auth.uid()))
        )
    )
  );

DROP POLICY IF EXISTS "berkas_permohonan_write" ON storage.objects;

CREATE POLICY "berkas_permohonan_write" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'berkas-permohonan' AND EXISTS (
      SELECT 1 FROM public.permohonan p
      WHERE p.id::text = (storage.foldername(name))[1]
        AND (
          p.pemohon_id = auth.uid()
          OR public.has_role(auth.uid(),'super_admin')
          OR (public.has_role(auth.uid(),'admin_opd') AND p.opd_id = public.get_user_opd(auth.uid()))
        )
    )
  );

DROP POLICY IF EXISTS "berkas_permohonan_update" ON storage.objects;

CREATE POLICY "berkas_permohonan_update" ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'berkas-permohonan' AND EXISTS (
      SELECT 1 FROM public.permohonan p
      WHERE p.id::text = (storage.foldername(name))[1]
        AND (p.pemohon_id = auth.uid() OR public.has_role(auth.uid(),'super_admin')
             OR (public.has_role(auth.uid(),'admin_opd') AND p.opd_id = public.get_user_opd(auth.uid())))
    )
  );

DROP POLICY IF EXISTS "berkas_permohonan_delete" ON storage.objects;

CREATE POLICY "berkas_permohonan_delete" ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'berkas-permohonan' AND EXISTS (
      SELECT 1 FROM public.permohonan p
      WHERE p.id::text = (storage.foldername(name))[1]
        AND (p.pemohon_id = auth.uid() OR public.has_role(auth.uid(),'super_admin')
             OR (public.has_role(auth.uid(),'admin_opd') AND p.opd_id = public.get_user_opd(auth.uid())))
    )
  );

DROP POLICY IF EXISTS "form_submissions_owner_all" ON storage.objects;

CREATE POLICY "form_submissions_owner_all" ON storage.objects FOR ALL TO authenticated
  USING (
    bucket_id = 'form-submissions' AND (
      (storage.foldername(name))[2] = auth.uid()::text
      OR public.has_role(auth.uid(),'super_admin')
      OR EXISTS (
        SELECT 1 FROM public.forms f
        WHERE f.id::text = (storage.foldername(name))[1]
          AND public.has_role(auth.uid(),'admin_opd')
          AND f.opd_pemilik_id = public.get_user_opd(auth.uid())
      )
    )
  )
  WITH CHECK (
    bucket_id = 'form-submissions' AND (
      (storage.foldername(name))[2] = auth.uid()::text
      OR public.has_role(auth.uid(),'super_admin')
      OR EXISTS (
        SELECT 1 FROM public.forms f
        WHERE f.id::text = (storage.foldername(name))[1]
          AND public.has_role(auth.uid(),'admin_opd')
          AND f.opd_pemilik_id = public.get_user_opd(auth.uid())
      )
    )
  );

DROP POLICY IF EXISTS "aset_foto_all" ON storage.objects;

CREATE POLICY "aset_foto_all" ON storage.objects FOR ALL TO authenticated
  USING (
    bucket_id = 'aset-foto' AND (
      public.has_role(auth.uid(),'super_admin')
      OR (storage.foldername(name))[1] = public.get_user_opd(auth.uid())::text
    )
  )
  WITH CHECK (
    bucket_id = 'aset-foto' AND (
      public.has_role(auth.uid(),'super_admin')
      OR (storage.foldername(name))[1] = public.get_user_opd(auth.uid())::text
    )
  );

DROP POLICY IF EXISTS "signatures_owner_all" ON storage.objects;

CREATE POLICY "signatures_owner_all" ON storage.objects FOR ALL TO authenticated
  USING (
    bucket_id = 'signatures' AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR public.has_role(auth.uid(),'super_admin')
    )
  )
  WITH CHECK (
    bucket_id = 'signatures' AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR public.has_role(auth.uid(),'super_admin')
    )
  );

DROP POLICY IF EXISTS "share_files_admin_read" ON storage.objects;

CREATE POLICY "share_files_admin_read" ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'share-files' AND (
      public.has_role(auth.uid(),'super_admin')
      OR public.has_role(auth.uid(),'admin_pemda')
      OR public.has_role(auth.uid(),'admin_opd')
    )
  );

DROP POLICY IF EXISTS "signed_documents_read" ON storage.objects;

CREATE POLICY "signed_documents_read" ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'signed-documents' AND (
      public.has_role(auth.uid(),'super_admin')
      OR public.has_role(auth.uid(),'admin_pemda')
      OR public.has_role(auth.uid(),'admin_opd')
    )
  );

DROP POLICY IF EXISTS "berkas_permohonan_owner_all" ON storage.objects;

CREATE POLICY "berkas_permohonan_owner_all"
ON storage.objects FOR ALL TO authenticated
USING (bucket_id = 'berkas-permohonan' AND auth.uid()::text = (storage.foldername(name))[1])
WITH CHECK (bucket_id = 'berkas-permohonan' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "berkas_permohonan_admin_read" ON storage.objects;

CREATE POLICY "berkas_permohonan_admin_read"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'berkas-permohonan' AND (
  public.has_role(auth.uid(),'super_admin') OR
  public.has_role(auth.uid(),'admin_pemda') OR
  public.has_role(auth.uid(),'admin_opd') OR
  public.has_role(auth.uid(),'admin_desa')
));

DROP POLICY IF EXISTS "form_submissions_owner_all" ON storage.objects;

CREATE POLICY "form_submissions_owner_all"
ON storage.objects FOR ALL TO authenticated
USING (bucket_id = 'form-submissions' AND auth.uid()::text = (storage.foldername(name))[1])
WITH CHECK (bucket_id = 'form-submissions' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "form_submissions_admin_read" ON storage.objects;

CREATE POLICY "form_submissions_admin_read"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'form-submissions' AND (
  public.has_role(auth.uid(),'super_admin') OR
  public.has_role(auth.uid(),'admin_pemda') OR
  public.has_role(auth.uid(),'admin_opd')
));

DROP POLICY IF EXISTS "signatures_owner_all" ON storage.objects;

CREATE POLICY "signatures_owner_all"
ON storage.objects FOR ALL TO authenticated
USING (bucket_id = 'signatures' AND auth.uid()::text = (storage.foldername(name))[1])
WITH CHECK (bucket_id = 'signatures' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "signed_documents_owner_read" ON storage.objects;

CREATE POLICY "signed_documents_owner_read"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'signed-documents' AND (
  auth.uid()::text = (storage.foldername(name))[1] OR
  public.has_role(auth.uid(),'super_admin') OR
  public.has_role(auth.uid(),'admin_pemda') OR
  public.has_role(auth.uid(),'admin_opd')
));

DROP POLICY IF EXISTS "share_files_owner_all" ON storage.objects;

CREATE POLICY "share_files_owner_all"
ON storage.objects FOR ALL TO authenticated
USING (bucket_id = 'share-files' AND auth.uid()::text = (storage.foldername(name))[1])
WITH CHECK (bucket_id = 'share-files' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "aset_foto_admin_write" ON storage.objects;

CREATE POLICY "aset_foto_admin_write"
ON storage.objects FOR ALL TO authenticated
USING (bucket_id = 'aset-foto' AND (
  public.has_role(auth.uid(),'super_admin') OR
  public.has_role(auth.uid(),'admin_pemda') OR
  public.has_role(auth.uid(),'admin_opd') OR
  public.has_role(auth.uid(),'asn')
))
WITH CHECK (bucket_id = 'aset-foto' AND (
  public.has_role(auth.uid(),'super_admin') OR
  public.has_role(auth.uid(),'admin_pemda') OR
  public.has_role(auth.uid(),'admin_opd') OR
  public.has_role(auth.uid(),'asn')
));

DROP POLICY IF EXISTS "pejabat_foto_public_read" ON storage.objects;

CREATE POLICY "pejabat_foto_public_read"
ON storage.objects FOR SELECT TO anon, authenticated
USING (bucket_id = 'pejabat-foto');

DROP POLICY IF EXISTS "pejabat_foto_admin_write" ON storage.objects;

CREATE POLICY "pejabat_foto_admin_write"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'pejabat-foto' AND (
  public.has_role(auth.uid(),'super_admin') OR
  public.has_role(auth.uid(),'admin_pemda') OR
  public.has_role(auth.uid(),'admin_opd')
));

DROP POLICY IF EXISTS "pejabat_foto_admin_update" ON storage.objects;

CREATE POLICY "pejabat_foto_admin_update"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'pejabat-foto' AND (
  public.has_role(auth.uid(),'super_admin') OR
  public.has_role(auth.uid(),'admin_pemda') OR
  public.has_role(auth.uid(),'admin_opd')
));

DROP POLICY IF EXISTS "pejabat_foto_admin_delete" ON storage.objects;

CREATE POLICY "pejabat_foto_admin_delete"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'pejabat-foto' AND (
  public.has_role(auth.uid(),'super_admin') OR
  public.has_role(auth.uid(),'admin_pemda') OR
  public.has_role(auth.uid(),'admin_opd')
));

DROP POLICY IF EXISTS "branding_public_read" ON storage.objects;

CREATE POLICY "branding_public_read"
ON storage.objects FOR SELECT TO anon, authenticated
USING (bucket_id = 'branding');

DROP POLICY IF EXISTS "branding_admin_write" ON storage.objects;

CREATE POLICY "branding_admin_write"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'branding' AND (
  public.has_role(auth.uid(),'super_admin') OR
  public.has_role(auth.uid(),'admin_pemda')
));

DROP POLICY IF EXISTS "branding_admin_update" ON storage.objects;

CREATE POLICY "branding_admin_update"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'branding' AND (
  public.has_role(auth.uid(),'super_admin') OR
  public.has_role(auth.uid(),'admin_pemda')
));

DROP POLICY IF EXISTS "branding_admin_delete" ON storage.objects;

CREATE POLICY "branding_admin_delete"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'branding' AND (
  public.has_role(auth.uid(),'super_admin') OR
  public.has_role(auth.uid(),'admin_pemda')
));

DROP POLICY IF EXISTS "bukti_dokumen storage read auth" ON storage.objects;

CREATE POLICY "bukti_dokumen storage read auth"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'bukti-dokumen');

DROP POLICY IF EXISTS "bukti_dokumen storage insert auth" ON storage.objects;

CREATE POLICY "bukti_dokumen storage insert auth"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'bukti-dokumen');

DROP POLICY IF EXISTS "bukti_dokumen storage update auth" ON storage.objects;

CREATE POLICY "bukti_dokumen storage update auth"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'bukti-dokumen')
  WITH CHECK (bucket_id = 'bukti-dokumen');

DROP POLICY IF EXISTS "bukti_dokumen storage delete admin" ON storage.objects;

CREATE POLICY "bukti_dokumen storage delete admin"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'bukti-dokumen'
    AND (public.has_role(auth.uid(), 'super_admin'::app_role)
      OR public.has_role(auth.uid(), 'admin_pemda'::app_role)
      OR public.has_role(auth.uid(), 'admin_opd'::app_role)));

DO $$
DECLARE p record;
BEGIN
  FOR p IN SELECT policyname FROM pg_policies WHERE schemaname='storage' AND tablename='objects'
    AND policyname IN (
      'berkas_permohonan_owner_rw','berkas_permohonan_admin_all',
      'aset_foto_owner_rw','aset_foto_admin_all',
      'absensi_foto_owner_rw','absensi_foto_admin_read',
      'form_submissions_owner_rw','form_submissions_admin_all',
      'bukti_dokumen_admin_all',
      'branding_public_read','branding_admin_write',
      'pejabat_foto_public_read','pejabat_foto_admin_write'
    )
  LOOP
    EXECUTE format('DROP POLICY %I ON storage.objects', p.policyname);
  END LOOP;
END $$;

DROP POLICY IF EXISTS "berkas_permohonan_owner_rw" ON storage.objects;

CREATE POLICY "berkas_permohonan_owner_rw" ON storage.objects FOR ALL TO authenticated
  USING (bucket_id='berkas-permohonan' AND (storage.foldername(name))[1]=auth.uid()::text)
  WITH CHECK (bucket_id='berkas-permohonan' AND (storage.foldername(name))[1]=auth.uid()::text);

DROP POLICY IF EXISTS "berkas_permohonan_admin_all" ON storage.objects;

CREATE POLICY "berkas_permohonan_admin_all" ON storage.objects FOR ALL TO authenticated
  USING (bucket_id='berkas-permohonan' AND (public.has_role(auth.uid(),'super_admin'::public.app_role) OR public.has_role(auth.uid(),'admin_pemda'::public.app_role) OR public.has_role(auth.uid(),'admin_opd'::public.app_role)))
  WITH CHECK (bucket_id='berkas-permohonan' AND (public.has_role(auth.uid(),'super_admin'::public.app_role) OR public.has_role(auth.uid(),'admin_pemda'::public.app_role) OR public.has_role(auth.uid(),'admin_opd'::public.app_role)));

DROP POLICY IF EXISTS "aset_foto_owner_rw" ON storage.objects;

CREATE POLICY "aset_foto_owner_rw" ON storage.objects FOR ALL TO authenticated
  USING (bucket_id='aset-foto' AND (storage.foldername(name))[1]=auth.uid()::text)
  WITH CHECK (bucket_id='aset-foto' AND (storage.foldername(name))[1]=auth.uid()::text);

DROP POLICY IF EXISTS "aset_foto_admin_all" ON storage.objects;

CREATE POLICY "aset_foto_admin_all" ON storage.objects FOR ALL TO authenticated
  USING (bucket_id='aset-foto' AND (public.has_role(auth.uid(),'super_admin'::public.app_role) OR public.has_role(auth.uid(),'admin_pemda'::public.app_role) OR public.has_role(auth.uid(),'admin_opd'::public.app_role) OR public.has_role(auth.uid(),'asn'::public.app_role)))
  WITH CHECK (bucket_id='aset-foto' AND (public.has_role(auth.uid(),'super_admin'::public.app_role) OR public.has_role(auth.uid(),'admin_pemda'::public.app_role) OR public.has_role(auth.uid(),'admin_opd'::public.app_role) OR public.has_role(auth.uid(),'asn'::public.app_role)));

DROP POLICY IF EXISTS "absensi_foto_owner_rw" ON storage.objects;

CREATE POLICY "absensi_foto_owner_rw" ON storage.objects FOR ALL TO authenticated
  USING (bucket_id='absensi-foto' AND (storage.foldername(name))[1]=auth.uid()::text)
  WITH CHECK (bucket_id='absensi-foto' AND (storage.foldername(name))[1]=auth.uid()::text);

DROP POLICY IF EXISTS "absensi_foto_admin_read" ON storage.objects;

CREATE POLICY "absensi_foto_admin_read" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id='absensi-foto' AND (public.has_role(auth.uid(),'super_admin'::public.app_role) OR public.has_role(auth.uid(),'admin_pemda'::public.app_role)));

DROP POLICY IF EXISTS "form_submissions_owner_rw" ON storage.objects;

CREATE POLICY "form_submissions_owner_rw" ON storage.objects FOR ALL TO authenticated
  USING (bucket_id='form-submissions' AND (storage.foldername(name))[1]=auth.uid()::text)
  WITH CHECK (bucket_id='form-submissions' AND (storage.foldername(name))[1]=auth.uid()::text);

DROP POLICY IF EXISTS "form_submissions_admin_all" ON storage.objects;

CREATE POLICY "form_submissions_admin_all" ON storage.objects FOR ALL TO authenticated
  USING (bucket_id='form-submissions' AND (public.has_role(auth.uid(),'super_admin'::public.app_role) OR public.has_role(auth.uid(),'admin_pemda'::public.app_role) OR public.has_role(auth.uid(),'admin_opd'::public.app_role)))
  WITH CHECK (bucket_id='form-submissions' AND (public.has_role(auth.uid(),'super_admin'::public.app_role) OR public.has_role(auth.uid(),'admin_pemda'::public.app_role) OR public.has_role(auth.uid(),'admin_opd'::public.app_role)));

DROP POLICY IF EXISTS "bukti_dokumen_admin_all" ON storage.objects;

CREATE POLICY "bukti_dokumen_admin_all" ON storage.objects FOR ALL TO authenticated
  USING (bucket_id='bukti-dokumen' AND (public.has_role(auth.uid(),'super_admin'::public.app_role) OR public.has_role(auth.uid(),'admin_pemda'::public.app_role) OR public.has_role(auth.uid(),'admin_opd'::public.app_role)))
  WITH CHECK (bucket_id='bukti-dokumen' AND (public.has_role(auth.uid(),'super_admin'::public.app_role) OR public.has_role(auth.uid(),'admin_pemda'::public.app_role) OR public.has_role(auth.uid(),'admin_opd'::public.app_role)));

DROP POLICY IF EXISTS "branding_public_read" ON storage.objects;

CREATE POLICY "branding_public_read" ON storage.objects FOR SELECT TO anon, authenticated
  USING (bucket_id='branding');

DROP POLICY IF EXISTS "branding_admin_write" ON storage.objects;

CREATE POLICY "branding_admin_write" ON storage.objects FOR ALL TO authenticated
  USING (bucket_id='branding' AND (public.has_role(auth.uid(),'super_admin'::public.app_role) OR public.has_role(auth.uid(),'admin_pemda'::public.app_role)))
  WITH CHECK (bucket_id='branding' AND (public.has_role(auth.uid(),'super_admin'::public.app_role) OR public.has_role(auth.uid(),'admin_pemda'::public.app_role)));

DROP POLICY IF EXISTS "pejabat_foto_public_read" ON storage.objects;

CREATE POLICY "pejabat_foto_public_read" ON storage.objects FOR SELECT TO anon, authenticated
  USING (bucket_id='pejabat-foto');

DROP POLICY IF EXISTS "pejabat_foto_admin_write" ON storage.objects;

CREATE POLICY "pejabat_foto_admin_write" ON storage.objects FOR ALL TO authenticated
  USING (bucket_id='pejabat-foto' AND (public.has_role(auth.uid(),'super_admin'::public.app_role) OR public.has_role(auth.uid(),'admin_pemda'::public.app_role)))
  WITH CHECK (bucket_id='pejabat-foto' AND (public.has_role(auth.uid(),'super_admin'::public.app_role) OR public.has_role(auth.uid(),'admin_pemda'::public.app_role)));

DO $$
DECLARE
  b text;
  public_buckets text[] := ARRAY['branding','pejabat-foto'];
  private_buckets text[] := ARRAY['berkas-permohonan','aset-foto','absensi-foto','bukti-dokumen','share-files','form-submissions'];
BEGIN
  FOREACH b IN ARRAY (public_buckets || private_buckets) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', b || '_read');
    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', b || '_insert');
    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', b || '_update');
    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', b || '_delete');
  END LOOP;
  FOREACH b IN ARRAY public_buckets LOOP
    EXECUTE format($p$CREATE POLICY %I ON storage.objects FOR SELECT TO anon, authenticated USING (bucket_id = %L)$p$, b || '_read', b);
    EXECUTE format($p$CREATE POLICY %I ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = %L)$p$, b || '_insert', b);
    EXECUTE format($p$CREATE POLICY %I ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = %L) WITH CHECK (bucket_id = %L)$p$, b || '_update', b, b);
    EXECUTE format($p$CREATE POLICY %I ON storage.objects FOR DELETE TO authenticated USING (bucket_id = %L)$p$, b || '_delete', b);
  END LOOP;
  FOREACH b IN ARRAY private_buckets LOOP
    EXECUTE format($p$CREATE POLICY %I ON storage.objects FOR SELECT TO authenticated USING (bucket_id = %L)$p$, b || '_read', b);
    EXECUTE format($p$CREATE POLICY %I ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = %L)$p$, b || '_insert', b);
    EXECUTE format($p$CREATE POLICY %I ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = %L) WITH CHECK (bucket_id = %L)$p$, b || '_update', b, b);
    EXECUTE format($p$CREATE POLICY %I ON storage.objects FOR DELETE TO authenticated USING (bucket_id = %L)$p$, b || '_delete', b);
  END LOOP;
END $$;

DO $$
DECLARE b text;
BEGIN
  FOREACH b IN ARRAY ARRAY['berkas-permohonan','share-files','form-submissions','bukti-dokumen','absensi-foto','aset-foto','pejabat-foto','branding'] LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', 'auth_rw_' || b);
    EXECUTE format(
      'CREATE POLICY %I ON storage.objects FOR ALL TO authenticated USING (bucket_id = %L) WITH CHECK (bucket_id = %L)',
      'auth_rw_' || b, b, b);
  END LOOP;
END $$;
