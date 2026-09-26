-- Optimizing common queries
CREATE INDEX IF NOT EXISTS idx_sheep_owner_id ON public.sheep(owner_id);
CREATE INDEX IF NOT EXISTS idx_dna_analysis_sheep_id ON public.dna_analysis(sheep_id);
CREATE INDEX IF NOT EXISTS idx_health_events_sheep_id ON public.health_events(sheep_id);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_sheep_id ON public.daily_tasks(sheep_id);
