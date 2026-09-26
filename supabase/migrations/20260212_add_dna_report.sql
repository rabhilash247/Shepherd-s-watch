-- Add DNA report columns to sheep table
ALTER TABLE sheep 
ADD COLUMN IF NOT EXISTS dna_report_url TEXT,
ADD COLUMN IF NOT EXISTS dna_verified BOOLEAN DEFAULT false;
