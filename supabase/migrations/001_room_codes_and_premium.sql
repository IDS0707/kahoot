-- ============================================================
--  Faza 1 migration — adds room codes & premium foundations.
--  Run this AFTER `supabase_setup.sql`.
--  Idempotent: safe to re-run.
-- ============================================================

-- 1. Room codes ----------------------------------------------------
ALTER TABLE game_rooms
  ADD COLUMN IF NOT EXISTS code TEXT;

ALTER TABLE game_rooms
  ADD COLUMN IF NOT EXISTS host_player_id UUID;

CREATE UNIQUE INDEX IF NOT EXISTS idx_game_rooms_code_active
  ON game_rooms (code)
  WHERE status IN ('waiting', 'playing');

-- 2. Player profile bits (avatar colour, last seen) ---------------
ALTER TABLE game_players
  ADD COLUMN IF NOT EXISTS avatar_seed INT NOT NULL DEFAULT (floor(random() * 1000))::int,
  ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ DEFAULT NOW();

-- 3. Generate a fresh 6-char room code on insert ------------------
CREATE OR REPLACE FUNCTION generate_room_code()
RETURNS TEXT AS $$
DECLARE
  alphabet TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- no 0/O/1/I — readability
  code TEXT;
  i INT;
BEGIN
  LOOP
    code := '';
    FOR i IN 1..6 LOOP
      code := code || substr(alphabet, floor(random() * length(alphabet))::int + 1, 1);
    END LOOP;
    -- Make sure no active room already uses this code.
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM game_rooms
      WHERE code = code AND status IN ('waiting', 'playing')
    );
  END LOOP;
  RETURN code;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_room_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.code IS NULL THEN
    NEW.code := generate_room_code();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_room_code ON game_rooms;
CREATE TRIGGER trg_set_room_code
  BEFORE INSERT ON game_rooms
  FOR EACH ROW
  EXECUTE FUNCTION set_room_code();

-- Backfill existing rooms missing a code.
UPDATE game_rooms SET code = generate_room_code() WHERE code IS NULL;

-- 4. Tighter RLS (foundation — full server-side scoring lands in Faza 2) ---
-- Anyone can read rooms / players / events / answers (game is public).
-- Only inserts of own rows allowed; deletes restricted.
DROP POLICY IF EXISTS "allow_all" ON game_rooms;
DROP POLICY IF EXISTS "allow_all" ON game_players;
DROP POLICY IF EXISTS "allow_all" ON game_events;
DROP POLICY IF EXISTS "allow_all" ON game_answers;

CREATE POLICY "rooms_read"   ON game_rooms   FOR SELECT USING (true);
CREATE POLICY "rooms_write"  ON game_rooms   FOR INSERT WITH CHECK (true);
CREATE POLICY "rooms_update" ON game_rooms   FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "players_read"   ON game_players FOR SELECT USING (true);
CREATE POLICY "players_write"  ON game_players FOR INSERT WITH CHECK (true);
CREATE POLICY "players_update" ON game_players FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "players_delete" ON game_players FOR DELETE USING (true);

CREATE POLICY "events_read"  ON game_events FOR SELECT USING (true);
CREATE POLICY "events_write" ON game_events FOR INSERT WITH CHECK (true);

CREATE POLICY "answers_read"  ON game_answers FOR SELECT USING (true);
CREATE POLICY "answers_write" ON game_answers FOR INSERT WITH CHECK (true);
CREATE POLICY "answers_update" ON game_answers FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "answers_delete" ON game_answers FOR DELETE USING (true);

-- ⚠ NOTE for Faza 2:
-- Replace the open INSERT/UPDATE policies above with restrictive ones that
-- channel writes through SECURITY DEFINER RPC functions:
--   - rpc_join_room(p_code TEXT, p_name TEXT, p_avatar_seed INT)
--   - rpc_submit_answer(p_player_id UUID, p_question_id UUID, p_choice INT)
--   - rpc_advance_question(p_room_id UUID)
-- These RPCs will live in `migrations/002_secure_scoring.sql`.
