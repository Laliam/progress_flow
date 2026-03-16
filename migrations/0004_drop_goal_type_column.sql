-- ============================================================
-- Migration 0004: Drop obsolete goal_type column from tasks
-- ============================================================
-- goal_type (NOT NULL) was the original schema design but was
-- replaced by the free-form `unit` column (migration 0003).
-- The app code never inserts goal_type, so every task INSERT
-- fails with a NOT NULL constraint violation.
-- ============================================================

SET search_path = public;

-- Drop the obsolete column (data loss is intentional — it was never used by the app)
ALTER TABLE tasks DROP COLUMN IF EXISTS goal_type;

-- Record this migration
INSERT INTO schema_migrations (version, description)
VALUES ('0004', 'Drop obsolete goal_type column from tasks')
ON CONFLICT (version) DO NOTHING;
