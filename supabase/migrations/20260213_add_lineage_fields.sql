-- ============================================================================
-- Shepherd's Watch Database Schema
-- Migration: Add Lineage/Ancestry Fields
-- ============================================================================

-- 1. Add Sire and Dam IDs to sheep table
ALTER TABLE public.sheep
ADD COLUMN IF NOT EXISTS sire_id UUID REFERENCES public.sheep(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS dam_id UUID REFERENCES public.sheep(id) ON DELETE SET NULL;

-- 2. Add indexes for faster ancestry lookups
CREATE INDEX IF NOT EXISTS idx_sheep_sire_id ON public.sheep(sire_id);
CREATE INDEX IF NOT EXISTS idx_sheep_dam_id ON public.sheep(dam_id);

-- 3. Comment for documentation
COMMENT ON COLUMN public.sheep.sire_id IS 'Reference to the biological father (must be a male sheep)';
COMMENT ON COLUMN public.sheep.dam_id IS 'Reference to the biological mother (must be a female sheep)';
