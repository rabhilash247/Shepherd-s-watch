-- Add qr_code column to sheep table
ALTER TABLE sheep 
ADD COLUMN IF NOT EXISTS qr_code TEXT UNIQUE;

-- Populate existing records with their ID as the default QR code
UPDATE sheep 
SET qr_code = id::text 
WHERE qr_code IS NULL;

-- Make it NOT NULL for future records (optional, but good for consistency)
-- ALTER TABLE sheep ALTER COLUMN qr_code SET NOT NULL;
