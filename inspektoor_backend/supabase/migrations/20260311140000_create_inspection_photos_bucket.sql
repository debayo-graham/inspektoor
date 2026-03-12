-- Create the inspection-photos storage bucket (public for viewing in reports).
-- Files are organized by org: {org_id}/{inspection_id}/{item_key}/{filename}

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'inspection-photos',
  'inspection-photos',
  true,
  5242880,  -- 5MB per file
  ARRAY['image/jpeg', 'image/png']::text[]
);

-- Upload: restrict to user's own org folder
CREATE POLICY "org_scoped_upload_inspection_photos"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'inspection-photos'
    AND (storage.foldername(name))[1] IN (
      SELECT uo.org_id::text FROM users_orgs uo WHERE uo.user_id = auth.uid()
    )
  );

-- Read: restrict to user's own org folder
CREATE POLICY "org_scoped_read_inspection_photos"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'inspection-photos'
    AND (storage.foldername(name))[1] IN (
      SELECT uo.org_id::text FROM users_orgs uo WHERE uo.user_id = auth.uid()
    )
  );

-- Delete: restrict to user's own org folder (for future cleanup)
CREATE POLICY "org_scoped_delete_inspection_photos"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'inspection-photos'
    AND (storage.foldername(name))[1] IN (
      SELECT uo.org_id::text FROM users_orgs uo WHERE uo.user_id = auth.uid()
    )
  );
