-- GPS tracking is linked to the existing sheep record. It does not create or
-- replace a QR identity. Device ingestion can later write through a service role.

CREATE TABLE IF NOT EXISTS public.gps_trackers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sheep_id UUID NOT NULL UNIQUE REFERENCES public.sheep(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL UNIQUE,
    battery_percentage INTEGER NOT NULL DEFAULT 100 CHECK (battery_percentage BETWEEN 0 AND 100),
    connection_status TEXT NOT NULL DEFAULT 'offline' CHECK (connection_status IN ('online', 'offline')),
    last_communication_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.gps_latest_locations (
    tracker_id UUID PRIMARY KEY REFERENCES public.gps_trackers(id) ON DELETE CASCADE,
    sheep_id UUID NOT NULL UNIQUE REFERENCES public.sheep(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    accuracy_meters DOUBLE PRECISION NOT NULL CHECK (accuracy_meters >= 0),
    recorded_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.gps_location_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tracker_id UUID NOT NULL REFERENCES public.gps_trackers(id) ON DELETE CASCADE,
    sheep_id UUID NOT NULL REFERENCES public.sheep(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    accuracy_meters DOUBLE PRECISION NOT NULL CHECK (accuracy_meters >= 0),
    recorded_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.gps_search_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sheep_id UUID NOT NULL UNIQUE REFERENCES public.sheep(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    radius_km INTEGER NOT NULL DEFAULT 5 CHECK (radius_km IN (5, 6)),
    center_latitude DOUBLE PRECISION NOT NULL CHECK (center_latitude BETWEEN -90 AND 90),
    center_longitude DOUBLE PRECISION NOT NULL CHECK (center_longitude BETWEEN -180 AND 180),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.gps_geofence_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sheep_id UUID NOT NULL REFERENCES public.sheep(id) ON DELETE CASCADE,
    tracker_id UUID NOT NULL REFERENCES public.gps_trackers(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN ('live', 'near_boundary', 'outside', 'connection_lost', 'found')),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    distance_km DOUBLE PRECISION,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_gps_history_sheep_recorded_at ON public.gps_location_history(sheep_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_gps_events_sheep_occurred_at ON public.gps_geofence_events(sheep_id, occurred_at DESC);

CREATE TRIGGER update_gps_trackers_updated_at BEFORE UPDATE ON public.gps_trackers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_gps_latest_locations_updated_at BEFORE UPDATE ON public.gps_latest_locations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE public.gps_trackers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gps_latest_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gps_location_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gps_search_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gps_geofence_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view trackers for own sheep" ON public.gps_trackers FOR SELECT USING (EXISTS (SELECT 1 FROM public.sheep WHERE sheep.id = gps_trackers.sheep_id AND sheep.owner_id = auth.uid()));
CREATE POLICY "Users can manage trackers for own sheep" ON public.gps_trackers FOR ALL USING (EXISTS (SELECT 1 FROM public.sheep WHERE sheep.id = gps_trackers.sheep_id AND sheep.owner_id = auth.uid())) WITH CHECK (EXISTS (SELECT 1 FROM public.sheep WHERE sheep.id = gps_trackers.sheep_id AND sheep.owner_id = auth.uid()));
CREATE POLICY "Users can view latest GPS for own sheep" ON public.gps_latest_locations FOR SELECT USING (EXISTS (SELECT 1 FROM public.sheep WHERE sheep.id = gps_latest_locations.sheep_id AND sheep.owner_id = auth.uid()));
CREATE POLICY "Users can manage latest GPS for own sheep" ON public.gps_latest_locations FOR ALL USING (EXISTS (SELECT 1 FROM public.sheep WHERE sheep.id = gps_latest_locations.sheep_id AND sheep.owner_id = auth.uid())) WITH CHECK (EXISTS (SELECT 1 FROM public.sheep WHERE sheep.id = gps_latest_locations.sheep_id AND sheep.owner_id = auth.uid()));
CREATE POLICY "Users can view GPS history for own sheep" ON public.gps_location_history FOR SELECT USING (EXISTS (SELECT 1 FROM public.sheep WHERE sheep.id = gps_location_history.sheep_id AND sheep.owner_id = auth.uid()));
CREATE POLICY "Users can manage GPS history for own sheep" ON public.gps_location_history FOR ALL USING (EXISTS (SELECT 1 FROM public.sheep WHERE sheep.id = gps_location_history.sheep_id AND sheep.owner_id = auth.uid())) WITH CHECK (EXISTS (SELECT 1 FROM public.sheep WHERE sheep.id = gps_location_history.sheep_id AND sheep.owner_id = auth.uid()));
CREATE POLICY "Users can manage own GPS search settings" ON public.gps_search_settings FOR ALL USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Users can view own geofence events" ON public.gps_geofence_events FOR SELECT USING (auth.uid() = owner_id);
CREATE POLICY "Users can insert own geofence events" ON public.gps_geofence_events FOR INSERT WITH CHECK (auth.uid() = owner_id);