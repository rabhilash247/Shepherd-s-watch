-- Migration to make sheep fields nullable for Bulk Registration (Progressive Disclosure)

-- Make fields nullable
ALTER TABLE sheep ALTER COLUMN breed DROP NOT NULL;
ALTER TABLE sheep ALTER COLUMN date_of_birth DROP NOT NULL;
ALTER TABLE sheep ALTER COLUMN gender DROP NOT NULL;
ALTER TABLE sheep ALTER COLUMN weight_kg DROP NOT NULL;

-- Add index for performance on bulk operations
CREATE INDEX IF NOT EXISTS idx_sheep_owner_created ON sheep(owner_id, created_at DESC);
