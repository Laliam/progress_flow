-- ============================================================
-- Migration 0002: Public challenges + schema_migrations table
-- ============================================================

SET search_path = public;

-- 1. Schema migration tracking table
-- Apply once; safe to run repeatedly via IF NOT EXISTS.
CREATE TABLE IF NOT EXISTS schema_migrations (
  version     text        PRIMARY KEY,
  description text,
  applied_at  timestamptz DEFAULT now()
);

-- 2. Add is_public column to tasks
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS is_public boolean NOT NULL DEFAULT false;

-- 3. Update tasks SELECT policy to expose public group challenges to all
--    authenticated users (no invite code needed to discover them).
DROP POLICY IF EXISTS "Users can see tasks they created or participate in" ON tasks;
CREATE POLICY "Users can see tasks they are authorized to see" ON tasks
  FOR SELECT USING (
    auth.uid() = creator_id
    OR id IN (
      SELECT task_id FROM task_participants WHERE user_id = auth.uid()
    )
    OR (is_public = true AND is_group_task = true)
  );

-- 4. Record this migration
INSERT INTO schema_migrations (version, description)
VALUES ('0002', 'Public challenges + schema_migrations table')
ON CONFLICT (version) DO NOTHING;
