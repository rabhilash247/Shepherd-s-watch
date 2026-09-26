-- ============================================================================
-- Shepherd's Watch Database Schema
-- Migration 003: Functions and Views
-- ============================================================================
-- This migration creates helpful database functions and views for common
-- queries and business logic.
-- ============================================================================

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View: Upcoming Tasks (Due within next 7 days, not completed)
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

-- View: High Risk Sheep (Health score < 60 or risk_level = 'high')
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

-- View: Pregnant Sheep Summary
CREATE OR REPLACE VIEW pregnant_sheep_summary AS
SELECT 
    s.*,
    he.date as pregnancy_confirmed_date,
    he.description as pregnancy_notes
FROM sheep s
LEFT JOIN health_events he ON s.id = he.sheep_id AND he.type = 'pregnancy'
WHERE s.status = 'pregnant'
ORDER BY he.date ASC;

-- View: Recent Health Events (Last 30 days)
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

-- View: Vaccination Schedule (Upcoming vaccinations in next 60 days)
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

-- View: Flock Statistics
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

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function: Calculate Sheep Age in Months
CREATE OR REPLACE FUNCTION get_sheep_age_months(birth_date DATE)
RETURNS INTEGER AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) * 12 + 
           EXTRACT(MONTH FROM AGE(CURRENT_DATE, birth_date));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function: Get Sheep Health Summary
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

-- Function: Auto-calculate Risk Level Based on Health Score
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

-- Function: Update Sheep Risk Level Automatically
CREATE OR REPLACE FUNCTION update_sheep_risk_level()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-update risk level when health score changes
    IF NEW.health_score != OLD.health_score THEN
        NEW.risk_level := calculate_risk_level(NEW.health_score);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto-update risk level on health score change
CREATE TRIGGER trigger_update_sheep_risk_level
    BEFORE UPDATE ON sheep
    FOR EACH ROW
    WHEN (NEW.health_score IS DISTINCT FROM OLD.health_score)
    EXECUTE FUNCTION update_sheep_risk_level();

-- Function: Create Automatic Tasks Based on Events
CREATE OR REPLACE FUNCTION create_auto_task_from_event()
RETURNS TRIGGER AS $$
DECLARE
    sheep_rec RECORD;
    task_title TEXT;
    task_description TEXT;
    task_due_date DATE;
BEGIN
    -- Get sheep information
    SELECT * INTO sheep_rec FROM sheep WHERE id = NEW.sheep_id;
    
    -- Create follow-up tasks based on event type
    IF NEW.type = 'vaccination' THEN
        -- Schedule next vaccination in 6 months
        task_title := 'Vaccination Booster - ' || sheep_rec.name;
        task_description := 'Follow-up vaccination for ' || NEW.title;
        task_due_date := NEW.date + INTERVAL '6 months';
        
        INSERT INTO daily_tasks (title, description, type, sheep_id, sheep_name, due_date, priority, owner_id)
        VALUES (task_title, task_description, 'vaccination', NEW.sheep_id, sheep_rec.name, task_due_date, 'medium', sheep_rec.owner_id);
        
    ELSIF NEW.type = 'deworming' THEN
        -- Schedule next deworming in 3 months
        task_title := 'Deworming - ' || sheep_rec.name;
        task_description := 'Quarterly deworming schedule';
        task_due_date := NEW.date + INTERVAL '3 months';
        
        INSERT INTO daily_tasks (title, description, type, sheep_id, sheep_name, due_date, priority, owner_id)
        VALUES (task_title, task_description, 'deworming', NEW.sheep_id, sheep_rec.name, task_due_date, 'medium', sheep_rec.owner_id);
        
    ELSIF NEW.type = 'illness' THEN
        -- Schedule vet follow-up in 1 week
        task_title := 'Vet Follow-up - ' || sheep_rec.name;
        task_description := 'Follow-up on: ' || NEW.description;
        task_due_date := NEW.date + INTERVAL '1 week';
        
        INSERT INTO daily_tasks (title, description, type, sheep_id, sheep_name, due_date, priority, owner_id)
        VALUES (task_title, task_description, 'vet_followup', NEW.sheep_id, sheep_rec.name, task_due_date, 'high', sheep_rec.owner_id);
        
    ELSIF NEW.type = 'pregnancy' THEN
        -- Schedule lambing watch in 145 days (typical sheep gestation is 145-150 days)
        task_title := 'Lambing Watch - ' || sheep_rec.name;
        task_description := 'Expected lambing date based on confirmed pregnancy';
        task_due_date := NEW.date + INTERVAL '145 days';
        
        INSERT INTO daily_tasks (title, description, type, sheep_id, sheep_name, due_date, priority, owner_id)
        VALUES (task_title, task_description, 'lambing', NEW.sheep_id, sheep_rec.name, task_due_date, 'high', sheep_rec.owner_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Create automatic tasks from health events
CREATE TRIGGER trigger_create_auto_task
    AFTER INSERT ON health_events
    FOR EACH ROW
    EXECUTE FUNCTION create_auto_task_from_event();

-- ============================================================================
-- HELPER FUNCTIONS FOR QUERIES
-- ============================================================================

-- Function: Get Overdue Tasks Count
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

-- Function: Get Health Score Distribution
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

-- ============================================================================
-- END OF MIGRATION 003
-- ============================================================================
