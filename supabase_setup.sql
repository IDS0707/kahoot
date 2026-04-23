-- ============================================================
--  Kahoot Quiz – Supabase Setup
--  Run this entire script in the Supabase SQL Editor once.
--  Dashboard → SQL Editor → New query → paste → Run
-- ============================================================

-- 1. Tables -------------------------------------------------------

CREATE TABLE IF NOT EXISTS game_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  status TEXT NOT NULL DEFAULT 'waiting',          -- waiting | playing | finished
  current_question_index INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS game_players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES game_rooms(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  score INT NOT NULL DEFAULT 0,
  is_host BOOLEAN NOT NULL DEFAULT FALSE,
  joined_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS game_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES game_rooms(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES game_players(id) ON DELETE CASCADE,
  player_name TEXT NOT NULL,
  question_index INT NOT NULL,
  answer_index INT NOT NULL,
  is_correct BOOLEAN NOT NULL,
  points_earned INT NOT NULL DEFAULT 0,
  answered_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (player_id, question_index)
);

CREATE TABLE IF NOT EXISTS game_events (
  id BIGSERIAL PRIMARY KEY,
  room_id UUID NOT NULL REFERENCES game_rooms(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Row Level Security (allow anon access for public game) --------

ALTER TABLE game_rooms   ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_events  ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allow_all" ON game_rooms;
DROP POLICY IF EXISTS "allow_all" ON game_players;
DROP POLICY IF EXISTS "allow_all" ON game_answers;
DROP POLICY IF EXISTS "allow_all" ON game_events;

CREATE POLICY "allow_all" ON game_rooms   FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON game_players FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON game_answers FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON game_events  FOR ALL USING (true) WITH CHECK (true);

-- 3. Enable Realtime on required tables ---------------------------
--    (these tables need to broadcast changes to subscribed clients)

ALTER PUBLICATION supabase_realtime ADD TABLE game_players;
ALTER PUBLICATION supabase_realtime ADD TABLE game_events;
ALTER PUBLICATION supabase_realtime ADD TABLE game_answers;
