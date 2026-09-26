# Complete Database Setup - All SQL Queries

This file contains all SQL queries needed to set up the Shepherd's Watch database in Supabase. You can run these in the Supabase SQL Editor.

## Instructions

1. Go to your Supabase project dashboard
2. Click on **SQL Editor** in the sidebar
3. Copy and paste each migration below (in order)
4. Click **Run** for each one

---

## Migration 001: Initial Schema

```sql
-- ============================================================================
-- Shepherd's Watch Database Schema
-- Migration 001: Initial Schema
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- PROFILES TABLE
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    farm_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

-- SHEEP TABLE
CREATE TABLE IF NOT EXISTS sheep (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tag_id TEXT NOT NULL,
    name TEXT NOT NULL,
    breed TEXT NOT NULL,
    date_of_birth DATE NOT NULL,
    gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
    weight_kg NUMERIC(6,2) NOT NULL CHECK (weight_kg > 0),
    health_score INTEGER NOT NULL DEFAULT 100 CHECK (health_score >= 0 AND health_score <= 100),
    risk_level TEXT NOT NULL DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high')),
    status TEXT NOT NULL DEFAULT 'healthy' CHECK (status IN ('healthy', 'sick', 'pregnant', 'lactating')),
    image_url TEXT,
    owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(owner_id, tag_id)
);

CREATE INDEX IF NOT EXISTS idx_sheep_owner_id ON sheep(owner_id);
CREATE INDEX IF NOT EXISTS idx_sheep_tag_id ON sheep(tag_id);
CREATE INDEX IF NOT EXISTS idx_sheep_status ON sheep(status);
CREATE INDEX IF NOT EXISTS idx_sheep_risk_level ON sheep(risk_level);
CREATE INDEX IF NOT EXISTS idx_sheep_health_score ON sheep(health_score);

-- HEALTH EVENTS TABLE
CREATE TABLE IF NOT EXISTS health_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sheep_id UUID NOT NULL REFERENCES sheep(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN (
        'birth', 'vaccination', 'deworming', 'illness', 
        'pregnancy', 'lambing', 'vet_visit', 'sale', 'weight_check'
    )),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    date DATE NOT NULL,
    administered_by TEXT,
    hash TEXT,
    verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_health_events_sheep_id ON health_events(sheep_id);
CREATE INDEX IF NOT EXISTS idx_health_events_type ON health_events(type);
CREATE INDEX IF NOT EXISTS idx_health_events_date ON health_events(date DESC);
CREATE INDEX IF NOT EXISTS idx_health_events_verified ON health_events(verified);

-- DAILY TASKS TABLE
CREATE TABLE IF NOT EXISTS daily_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN (
        'vaccination', 'vet_followup', 'lambing', 'high_risk', 'deworming'
    )),
    sheep_id UUID NOT NULL REFERENCES sheep(id) ON DELETE CASCADE,
    sheep_name TEXT NOT NULL,
    due_date DATE NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT false,
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_daily_tasks_owner_id ON daily_tasks(owner_id);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_sheep_id ON daily_tasks(sheep_id);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_due_date ON daily_tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_completed ON daily_tasks(completed);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_priority ON daily_tasks(priority);

-- AUTOMATIC TIMESTAMP UPDATES
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sheep_updated_at
    BEFORE UPDATE ON sheep
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_health_events_updated_at
    BEFORE UPDATE ON health_events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_tasks_updated_at
    BEFORE UPDATE ON daily_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- PROFILE AUTO-CREATION
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();
```

---

## Migration 002: Row Level Security

```sql
-- ============================================================================
-- Shepherd's Watch Database Schema
-- Migration 002: Row Level Security (RLS) Policies
-- ============================================================================

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE sheep ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_tasks ENABLE ROW LEVEL SECURITY;

-- PROFILES POLICIES
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- SHEEP POLICIES
CREATE POLICY "Users can view own sheep"
    ON sheep FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can insert own sheep"
    ON sheep FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own sheep"
    ON sheep FOR UPDATE
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can delete own sheep"
    ON sheep FOR DELETE
    USING (auth.uid() = owner_id);

-- HEALTH EVENTS POLICIES
CREATE POLICY "Users can view health events for own sheep"
    ON health_events FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM sheep
            WHERE sheep.id = health_events.sheep_id
            AND sheep.owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert health events for own sheep"
    ON health_events FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM sheep
            WHERE sheep.id = health_events.sheep_id
            AND sheep.owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can update health events for own sheep"
    ON health_events FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM sheep
            WHERE sheep.id = health_events.sheep_id
            AND sheep.owner_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM sheep
            WHERE sheep.id = health_events.sheep_id
            AND sheep.owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete health events for own sheep"
    ON health_events FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM sheep
            WHERE sheep.id = health_events.sheep_id
            AND sheep.owner_id = auth.uid()
        )
    );

-- DAILY TASKS POLICIES
CREATE POLICY "Users can view own tasks"
    ON daily_tasks FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can insert own tasks"
    ON daily_tasks FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own tasks"
    ON daily_tasks FOR UPDATE
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can delete own tasks"
    ON daily_tasks FOR DELETE
    USING (auth.uid() = owner_id);
```

---

## Migration 003: Functions and Views

```sql
-- ============================================================================
-- Shepherd's Watch Database Schema
-- Migration 003: Functions and Views
-- ============================================================================

-- VIEW: Upcoming Tasks
CREATE OR REPLACE VIEW upcoming_tasks AS
SELECT 
    dt.*,
    s.breed,
    s.health_score,
    s.risk_level
FROM daily_tasks dt
JOIN sheep s ON dt.sheep_id = s.id
WHERE dt.completed = false
  AND dt.due_date <= CURRENT_DATE + INTERVAL '7 days'
ORDER BY dt.due_date ASC, dt.priority DESC;

-- VIEW: High Risk Sheep
CREATE OR REPLACE VIEW high_risk_sheep AS
SELECT 
    s.*,
    COUNT(he.id) as total_health_events,
    MAX(he.date) as last_health_event_date
FROM sheep s
LEFT JOIN health_events he ON s.id = he.sheep_id
WHERE s.health_score < 60 OR s.risk_level = 'high'
GROUP BY s.id
ORDER BY s.health_score ASC, s.risk_level DESC;

-- VIEW: Pregnant Sheep Summary
CREATE OR REPLACE VIEW pregnant_sheep_summary AS
SELECT 
    s.*,
    he.date as pregnancy_confirmed_date,
    he.description as pregnancy_notes
FROM sheep s
LEFT JOIN health_events he ON s.id = he.sheep_id AND he.type = 'pregnancy'
WHERE s.status = 'pregnant'
ORDER BY he.date ASC;

-- VIEW: Recent Health Events
CREATE OR REPLACE VIEW recent_health_events AS
SELECT 
    he.*,
    s.tag_id,
    s.name as sheep_name,
    s.breed
FROM health_events he
JOIN sheep s ON he.sheep_id = s.id
WHERE he.date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY he.date DESC;

-- VIEW: Vaccination Schedule
CREATE OR REPLACE VIEW vaccination_schedule AS
SELECT 
    dt.*,
    s.tag_id,
    s.breed,
    s.health_score
FROM daily_tasks dt
JOIN sheep s ON dt.sheep_id = s.id
WHERE dt.type = 'vaccination'
  AND dt.completed = false
  AND dt.due_date <= CURRENT_DATE + INTERVAL '60 days'
ORDER BY dt.due_date ASC;

-- VIEW: Flock Statistics
CREATE OR REPLACE VIEW flock_statistics AS
SELECT 
    owner_id,
    COUNT(*) as total_sheep,
    COUNT(*) FILTER (WHERE gender = 'male') as total_males,
    COUNT(*) FILTER (WHERE gender = 'female') as total_females,
    COUNT(*) FILTER (WHERE status = 'pregnant') as total_pregnant,
    COUNT(*) FILTER (WHERE status = 'sick') as total_sick,
    COUNT(*) FILTER (WHERE status = 'lactating') as total_lactating,
    COUNT(*) FILTER (WHERE risk_level = 'high') as high_risk_count,
    COUNT(*) FILTER (WHERE risk_level = 'medium') as medium_risk_count,
    COUNT(*) FILTER (WHERE risk_level = 'low') as low_risk_count,
    ROUND(AVG(health_score), 2) as average_health_score,
    ROUND(AVG(weight_kg), 2) as average_weight,
    MIN(date_of_birth) as oldest_sheep_dob,
    MAX(date_of_birth) as youngest_sheep_dob
FROM sheep
GROUP BY owner_id;

-- FUNCTION: Calculate Sheep Age
CREATE OR REPLACE FUNCTION get_sheep_age_months(birth_date DATE)
RETURNS INTEGER AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) * 12 + 
           EXTRACT(MONTH FROM AGE(CURRENT_DATE, birth_date));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- FUNCTION: Get Sheep Health Summary
CREATE OR REPLACE FUNCTION get_sheep_health_summary(sheep_uuid UUID)
RETURNS TABLE (
    sheep_id UUID,
    sheep_name TEXT,
    total_events INTEGER,
    last_vaccination_date DATE,
    last_deworming_date DATE,
    last_vet_visit_date DATE,
    illness_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id as sheep_id,
        s.name as sheep_name,
        COUNT(he.id)::INTEGER as total_events,
        MAX(he.date) FILTER (WHERE he.type = 'vaccination') as last_vaccination_date,
        MAX(he.date) FILTER (WHERE he.type = 'deworming') as last_deworming_date,
        MAX(he.date) FILTER (WHERE he.type = 'vet_visit') as last_vet_visit_date,
        COUNT(he.id) FILTER (WHERE he.type = 'illness')::INTEGER as illness_count
    FROM sheep s
    LEFT JOIN health_events he ON s.id = he.sheep_id
    WHERE s.id = sheep_uuid
    GROUP BY s.id, s.name;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Auto-calculate Risk Level
CREATE OR REPLACE FUNCTION calculate_risk_level(health_score_value INTEGER)
RETURNS TEXT AS $$
BEGIN
    IF health_score_value >= 80 THEN
        RETURN 'low';
    ELSIF health_score_value >= 50 THEN
        RETURN 'medium';
    ELSE
        RETURN 'high';
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- FUNCTION: Update Risk Level Automatically
CREATE OR REPLACE FUNCTION update_sheep_risk_level()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.health_score != OLD.health_score THEN
        NEW.risk_level := calculate_risk_level(NEW.health_score);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_sheep_risk_level
    BEFORE UPDATE ON sheep
    FOR EACH ROW
    WHEN (NEW.health_score IS DISTINCT FROM OLD.health_score)
    EXECUTE FUNCTION update_sheep_risk_level();

-- FUNCTION: Create Automatic Tasks
CREATE OR REPLACE FUNCTION create_auto_task_from_event()
RETURNS TRIGGER AS $$
DECLARE
    sheep_rec RECORD;
    task_title TEXT;
    task_description TEXT;
    task_due_date DATE;
BEGIN
    SELECT * INTO sheep_rec FROM sheep WHERE id = NEW.sheep_id;
    
    IF NEW.type = 'vaccination' THEN
        task_title := 'Vaccination Booster - ' || sheep_rec.name;
        task_description := 'Follow-up vaccination for ' || NEW.title;
        task_due_date := NEW.date + INTERVAL '6 months';
        
        INSERT INTO daily_tasks (title, description, type, sheep_id, sheep_name, due_date, priority, owner_id)
        VALUES (task_title, task_description, 'vaccination', NEW.sheep_id, sheep_rec.name, task_due_date, 'medium', sheep_rec.owner_id);
        
    ELSIF NEW.type = 'deworming' THEN
        task_title := 'Deworming - ' || sheep_rec.name;
        task_description := 'Quarterly deworming schedule';
        task_due_date := NEW.date + INTERVAL '3 months';
        
        INSERT INTO daily_tasks (title, description, type, sheep_id, sheep_name, due_date, priority, owner_id)
        VALUES (task_title, task_description, 'deworming', NEW.sheep_id, sheep_rec.name, task_due_date, 'medium', sheep_rec.owner_id);
        
    ELSIF NEW.type = 'illness' THEN
        task_title := 'Vet Follow-up - ' || sheep_rec.name;
        task_description := 'Follow-up on: ' || NEW.description;
        task_due_date := NEW.date + INTERVAL '1 week';
        
        INSERT INTO daily_tasks (title, description, type, sheep_id, sheep_name, due_date, priority, owner_id)
        VALUES (task_title, task_description, 'vet_followup', NEW.sheep_id, sheep_rec.name, task_due_date, 'high', sheep_rec.owner_id);
        
    ELSIF NEW.type = 'pregnancy' THEN
        task_title := 'Lambing Watch - ' || sheep_rec.name;
        task_description := 'Expected lambing date based on confirmed pregnancy';
        task_due_date := NEW.date + INTERVAL '145 days';
        
        INSERT INTO daily_tasks (title, description, type, sheep_id, sheep_name, due_date, priority, owner_id)
        VALUES (task_title, task_description, 'lambing', NEW.sheep_id, sheep_rec.name, task_due_date, 'high', sheep_rec.owner_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_auto_task
    AFTER INSERT ON health_events
    FOR EACH ROW
    EXECUTE FUNCTION create_auto_task_from_event();

-- FUNCTION: Get Overdue Tasks Count
CREATE OR REPLACE FUNCTION get_overdue_tasks_count(user_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM daily_tasks
        WHERE owner_id = user_uuid
          AND completed = false
          AND due_date < CURRENT_DATE
    );
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Get Health Score Distribution
CREATE OR REPLACE FUNCTION get_health_score_distribution(user_uuid UUID)
RETURNS TABLE (
    score_range TEXT,
    count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN health_score >= 80 THEN 'Excellent (80+)'
            WHEN health_score >= 60 THEN 'Good (60-79)'
            WHEN health_score >= 40 THEN 'Moderate (40-59)'
            ELSE 'At Risk (<40)'
        END as score_range,
        COUNT(*) as count
    FROM sheep
    WHERE owner_id = user_uuid
    GROUP BY score_range
    ORDER BY 
        CASE score_range
            WHEN 'Excellent (80+)' THEN 1
            WHEN 'Good (60-79)' THEN 2
            WHEN 'Moderate (40-59)' THEN 3
            WHEN 'At Risk (<40)' THEN 4
        END;
END;
$$ LANGUAGE plpgsql;
```

---

## Verification Queries

After running all migrations, run these to verify everything is set up correctly:

```sql
-- Check all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Verify RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- Check all policies
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Check all views
SELECT table_name 
FROM information_schema.views 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Check all functions
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public'
ORDER BY routine_name;
```

---

**All set! Your database is ready for use.** 🐑
