-- ============================================================
--  Faza 2 migration — server-side scoring + question vault.
--  Run AFTER 001_room_codes_and_premium.sql.
--  Idempotent.
-- ============================================================

-- 1. Authoritative question vault ---------------------------------
CREATE TABLE IF NOT EXISTS questions (
  id            BIGSERIAL PRIMARY KEY,
  position      INT UNIQUE NOT NULL,
  question      TEXT NOT NULL,
  options       JSONB NOT NULL,                  -- string[]
  correct_index INT  NOT NULL,
  time_limit    INT  NOT NULL DEFAULT 15,
  explanation   TEXT,
  difficulty    TEXT NOT NULL DEFAULT 'medium',  -- easy | medium | hard
  category      TEXT NOT NULL DEFAULT 'present_perfect',
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
-- No direct anon access — only via RPC.
DROP POLICY IF EXISTS "questions_no_direct_access" ON questions;
CREATE POLICY "questions_no_direct_access" ON questions FOR ALL USING (false);

-- 2. Per-room question state -------------------------------------
ALTER TABLE game_rooms
  ADD COLUMN IF NOT EXISTS current_question_started_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS total_questions INT;

-- 3. Player gamification fields ----------------------------------
ALTER TABLE game_players
  ADD COLUMN IF NOT EXISTS streak     INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS combo_max  INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS xp         INT NOT NULL DEFAULT 0;

-- 4. Seed the 15 Present Perfect questions -----------------------
INSERT INTO questions (position, question, options, correct_index, time_limit, explanation, difficulty)
VALUES
  (0,  'She ___ already finished her homework.', '["have","has","had","is"]'::jsonb, 1, 15, 'With 3rd person singular (she), Present Perfect uses ''has''.', 'easy'),
  (1,  'I ___ never been to Paris.',              '["have","has","had","am"]'::jsonb, 0, 15, 'With ''I'', Present Perfect uses ''have''.', 'easy'),
  (2,  'They ___ just arrived at the airport.',   '["has","have","had","are"]'::jsonb, 1, 15, 'Plural ''they'' takes ''have''.', 'easy'),
  (3,  '___ you ever eaten sushi?',                '["Have","Has","Did","Do"]'::jsonb, 0, 15, 'Present Perfect questions with ''you'' use ''Have''.', 'easy'),
  (4,  'He ___ lived in London for five years.',   '["have","has","had","is"]'::jsonb, 1, 15, '3rd person singular ''he'' uses ''has''.', 'medium'),
  (5,  'We ___ not finished the project yet.',     '["has","have","had","are"]'::jsonb, 1, 15, 'Plural ''we'' uses ''have''.', 'medium'),
  (6,  '___ she ever seen the Eiffel Tower?',      '["Have","Has","Did","Does"]'::jsonb, 1, 15, 'Questions with ''she'' use ''Has''.', 'medium'),
  (7,  'I have just ___ a new book.',              '["read","reads","reading","readed"]'::jsonb, 0, 15, 'Past participle of ''read'' is ''read'' (irregular).', 'medium'),
  (8,  'Which sentence is correct?',
        '["She has went to the store.","She has gone to the store.","She have gone to the store.","She had go to the store."]'::jsonb,
        1, 18, 'Correct Present Perfect: has + past participle ''gone''.', 'hard'),
  (9,  'They have ___ dinner already.',            '["eat","ate","eaten","eating"]'::jsonb, 2, 15, 'After ''have'', use past participle ''eaten''.', 'medium'),
  (10, 'My parents ___ never visited Japan.',      '["has","have","had","are"]'::jsonb, 1, 15, 'Plural subject takes ''have''.', 'medium'),
  (11, 'She has ___ her keys somewhere.',          '["lose","lost","losing","losted"]'::jsonb, 1, 15, 'Past participle of ''lose'' is ''lost''.', 'medium'),
  (12, '___ he finished his work yet?',            '["Have","Has","Did","Is"]'::jsonb, 1, 15, 'Questions with ''he'' use ''Has''.', 'medium'),
  (13, 'I have ___ this movie three times.',       '["see","saw","seen","seeing"]'::jsonb, 2, 15, 'Past participle of ''see'' is ''seen''.', 'medium'),
  (14, 'We have ___ in this city since 2010.',     '["live","lived","living","lives"]'::jsonb, 1, 15, '''live'' → ''lived'' with ''since''.', 'medium')
ON CONFLICT (position) DO UPDATE SET
  question      = EXCLUDED.question,
  options       = EXCLUDED.options,
  correct_index = EXCLUDED.correct_index,
  time_limit    = EXCLUDED.time_limit,
  explanation   = EXCLUDED.explanation,
  difficulty    = EXCLUDED.difficulty;

-- 5. RPC: fetch a public question (NO correct_index) -------------
CREATE OR REPLACE FUNCTION rpc_get_question(p_position INT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v RECORD; v_total INT;
BEGIN
  SELECT * INTO v FROM questions WHERE position = p_position;
  IF v IS NULL THEN RAISE EXCEPTION 'Question % not found', p_position; END IF;
  SELECT COUNT(*) INTO v_total FROM questions;

  RETURN jsonb_build_object(
    'index',      v.position,
    'total',      v_total,
    'question',   v.question,
    'options',    v.options,
    'timeLimit',  v.time_limit,
    'difficulty', v.difficulty,
    'category',   v.category
  );
END;
$$;

-- 6. RPC: get total question count -------------------------------
CREATE OR REPLACE FUNCTION rpc_question_count() RETURNS INT
LANGUAGE sql SECURITY DEFINER SET search_path = public AS
$$ SELECT COUNT(*)::INT FROM questions $$;

-- 7. RPC: submit an answer (server validates + scores) -----------
CREATE OR REPLACE FUNCTION rpc_submit_answer(
  p_room_id        UUID,
  p_player_id      UUID,
  p_question_index INT,
  p_choice         INT
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_q              RECORD;
  v_room           RECORD;
  v_player         RECORD;
  v_elapsed        FLOAT;
  v_is_correct     BOOLEAN;
  v_base_points    INT := 0;
  v_combo_mult     FLOAT := 1.0;
  v_streak_bonus   INT := 0;
  v_total_points   INT := 0;
  v_new_streak     INT;
  v_new_combo_max  INT;
  v_new_score      INT;
BEGIN
  -- Idempotency.
  IF EXISTS (
    SELECT 1 FROM game_answers
    WHERE player_id = p_player_id AND question_index = p_question_index
  ) THEN
    RAISE EXCEPTION 'ALREADY_ANSWERED';
  END IF;

  SELECT * INTO v_q FROM questions WHERE position = p_question_index;
  IF v_q IS NULL THEN RAISE EXCEPTION 'BAD_QUESTION'; END IF;

  SELECT * INTO v_room FROM game_rooms WHERE id = p_room_id;
  IF v_room.status <> 'playing' THEN RAISE EXCEPTION 'NOT_PLAYING'; END IF;
  IF v_room.current_question_index <> p_question_index THEN
    RAISE EXCEPTION 'STALE_ANSWER';
  END IF;

  SELECT * INTO v_player FROM game_players WHERE id = p_player_id;
  IF v_player IS NULL THEN RAISE EXCEPTION 'UNKNOWN_PLAYER'; END IF;
  IF v_player.is_host THEN RAISE EXCEPTION 'HOST_CANNOT_ANSWER'; END IF;

  v_elapsed := GREATEST(
    0,
    EXTRACT(EPOCH FROM (NOW() - COALESCE(v_room.current_question_started_at, NOW())))
  );

  v_is_correct := (p_choice = v_q.correct_index);

  IF v_is_correct THEN
    v_base_points := GREATEST(
      100,
      ROUND(1000 * (1 - LEAST(v_elapsed::FLOAT / v_q.time_limit, 1)))
    );
    v_new_streak := v_player.streak + 1;

    -- Streak ≥3 unlocks combo multiplier (capped at 2.5x).
    IF v_new_streak >= 3 THEN
      v_combo_mult := LEAST(1.0 + (v_new_streak - 2) * 0.25, 2.5);
      v_streak_bonus := ROUND(v_base_points * (v_combo_mult - 1));
    END IF;
    v_total_points := v_base_points + v_streak_bonus;
  ELSE
    v_new_streak := 0;
  END IF;

  v_new_combo_max := GREATEST(v_player.combo_max, v_new_streak);
  v_new_score     := v_player.score + v_total_points;

  INSERT INTO game_answers (
    room_id, player_id, player_name,
    question_index, answer_index, is_correct, points_earned
  ) VALUES (
    p_room_id, p_player_id, v_player.name,
    p_question_index, p_choice, v_is_correct, v_total_points
  );

  UPDATE game_players SET
    score     = v_new_score,
    streak    = v_new_streak,
    combo_max = v_new_combo_max,
    xp        = xp + (CASE WHEN v_is_correct THEN 10 ELSE 1 END)
  WHERE id = p_player_id;

  -- IMPORTANT: never include correct_index here; client should only learn
  -- it after the host calls rpc_reveal_answer.
  RETURN jsonb_build_object(
    'isCorrect',       v_is_correct,
    'basePoints',      v_base_points,
    'streakBonus',     v_streak_bonus,
    'comboMultiplier', v_combo_mult,
    'points',          v_total_points,
    'totalScore',      v_new_score,
    'streak',          v_new_streak,
    'elapsedSeconds',  v_elapsed
  );
END;
$$;

-- 8. RPC: reveal correct answer (host only) ----------------------
CREATE OR REPLACE FUNCTION rpc_reveal_answer(
  p_room_id        UUID,
  p_player_id      UUID,
  p_question_index INT
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_player RECORD; v_q RECORD;
BEGIN
  SELECT * INTO v_player FROM game_players
  WHERE id = p_player_id AND room_id = p_room_id;
  IF v_player IS NULL OR NOT v_player.is_host THEN
    RAISE EXCEPTION 'NOT_HOST';
  END IF;

  SELECT * INTO v_q FROM questions WHERE position = p_question_index;
  IF v_q IS NULL THEN RAISE EXCEPTION 'BAD_QUESTION'; END IF;

  RETURN jsonb_build_object(
    'questionIndex', v_q.position,
    'correctIndex',  v_q.correct_index,
    'correctAnswer', (v_q.options ->> v_q.correct_index),
    'explanation',   v_q.explanation
  );
END;
$$;

-- 9. RPC: mark a question as started (host only) -----------------
--    Sets the authoritative server timestamp used by rpc_submit_answer.
CREATE OR REPLACE FUNCTION rpc_start_question(
  p_room_id    UUID,
  p_player_id  UUID,
  p_question_index INT
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_player RECORD;
BEGIN
  SELECT * INTO v_player FROM game_players
  WHERE id = p_player_id AND room_id = p_room_id;
  IF v_player IS NULL OR NOT v_player.is_host THEN
    RAISE EXCEPTION 'NOT_HOST';
  END IF;

  UPDATE game_rooms SET
    current_question_index      = p_question_index,
    current_question_started_at = NOW(),
    status                      = 'playing'
  WHERE id = p_room_id;

  -- Reset answered-state per player so the new question has a clean slate.
  -- (We don't truncate game_answers — those are the historical record.)
END;
$$;

-- 10. Grants ----------------------------------------------------
GRANT EXECUTE ON FUNCTION rpc_get_question(INT)               TO anon, authenticated;
GRANT EXECUTE ON FUNCTION rpc_question_count()                TO anon, authenticated;
GRANT EXECUTE ON FUNCTION rpc_submit_answer(UUID, UUID, INT, INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION rpc_reveal_answer(UUID, UUID, INT)  TO anon, authenticated;
GRANT EXECUTE ON FUNCTION rpc_start_question(UUID, UUID, INT) TO anon, authenticated;
