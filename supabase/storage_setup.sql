-- ============================================
-- STORAGE SETUP FOR ZAD ALDAIA
-- Run this AFTER creating the 'images' bucket in Supabase Dashboard
-- ============================================

-- STEP 1: First, create the bucket manually in Supabase Dashboard:
-- 1. Go to Supabase Dashboard → Storage
-- 2. Click "New bucket"
-- 3. Name it: images
-- 4. Check "Public bucket"
-- 5. Click "Create bucket"

-- STEP 2: Then run this SQL to set up storage policies

-- Allow authenticated users to upload images
CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'images');

-- Allow authenticated users to update their images
CREATE POLICY "Authenticated users can update images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'images');

-- Allow authenticated users to delete images
CREATE POLICY "Authenticated users can delete images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'images');

-- Allow public read access to images
CREATE POLICY "Public can view images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'images');

-- ============================================
-- DONE! Storage is now configured
-- ============================================

-- Verify policies were created
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';
