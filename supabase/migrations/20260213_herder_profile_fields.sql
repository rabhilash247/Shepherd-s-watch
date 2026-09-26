-- Migration: Robust Herder Profile Fields and Unique ID
-- Village, Location, and Unique 6-digit Herder ID with explicit schema qualifiers

-- 1. Ensure columns exist in public.profiles
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='village') THEN
        ALTER TABLE public.profiles ADD COLUMN village TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='location') THEN
        ALTER TABLE public.profiles ADD COLUMN location TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='herder_id') THEN
        ALTER TABLE public.profiles ADD COLUMN herder_id TEXT UNIQUE;
    END IF;
END $$;

-- 2. Robust ID generation function
CREATE OR REPLACE FUNCTION public.generate_unique_herder_id()
RETURNS TEXT AS $$
DECLARE
    new_id TEXT;
    done BOOLEAN := FALSE;
BEGIN
    WHILE NOT done LOOP
        -- Generate a random 6-digit number as text
        new_id := lpad(floor(random() * 1000000)::text, 6, '0');
        
        -- Check if it exists in public.profiles
        IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE herder_id = new_id) THEN
            done := TRUE;
        END IF;
    END LOOP;
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- 3. Update handle_new_user with secure search_path and explicit qualifiers
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, village, location, herder_id)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'village', ''),
        COALESCE(NEW.raw_user_meta_data->>'location', ''),
        public.generate_unique_herder_id()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Backfill any missing IDs for existing profiles
UPDATE public.profiles SET herder_id = public.generate_unique_herder_id() WHERE herder_id IS NULL;
