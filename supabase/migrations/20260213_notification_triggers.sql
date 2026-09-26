-- ============================================================================
-- Shepherd's Watch Database Schema
-- Migration: Add Notification Triggers
-- ============================================================================

-- Function to create notification when a sheep's health score drops or risk increases
CREATE OR REPLACE FUNCTION notify_sheep_health_change()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Notify if risk level changes to HIGH
    IF (NEW.risk_level = 'high' AND (OLD.risk_level IS NULL OR OLD.risk_level != 'high')) THEN
        INSERT INTO public.notifications (user_id, title, message, type, link)
        VALUES (
            NEW.owner_id,
            '🚨 High Risk Alert',
            'Sheep "' || NEW.name || '" (' || NEW.tag_id || ') has been flagged as HIGH RISK. Immediate inspection recommended.',
            'health_alert',
            '/sheep/' || NEW.id
        );
    END IF;

    -- 2. Notify if health score drops by 10 or more points
    IF (OLD.health_score IS NOT NULL AND (OLD.health_score - NEW.health_score) >= 10) THEN
        INSERT INTO public.notifications (user_id, title, message, type, link)
        VALUES (
            NEW.owner_id,
            '📉 Health Score Drop',
            'Sheep "' || NEW.name || '" health score dropped to ' || NEW.health_score || '. Recent events may need review.',
            'health_alert',
            '/sheep/' || NEW.id
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for sheep table
DROP TRIGGER IF EXISTS tr_sheep_health_notification ON public.sheep;
CREATE TRIGGER tr_sheep_health_notification
    AFTER UPDATE ON public.sheep
    FOR EACH ROW
    EXECUTE FUNCTION notify_sheep_health_change();

-- Function to notify when a task is due (can be triggered by an insert or update)
CREATE OR REPLACE FUNCTION notify_task_due()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify on new high-priority tasks
    IF (TG_OP = 'INSERT' AND NEW.priority = 'high') THEN
        INSERT INTO public.notifications (user_id, title, message, type, link)
        VALUES (
            NEW.owner_id,
            '⚠️ New Urgent Task',
            'Urgent task assigned: "' || NEW.title || '" for sheep ' || NEW.sheep_name,
            'task_reminder',
            '/tasks'
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for daily_tasks table
DROP TRIGGER IF EXISTS tr_task_notification ON public.daily_tasks;
CREATE TRIGGER tr_task_notification
    AFTER INSERT ON public.daily_tasks
    FOR EACH ROW
    EXECUTE FUNCTION notify_task_due();
