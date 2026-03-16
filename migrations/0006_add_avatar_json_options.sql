-- Migration 0006: Add avatar_json_options column to profiles
-- This stores the Fluttermoji (avatar_maker) JSON options for cross-device sync.
-- Run in Supabase SQL Editor.

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS avatar_json_options text;
