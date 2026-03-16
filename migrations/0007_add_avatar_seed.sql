-- Migration 0007: add avatar_seed column to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_seed TEXT;
