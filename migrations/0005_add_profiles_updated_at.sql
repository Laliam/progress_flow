-- ============================================================
-- Migration 0005: Add updated_at to profiles
-- ============================================================
-- profile_repository upsert() sends updated_at but the column
-- didn't exist, so every profile save failed silently — that's
-- why avatars were never persisted.
-- ============================================================

SET search_path = public;

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

INSERT INTO schema_migrations (version, description)
VALUES ('0005', 'Add updated_at to profiles table')
ON CONFLICT (version) DO NOTHING;
