-- ============================================================
-- Migration 0003: Add unit to tasks, slogan+avatar to profiles
-- ============================================================
SET search_path = public;

-- 1. Add unit column to tasks
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS unit text;

-- 2. Add profile enhancement columns
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS slogan text DEFAULT '';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_emoji text DEFAULT '🦊';

-- 3. Record migration
INSERT INTO schema_migrations (version, description)
VALUES ('0003', 'Add unit to tasks, slogan+avatar to profiles')
ON CONFLICT (version) DO NOTHING;
