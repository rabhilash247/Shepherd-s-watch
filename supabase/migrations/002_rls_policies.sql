-- ============================================================================
-- Shepherd's Watch Database Schema
-- Migration 002: Row Level Security (RLS) Policies
-- ============================================================================
-- This migration enables Row Level Security and creates policies to ensure
-- users can only access their own data.
-- ============================================================================

-- ============================================================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE sheep ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_tasks ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PROFILES TABLE POLICIES
-- ============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- Users can insert their own profile (handled by trigger, but allowing for manual inserts)
CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ============================================================================
-- SHEEP TABLE POLICIES
-- ============================================================================

-- Users can view their own sheep
CREATE POLICY "Users can view own sheep"
    ON sheep FOR SELECT
    USING (auth.uid() = owner_id);

-- Users can insert sheep for themselves
CREATE POLICY "Users can insert own sheep"
    ON sheep FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

-- Users can update their own sheep
CREATE POLICY "Users can update own sheep"
    ON sheep FOR UPDATE
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- Users can delete their own sheep
CREATE POLICY "Users can delete own sheep"
    ON sheep FOR DELETE
    USING (auth.uid() = owner_id);

-- ============================================================================
-- HEALTH EVENTS TABLE POLICIES
-- ============================================================================

-- Users can view health events for their own sheep
CREATE POLICY "Users can view health events for own sheep"
    ON health_events FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM sheep
            WHERE sheep.id = health_events.sheep_id
            AND sheep.owner_id = auth.uid()
        )
    );

-- Users can insert health events for their own sheep
CREATE POLICY "Users can insert health events for own sheep"
    ON health_events FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM sheep
            WHERE sheep.id = health_events.sheep_id
            AND sheep.owner_id = auth.uid()
        )
    );

-- Users can update health events for their own sheep
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

-- Users can delete health events for their own sheep
CREATE POLICY "Users can delete health events for own sheep"
    ON health_events FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM sheep
            WHERE sheep.id = health_events.sheep_id
            AND sheep.owner_id = auth.uid()
        )
    );

-- ============================================================================
-- DAILY TASKS TABLE POLICIES
-- ============================================================================

-- Users can view their own tasks
CREATE POLICY "Users can view own tasks"
    ON daily_tasks FOR SELECT
    USING (auth.uid() = owner_id);

-- Users can insert their own tasks
CREATE POLICY "Users can insert own tasks"
    ON daily_tasks FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

-- Users can update their own tasks
CREATE POLICY "Users can update own tasks"
    ON daily_tasks FOR UPDATE
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- Users can delete their own tasks
CREATE POLICY "Users can delete own tasks"
    ON daily_tasks FOR DELETE
    USING (auth.uid() = owner_id);

-- ============================================================================
-- END OF MIGRATION 002
-- ============================================================================
