-- Supabase SQL Schema for Pull Up Club
-- This schema matches the Drift database schema defined in workout_database.dart
--
-- DELTA SYNC FIELDS:
--   - updated_at: Automatically updated on every row modification. Use this to query
--     records that have changed since last sync: WHERE updated_at > last_synced_at
--   - deleted_at: For soft deletes. Set to NOW() when deleting instead of hard delete.
--     Query with: WHERE deleted_at IS NULL for active records
--   - last_synced_at: Track when each record was last synced to the client.
--     Useful for tracking sync state per record
--
-- USER ID:
--   - user_id: Foreign key to auth.users(id). Automatically set on insert via trigger.
--     All RLS policies filter by user_id to ensure data isolation.

-- Create workouts table
CREATE TABLE IF NOT EXISTS workouts (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_type TEXT NOT NULL,
  max_groups INTEGER NOT NULL,
  start TIMESTAMPTZ NOT NULL,
  "end" TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Create workout_sets table
CREATE TABLE IF NOT EXISTS workout_sets (
  id SERIAL PRIMARY KEY,
  workout_id INTEGER NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  group_number INTEGER NOT NULL,
  target_reps INTEGER,
  completed_reps INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_workout_sets_workout_id ON workout_sets(workout_id);
CREATE INDEX IF NOT EXISTS idx_workouts_start ON workouts(start DESC);
CREATE INDEX IF NOT EXISTS idx_workouts_user_id ON workouts(user_id);

-- Enable Row Level Security (RLS) - adjust policies as needed for your use case
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sets ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own data
CREATE POLICY "Users can view their own workouts" ON workouts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own workouts" ON workouts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own workouts" ON workouts
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- CREATE POLICY "Users can delete their own workouts" ON workouts
--   FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view sets for their workouts" ON workout_sets
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM workouts WHERE workouts.id = workout_sets.workout_id AND workouts.user_id = auth.uid())
  );

CREATE POLICY "Users can insert sets for their workouts" ON workout_sets
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM workouts WHERE workouts.id = workout_sets.workout_id AND workouts.user_id = auth.uid())
  );

CREATE POLICY "Users can update sets for their workouts" ON workout_sets
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM workouts WHERE workouts.id = workout_sets.workout_id AND workouts.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM workouts WHERE workouts.id = workout_sets.workout_id AND workouts.user_id = auth.uid())
  );

-- CREATE POLICY "Users can delete sets for their workouts" ON workout_sets
--   FOR DELETE USING (
--     EXISTS (SELECT 1 FROM workouts WHERE workouts.id = workout_sets.workout_id AND workouts.user_id = auth.uid())
--   );

-- ============================================================================
-- TRIGGERS
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at on workouts table
CREATE TRIGGER update_workouts_updated_at
  BEFORE UPDATE ON workouts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger to automatically update updated_at on workout_sets table
CREATE TRIGGER update_workout_sets_updated_at
  BEFORE UPDATE ON workout_sets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to update parent workout's updated_at when a set is modified
CREATE OR REPLACE FUNCTION update_parent_workout_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  -- For INSERT and UPDATE, use NEW.workout_id
  -- For DELETE, use OLD.workout_id
  IF TG_OP = 'DELETE' THEN
    UPDATE workouts
    SET updated_at = NOW()
    WHERE id = OLD.workout_id;
    RETURN OLD;
  ELSE
    UPDATE workouts
    SET updated_at = NOW()
    WHERE id = NEW.workout_id;
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update parent workout when a set is inserted
CREATE TRIGGER update_workout_on_set_insert
  AFTER INSERT ON workout_sets
  FOR EACH ROW
  EXECUTE FUNCTION update_parent_workout_timestamp();

-- Trigger to update parent workout when a set is updated
CREATE TRIGGER update_workout_on_set_update
  AFTER UPDATE ON workout_sets
  FOR EACH ROW
  EXECUTE FUNCTION update_parent_workout_timestamp();

-- Trigger to update parent workout when a set is deleted
CREATE TRIGGER update_workout_on_set_delete
  AFTER DELETE ON workout_sets
  FOR EACH ROW
  EXECUTE FUNCTION update_parent_workout_timestamp();

-- Function to automatically set user_id on insert (if not provided)
CREATE OR REPLACE FUNCTION set_user_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.user_id IS NULL THEN
    NEW.user_id = auth.uid();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically set user_id on workouts insert
CREATE TRIGGER set_workouts_user_id
  BEFORE INSERT ON workouts
  FOR EACH ROW
  EXECUTE FUNCTION set_user_id();
