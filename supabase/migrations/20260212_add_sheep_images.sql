-- Add image columns to sheep table
ALTER TABLE sheep ADD COLUMN IF NOT EXISTS front_image_url TEXT;
ALTER TABLE sheep ADD COLUMN IF NOT EXISTS back_image_url TEXT;
ALTER TABLE sheep ADD COLUMN IF NOT EXISTS left_image_url TEXT;
ALTER TABLE sheep ADD COLUMN IF NOT EXISTS right_image_url TEXT;

-- Create storage bucket for sheep photos if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('sheep_photos', 'sheep_photos', true)
ON CONFLICT (id) DO NOTHING;

-- Set up RLS for storage (Allow public read, authenticated upload)
BEGIN;
  -- Remove existing policies if any to avoid conflicts
  DROP POLICY IF EXISTS "Public Access" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated Upload" ON storage.objects;
  DROP POLICY IF EXISTS "Owner Update" ON storage.objects;

  -- Create new policies
  CREATE POLICY "Public Access"
  ON storage.objects FOR SELECT
  USING ( bucket_id = 'sheep_photos' );

  CREATE POLICY "Authenticated Upload"
  ON storage.objects FOR INSERT
  WITH CHECK ( bucket_id = 'sheep_photos' AND auth.role() = 'authenticated' );

  CREATE POLICY "Owner Update"
  ON storage.objects FOR UPDATE
  USING ( bucket_id = 'sheep_photos' AND auth.uid() = owner );
COMMIT;
