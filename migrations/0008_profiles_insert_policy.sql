-- Allow authenticated users to insert their own profile row.
-- Required for upsert to work when the profile doesn't exist yet
-- (e.g. existing users who signed up before the trigger was created,
--  or first-time Google-OAuth users on a fresh install).

DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

CREATE POLICY "Users can insert own profile"
  ON profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);
