-- ============================================================================
-- Shepherd's Watch Database Schema
-- Migration: Add Production Blockchain Columns
-- ============================================================================

-- 1. Add blockchain-specific columns to health_events
ALTER TABLE public.health_events
ADD COLUMN IF NOT EXISTS blockchain_hash TEXT,
ADD COLUMN IF NOT EXISTS blockchain_tx TEXT;

-- 2. Ensure verified column is consistent
ALTER TABLE public.health_events
ALTER COLUMN verified SET DEFAULT false;

-- 3. Comments for documentation
COMMENT ON COLUMN public.health_events.blockchain_hash IS 'Cryptographic hash stored on the Polygon blockchain';
COMMENT ON COLUMN public.health_events.blockchain_tx IS 'Transaction ID on the Polygon network';
COMMENT ON COLUMN public.health_events.verified IS 'Whether the event has been successfully notarized on blockchain';
