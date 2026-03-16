-- 1. Setup Schema and Extensions
SET search_path = public;
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Profiles Table (Linked to Auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text UNIQUE,
  full_name text,
  avatar_url text,
  created_at timestamptz DEFAULT now()
);

-- 3. Tasks Table
CREATE TABLE IF NOT EXISTS tasks (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  creator_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  goal_type text NOT NULL,
  total_goal_value numeric NOT NULL,
  current_value numeric DEFAULT 0,
  priority text,
  is_group_task boolean DEFAULT false,
  deadline timestamptz,
  created_at timestamptz DEFAULT now()
);

-- 4. Task Participants Table
CREATE TABLE IF NOT EXISTS task_participants (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  task_id uuid NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  joined_at timestamptz DEFAULT now(),
  UNIQUE (user_id, task_id)
);

-- 5. Task Invites Table
CREATE TABLE IF NOT EXISTS task_invites (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  code text NOT NULL UNIQUE,
  task_id uuid NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  inviter_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

-- 6. Progress Logs Table
CREATE TABLE IF NOT EXISTS progress_logs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id uuid NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  value_added numeric NOT NULL,
  created_at timestamptz DEFAULT now()
);

--- SECURITY CONFIGURATION (RLS) ---

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_logs ENABLE ROW LEVEL SECURITY;

-- Helper to drop policies before recreating (Postgres doesn't have CREATE OR REPLACE POLICY)
DO $$ 
BEGIN
    -- Profiles
    DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
    DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
    
    -- Tasks
    DROP POLICY IF EXISTS "Users can see tasks they created or participate in" ON tasks;
    DROP POLICY IF EXISTS "Creators can insert tasks" ON tasks;
    DROP POLICY IF EXISTS "Creators can update tasks" ON tasks;
    DROP POLICY IF EXISTS "Creators can delete tasks" ON tasks;
    
    -- Participants
    DROP POLICY IF EXISTS "View participants" ON task_participants;
    DROP POLICY IF EXISTS "Users can join tasks" ON task_participants;
    
    -- Invites
    DROP POLICY IF EXISTS "Anyone can view invites" ON task_invites;
    DROP POLICY IF EXISTS "Users can create invites" ON task_invites;
    
    -- Logs
    DROP POLICY IF EXISTS "Insert logs" ON progress_logs;
    DROP POLICY IF EXISTS "Select logs" ON progress_logs;
EXCEPTION
    WHEN undefined_object THEN null;
END $$;

-- Profiles Policies
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Tasks Policies
CREATE POLICY "Users can see tasks they created or participate in" ON tasks
  FOR SELECT USING (
    auth.uid() = creator_id OR 
    id IN (SELECT task_id FROM task_participants WHERE user_id = auth.uid())
  );
CREATE POLICY "Creators can insert tasks" ON tasks FOR INSERT WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "Creators can update tasks" ON tasks FOR UPDATE USING (auth.uid() = creator_id) WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "Creators can delete tasks" ON tasks FOR DELETE USING (auth.uid() = creator_id);

-- Participants Policies
CREATE POLICY "View participants" ON task_participants FOR SELECT USING (true);
CREATE POLICY "Users can join tasks" ON task_participants FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Invites Policies
CREATE POLICY "Anyone can view invites" ON task_invites FOR SELECT USING (true);
CREATE POLICY "Users can create invites" ON task_invites FOR INSERT WITH CHECK (auth.uid() = inviter_id);

-- Logs Policies
CREATE POLICY "Insert logs" ON progress_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Select logs" ON progress_logs FOR SELECT USING (auth.uid() = user_id);

--- FUNCTIONS AND VIEWS ---

-- Aggregate progress view
CREATE OR REPLACE VIEW task_participants_view AS
SELECT
  tp.user_id,
  tp.task_id,
  p.username,
  LEAST(1.0, COALESCE(SUM(pl.value_added), 0) / NULLIF(t.total_goal_value, 0))::double precision AS completion_percent
FROM task_participants tp
JOIN tasks t ON t.id = tp.task_id
LEFT JOIN profiles p ON p.id = tp.user_id
LEFT JOIN progress_logs pl ON pl.task_id = tp.task_id AND pl.user_id = tp.user_id
GROUP BY tp.user_id, tp.task_id, p.username, t.total_goal_value;

-- Progress increment function
CREATE OR REPLACE FUNCTION increment_task_progress(p_task_id uuid, p_delta numeric)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE tasks
  SET current_value = LEAST(total_goal_value, COALESCE(current_value,0) + p_delta)
  WHERE id = p_task_id;
END;
$$;

--- AUTOMATIC PROFILE CREATION ON SIGNUP ---
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();