DROP POLICY IF EXISTS signatures_owner_all ON storage.objects;
CREATE POLICY signatures_owner_all ON storage.objects FOR ALL TO authenticated
  USING (bucket_id = 'signatures' AND (auth.uid()::text = (storage.foldername(name))[1] OR public.has_role(auth.uid(),'super_admin')))
  WITH CHECK (bucket_id = 'signatures' AND (auth.uid()::text = (storage.foldername(name))[1] OR public.has_role(auth.uid(),'super_admin')));