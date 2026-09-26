-- ============================================================================
-- Shepherd's Watch Database Schema
-- Migration 001: Initial Schema
-- ============================================================================
-- This migration creates the core database tables for the Shepherd's Watch
-- sheep farm management application.
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- PROFILES TABLE
-- ============================================================================
-- Stores user profile information linked to Supabase auth.users
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    farm_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for faster email lookups
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

-- ============================================================================
-- SHEEP TABLE
-- ============================================================================
-- Stores individual sheep records with health tracking
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
    
    -- Ensure tag_id is unique per owner
    UNIQUE(owner_id, tag_id)
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_sheep_owner_id ON sheep(owner_id);
CREATE INDEX IF NOT EXISTS idx_sheep_tag_id ON sheep(tag_id);
CREATE INDEX IF NOT EXISTS idx_sheep_status ON sheep(status);
CREATE INDEX IF NOT EXISTS idx_sheep_risk_level ON sheep(risk_level);
CREATE INDEX IF NOT EXISTS idx_sheep_health_score ON sheep(health_score);

-- ============================================================================
-- HEALTH EVENTS TABLE
-- ============================================================================
-- Stores medical history and health-related events for each sheep
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
    hash TEXT, -- For blockchain verification (future feature)
    verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for efficient event queries
CREATE INDEX IF NOT EXISTS idx_health_events_sheep_id ON health_events(sheep_id);
CREATE INDEX IF NOT EXISTS idx_health_events_type ON health_events(type);
CREATE INDEX IF NOT EXISTS idx_health_events_date ON health_events(date DESC);
CREATE INDEX IF NOT EXISTS idx_health_events_verified ON health_events(verified);

-- ============================================================================
-- DAILY TASKS TABLE
-- ============================================================================
-- Stores tasks and reminders for farm management
CREATE TABLE IF NOT EXISTS daily_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN (
        'vaccination', 'vet_followup', 'lambing', 'high_risk', 'deworming'
    )),
    sheep_id UUID NOT NULL REFERENCES sheep(id) ON DELETE CASCADE,
    sheep_name TEXT NOT NULL, -- Denormalized for quick access
    due_date DATE NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT false,
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for task management
CREATE INDEX IF NOT EXISTS idx_daily_tasks_owner_id ON daily_tasks(owner_id);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_sheep_id ON daily_tasks(sheep_id);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_due_date ON daily_tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_completed ON daily_tasks(completed);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_priority ON daily_tasks(priority);

-- ============================================================================
-- AUTOMATIC TIMESTAMP UPDATES
-- ============================================================================
-- Function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger to all tables
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

-- ============================================================================
-- PROFILE AUTO-CREATION
-- ============================================================================
-- Automatically create a profile when a new user signs up
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

-- Trigger to call the function when a new user is created
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- END OF MIGRATION 001
-- ============================================================================
