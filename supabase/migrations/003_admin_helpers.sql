-- ============================================================
--  Faza 3 migration — admin tooling: kick, analytics, code surfacing.
--  Run AFTER 002_secure_scoring.sql.
--  Idempotent.
-- ============================================================

-- 1. Reset per-player streak/score whenever a new game starts ----
--    The host already updates game_rooms.status='playing' via the existing
--    flow; this RPC also wipes the per-player streak / score / answers so
--    a replay starts clean.
CREATE OR REPLACE FUNCTION rpc_reset_for_new_game(
  p_room_id   UUID,
  p_player_id UUID
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

  UPDATE game_players
     SET score = 0, streak = 0, combo_max = 0
   WHERE room_id = p_room_id;
  DELETE FROM game_answers WHERE room_id = p_room_id;
END;
$$;

-- 2. Kick a player (host only) -----------------------------------
CREATE OR REPLACE FUNCTION rpc_kick_player(
  p_room_id        UUID,
  p_host_id        UUID,
  p_target_player  UUID
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_host RECORD;
BEGIN
  SELECT * INTO v_host FROM game_players
  WHERE id = p_host_id AND room_id = p_room_id;
  IF v_host IS NULL OR NOT v_host.is_host THEN
    RAISE EXCEPTION 'NOT_HOST';
  END IF;
  -- Hosts cannot kick themselves.
  IF p_host_id = p_target_player THEN
    RAISE EXCEPTION 'CANT_KICK_SELF';
  END IF;
  DELETE FROM game_players
   WHERE id = p_target_player AND room_id = p_room_id;
END;
$$;

-- 3. Per-question analytics view (live admin heatmap) -----------
--    Returns {answer_index, vote_count, correct_count} for the active Q.
CREATE OR REPLACE FUNCTION rpc_question_breakdown(
  p_room_id        UUID,
  p_question_index INT
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_q          RECORD;
  v_buckets    JSONB := '[]'::jsonb;
  v_total      INT;
  v_correct    INT;
  v_avg_time   FLOAT;
  v_fastest    RECORD;
  v_room       RECORD;
  v_started_at TIMESTAMPTZ;
BEGIN
  SELECT * INTO v_q FROM questions WHERE position = p_question_index;
  IF v_q IS NULL THEN RAISE EXCEPTION 'BAD_QUESTION'; END IF;

  SELECT * INTO v_room FROM game_rooms WHERE id = p_room_id;
  v_started_at := v_room.current_question_started_at;

  -- Bucket counts per answer index (0..3).
  SELECT jsonb_agg(jsonb_build_object('index', i, 'count', cnt) ORDER BY i)
    INTO v_buckets
  FROM (
    SELECT i.idx AS i,
           COALESCE(b.cnt, 0)::int AS cnt
    FROM (SELECT generate_series(0, jsonb_array_length(v_q.options) - 1) AS idx) i
    LEFT JOIN (
      SELECT answer_index, COUNT(*) AS cnt
      FROM game_answers
      WHERE room_id = p_room_id AND question_index = p_question_index
      GROUP BY answer_index
    ) b ON b.answer_index = i.idx
  ) AS s;

  SELECT
    COUNT(*)::int,
    COUNT(*) FILTER (WHERE is_correct)::int,
    AVG(EXTRACT(EPOCH FROM (answered_at - v_started_at)))::float
  INTO v_total, v_correct, v_avg_time
  FROM game_answers
  WHERE room_id = p_room_id AND question_index = p_question_index;

  SELECT a.player_name, EXTRACT(EPOCH FROM (a.answered_at - v_started_at))::float AS t
  INTO v_fastest
  FROM game_answers a
  WHERE a.room_id = p_room_id AND a.question_index = p_question_index AND a.is_correct
  ORDER BY a.answered_at ASC
  LIMIT 1;

  RETURN jsonb_build_object(
    'questionIndex', p_question_index,
    'buckets',       COALESCE(v_buckets, '[]'::jsonb),
    'totalAnswered', COALESCE(v_total, 0),
    'correctCount',  COALESCE(v_correct, 0),
    'avgSeconds',    v_avg_time,
    'fastestPlayer', CASE WHEN v_fastest IS NULL THEN NULL ELSE v_fastest.player_name END,
    'fastestSeconds', CASE WHEN v_fastest IS NULL THEN NULL ELSE v_fastest.t END
  );
END;
$$;

-- 4. Whole-game analytics (used on the leaderboard & admin top bar) ----
CREATE OR REPLACE FUNCTION rpc_room_analytics(p_room_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total_answers INT;
  v_total_correct INT;
  v_player_count  INT;
  v_mvp           RECORD;
  v_streak_leader RECORD;
BEGIN
  SELECT COUNT(*) INTO v_total_answers
    FROM game_answers WHERE room_id = p_room_id;
  SELECT COUNT(*) INTO v_total_correct
    FROM game_answers WHERE room_id = p_room_id AND is_correct;
  SELECT COUNT(*) INTO v_player_count
    FROM game_players WHERE room_id = p_room_id AND NOT is_host;

  SELECT name, score INTO v_mvp
    FROM game_players
    WHERE room_id = p_room_id AND NOT is_host
    ORDER BY score DESC NULLS LAST LIMIT 1;

  SELECT name, combo_max INTO v_streak_leader
    FROM game_players
    WHERE room_id = p_room_id AND NOT is_host
    ORDER BY combo_max DESC NULLS LAST LIMIT 1;

  RETURN jsonb_build_object(
    'players', v_player_count,
    'totalAnswers', v_total_answers,
    'totalCorrect', v_total_correct,
    'accuracyPct',
      CASE WHEN v_total_answers > 0
           THEN ROUND(100.0 * v_total_correct / v_total_answers)
           ELSE 0 END,
    'mvpName', CASE WHEN v_mvp IS NULL THEN NULL ELSE v_mvp.name END,
    'mvpScore', CASE WHEN v_mvp IS NULL THEN 0 ELSE v_mvp.score END,
    'streakLeaderName', CASE WHEN v_streak_leader IS NULL THEN NULL ELSE v_streak_leader.name END,
    'streakLeaderCombo', CASE WHEN v_streak_leader IS NULL THEN 0 ELSE v_streak_leader.combo_max END
  );
END;
$$;

-- 5. Grants ------------------------------------------------------
GRANT EXECUTE ON FUNCTION rpc_reset_for_new_game(UUID, UUID)        TO anon, authenticated;
GRANT EXECUTE ON FUNCTION rpc_kick_player(UUID, UUID, UUID)         TO anon, authenticated;
GRANT EXECUTE ON FUNCTION rpc_question_breakdown(UUID, INT)         TO anon, authenticated;
GRANT EXECUTE ON FUNCTION rpc_room_analytics(UUID)                  TO anon, authenticated;
