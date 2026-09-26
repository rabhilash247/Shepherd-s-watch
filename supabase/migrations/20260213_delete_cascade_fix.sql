-- 1. Fix circular reference for sheep deletion
-- Drop the existing constraint if it exists (Supabase naming convention varies, but it usually matches the column name)
DO $$ 
BEGIN
    ALTER TABLE public.sheep DROP CONSTRAINT IF EXISTS sheep_latest_analysis_id_fkey;
EXCEPTION
    WHEN undefined_object THEN null;
END $$;

ALTER TABLE public.sheep
ADD CONSTRAINT sheep_latest_analysis_id_fkey 
FOREIGN KEY (latest_analysis_id) 
REFERENCES dna_analysis(id) 
ON DELETE SET NULL;

-- 2. Setup Storage Buckets for animal images and reports
INSERT INTO storage.buckets (id, name, public)
VALUES ('sheep-images', 'sheep-images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('dna-reports', 'dna-reports', true)
ON CONFLICT (id) DO NOTHING;

-- 3. RLS Policies for Buckets (Allow authenticated owners to manage their files)
-- These are standard bucket policies
CREATE POLICY "Public Read Access" ON storage.objects FOR SELECT USING (bucket_id IN ('sheep-images', 'dna-reports'));
CREATE POLICY "Authenticated Upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id IN ('sheep-images', 'dna-reports') AND auth.role() = 'authenticated');
CREATE POLICY "Owner Delete Access" ON storage.objects FOR DELETE USING (bucket_id IN ('sheep-images', 'dna-reports') AND auth.role() = 'authenticated');
