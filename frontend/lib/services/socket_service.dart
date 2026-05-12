import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/questions.dart';

/// Singleton that manages the game connection via Supabase Realtime.
///
/// Public API is identical to the old Socket.IO-based service so all
/// screens work without modification.
///
/// Usage:
///   SocketService.instance.connect(AppConfig.serverUrl); // serverUrl ignored
///   SocketService.instance.onJoined = (data) { ... };
///   SocketService.instance.join('Alice');
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  static const Duration _afterGameStartDelay = Duration(milliseconds: 450);
  static const Duration _afterQuestionResultDelay = Duration(milliseconds: 850);

  late SupabaseClient _db;
  bool _initialized = false;

  String? _roomId;
  String? _playerId;
  bool _isHost = false;
  int _currentQuestionIndex = 0;
  int _localScore = 0;
  int _activeNonHostCount = 0;
  bool _roomUpdateInFlight = false;
  bool _endingQuestion = false;
  final Set<String> _answeredPlayerIds = <String>{};

  Timer? _questionTimer;
  Timer? _nextQuestionTimer;

  RealtimeChannel? _eventsChannel;
  RealtimeChannel? _playersChannel;
  RealtimeChannel? _answersChannel;

  // ── Callbacks ────────────────────────────────────────────────────────────────

  void Function(Map<String, dynamic>)? onJoined;
  void Function(Map<String, dynamic>)? onRoomUpdate;
  void Function()? onGameStarted;
  void Function(Map<String, dynamic>)? onNewQuestion;
  void Function(Map<String, dynamic>)? onAnswerResult;
  void Function(Map<String, dynamic>)? onQuestionResult;
  void Function(Map<String, dynamic>)? onGameOver;
  void Function()? onGameReset;
  void Function(String)? onError;

  // ── Connect (Supabase is already initialised in main.dart) ───────────────────

  // ignore: avoid_unused_parameters
  void connect(String serverUrl) {
    _db = Supabase.instance.client;
    _initialized = true;
    debugPrint('[GameService] Connected to Supabase');
  }

  // ── Join ─────────────────────────────────────────────────────────────────────

  void join(String name, {bool asHost = false}) {
    if (!_initialized) {
      onError?.call('Not connected');
      return;
    }
    _doJoin(name, asHost: asHost).catchError((e) {
      debugPrint('[GameService] join error: $e');
      onError?.call('Failed to join: $e');
    });
  }

  Future<void> _doJoin(String rawName, {bool asHost = false}) async {
    final safeName =
        rawName.trim().substring(0, min(20, rawName.trim().length));
    final isAdmin = asHost || safeName.toLowerCase() == 'admin771';

    // ── Find or create room ──────────────────────────────────────────────────
    final roomId = await _findOrCreateRoom(isAdmin);
    if (roomId == null) {
      onError?.call('No active game. Wait for the admin to join first.');
      return;
    }
    _roomId = roomId;

    // ── Check room status + grab the human-readable code ─────────────────────
    final roomRows = await _db
        .from('game_rooms')
        .select('status, code')
        .eq('id', roomId)
        .limit(1);
    if (roomRows.isEmpty) {
      onError?.call('Room not found.');
      return;
    }
    final status = roomRows[0]['status'] as String;
    final roomCode = roomRows[0]['code'] as String?;
    if (status == 'playing' && !isAdmin) {
      onError?.call('Game already in progress');
      return;
    }

    // ── Admin: remove stale host record so admin can always rejoin ───────────
    if (isAdmin) {
      await _db
          .from('game_players')
          .delete()
          .eq('room_id', roomId)
          .eq('is_host', true);
    }

    // ── Insert player ────────────────────────────────────────────────────────
    final player = await _db
        .from('game_players')
        .insert({
          'room_id': roomId,
          'name': safeName,
          'score': 0,
          'is_host': isAdmin,
        })
        .select()
        .single();

    _playerId = player['id'] as String;
    _isHost = isAdmin;
    _localScore = 0;

    // ── Subscribe ────────────────────────────────────────────────────────────
    _subscribePlayers();
    _subscribeEvents();
    if (isAdmin) _subscribeAnswers();

    // ── Notify caller ────────────────────────────────────────────────────────
    final players = await _getPlayerList();
    onJoined?.call({
      'name': safeName,
      'isHost': isAdmin,
      'players': players,
      'roomCode': roomCode,
      'roomId': roomId,
    });
    onRoomUpdate?.call({'players': players, 'count': players.length});
  }

  Future<String?> _findOrCreateRoom(bool isAdmin) async {
    final rows = await _db
        .from('game_rooms')
        .select('id, status')
        .or('status.eq.waiting,status.eq.playing')
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isNotEmpty) return rows[0]['id'] as String;

    if (!isAdmin) return null; // no room yet — only admin can create one

    final room = await _db
        .from('game_rooms')
        .insert({
          'status': 'waiting',
          'current_question_index': 0,
        })
        .select()
        .single();
    return room['id'] as String;
  }

  Future<List<Map<String, dynamic>>> _getPlayerList() async {
    if (_roomId == null) return [];
    final rows = await _db
        .from('game_players')
        .select('name, score, is_host')
        .eq('room_id', _roomId!)
        .order('joined_at', ascending: true);
    return List<Map<String, dynamic>>.from(
        (rows as List).map((r) => Map<String, dynamic>.from(r as Map)));
  }

  // ── Realtime subscriptions ───────────────────────────────────────────────────

  void _subscribePlayers() {
    _playersChannel?.unsubscribe();
    _playersChannel = _db
        .channel('players-$_roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'game_players',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: _roomId!),
          callback: (_) async {
            if (_roomUpdateInFlight) return;
            _roomUpdateInFlight = true;
            try {
              final players = await _getPlayerList();
              _activeNonHostCount =
                  players.where((p) => p['is_host'] != true).length;
              onRoomUpdate?.call({'players': players, 'count': players.length});
            } finally {
              _roomUpdateInFlight = false;
            }
          },
        )
        .subscribe();
  }

  void _subscribeEvents() {
    _eventsChannel?.unsubscribe();
    _eventsChannel = _db
        .channel('events-$_roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'game_events',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: _roomId!),
          callback: (payload) => _handleEvent(payload.newRecord),
        )
        .subscribe();
  }

  /// Admin subscribes to answers so it can detect when all players answered.
  void _subscribeAnswers() {
    _answersChannel?.unsubscribe();
    _answersChannel = _db
        .channel('answers-$_roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'game_answers',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: _roomId!),
          callback: (payload) => _onAnswerInserted(payload.newRecord),
        )
        .subscribe();
  }

  void _onAnswerInserted(Map<String, dynamic> row) {
    if (!_isHost || _endingQuestion) return;
    final questionIndex = row['question_index'] as int?;
    if (questionIndex != _currentQuestionIndex) return;

    final playerId = row['player_id']?.toString();
    if (playerId == null || playerId.isEmpty) return;

    _answeredPlayerIds.add(playerId);
    if (_activeNonHostCount > 0 &&
        _answeredPlayerIds.length >= _activeNonHostCount) {
      _questionTimer?.cancel();
      _processQuestionEnd();
    }
  }

  // ── Event handler ────────────────────────────────────────────────────────────

  void _handleEvent(Map<String, dynamic> record) {
    final type = record['event_type'] as String;
    final payload = Map<String, dynamic>.from(
        record['payload'] as Map? ?? <String, dynamic>{});

    debugPrint('[GameService] event: $type');

    switch (type) {
      case 'game_started':
        onGameStarted?.call();
        if (_isHost) {
          Future.delayed(_afterGameStartDelay, _sendNextQuestion);
        }

      case 'new_question':
        _currentQuestionIndex = payload['index'] as int;
        if (_isHost) _startQuestionTimer(payload['timeLimit'] as int);
        onNewQuestion?.call(payload);

      case 'question_result':
        _questionTimer?.cancel();
        onQuestionResult?.call(payload);
        if (_isHost) {
          _nextQuestionTimer?.cancel();
          _nextQuestionTimer =
              Timer(_afterQuestionResultDelay, _sendNextQuestion);
        }

      case 'game_over':
        _questionTimer?.cancel();
        _nextQuestionTimer?.cancel();
        onGameOver?.call(payload);

      case 'game_reset':
        _questionTimer?.cancel();
        _nextQuestionTimer?.cancel();
        _localScore = 0;
        onGameReset?.call();
    }
  }

  // ── Admin: game flow ─────────────────────────────────────────────────────────

  void startGame() {
    if (!_isHost) return;
    _doStartGame().catchError((e) => debugPrint('[GameService] startGame: $e'));
  }

  Future<void> _doStartGame() async {
    await _db.from('game_players').update({'score': 0}).eq('room_id', _roomId!);
    await _db.from('game_rooms').update({
      'status': 'playing',
      'current_question_index': 0,
    }).eq('id', _roomId!);
    _currentQuestionIndex = 0;
    await _insertEvent('game_started', {});
    // _handleEvent will trigger _sendNextQuestion after 2 s
  }

  void _startQuestionTimer(int seconds) {
    _questionTimer?.cancel();
    _questionTimer = Timer(Duration(seconds: seconds), _processQuestionEnd);
  }

  int _serverTotalQuestions = 0;

  void _sendNextQuestion() {
    if (!_isHost || _roomId == null) return;
    _doSendQuestion(_currentQuestionIndex)
        .catchError((e) => debugPrint('[GameService] sendQuestion: $e'));
  }

  Future<void> _doSendQuestion(int index) async {
    // Server is authoritative for the question vault. If we've fallen off
    // the end, end the game.
    if (_serverTotalQuestions == 0) {
      try {
        final cnt =
            await _db.rpc('rpc_question_count') as int? ?? kQuestions.length;
        _serverTotalQuestions = cnt;
      } catch (_) {
        _serverTotalQuestions = kQuestions.length;
      }
    }
    if (index >= _serverTotalQuestions) {
      await _doEndGame();
      return;
    }

    Map<String, dynamic> payload;
    try {
      final raw = await _db.rpc(
        'rpc_get_question',
        params: {'p_position': index},
      );
      payload = Map<String, dynamic>.from(raw as Map);
    } catch (e) {
      // Fallback to local cache if RPC unavailable (older DBs).
      debugPrint('[GameService] rpc_get_question failed, falling back: $e');
      final q = kQuestions[index];
      payload = {
        'index': index,
        'total': kQuestions.length,
        'question': q['question'],
        'options': q['options'],
        'timeLimit': q['timeLimit'],
        'difficulty': q['difficulty'] ?? 'medium',
        'category': q['category'] ?? 'present_perfect',
      };
    }

    _answeredPlayerIds.clear();
    _endingQuestion = false;

    // Tell the server "this question started NOW" — this is the server
    // timestamp rpc_submit_answer will use to compute elapsed time.
    try {
      await _db.rpc('rpc_start_question', params: {
        'p_room_id': _roomId,
        'p_player_id': _playerId,
        'p_question_index': index,
      });
    } catch (e) {
      // Older DBs: at least flip the index ourselves.
      debugPrint('[GameService] rpc_start_question fallback: $e');
      await _db
          .from('game_rooms')
          .update({'current_question_index': index}).eq('id', _roomId!);
    }

    await _insertEvent('new_question', payload);
  }

  void _processQuestionEnd() {
    if (!_isHost) return;
    _doProcessQuestionEnd()
        .catchError((e) => debugPrint('[GameService] processQuestionEnd: $e'));
  }

  Future<void> _doProcessQuestionEnd() async {
    if (_endingQuestion) return;
    _endingQuestion = true;
    _questionTimer?.cancel();

    Map<String, dynamic> reveal;
    try {
      final raw = await _db.rpc('rpc_reveal_answer', params: {
        'p_room_id': _roomId,
        'p_player_id': _playerId,
        'p_question_index': _currentQuestionIndex,
      });
      reveal = Map<String, dynamic>.from(raw as Map);
    } catch (e) {
      // Fallback: legacy local source (only used if SQL migration not run).
      debugPrint('[GameService] rpc_reveal_answer fallback: $e');
      final q = kQuestions[_currentQuestionIndex];
      reveal = {
        'questionIndex': _currentQuestionIndex,
        'correctIndex': q['correctIndex'],
        'correctAnswer': (q['options'] as List)[(q['correctIndex'] as int)],
        'explanation': q['explanation'],
      };
    }

    final leaderboard = await _buildLeaderboard();
    await _insertEvent('question_result', {
      ...reveal,
      'leaderboard': leaderboard,
    });
    _currentQuestionIndex++;
  }

  Future<List<Map<String, dynamic>>> _buildLeaderboard() async {
    final rows = await _db
        .from('game_players')
        .select('name, score, is_host')
        .eq('room_id', _roomId!)
        .order('score', ascending: false);
    int rank = 1;
    return (rows as List)
        .where((r) => r['is_host'] != true)
        .map((r) => {
              'rank': rank++,
              'name': r['name'],
              'score': r['score'],
            })
        .toList();
  }

  Future<void> _doEndGame() async {
    final leaderboard = await _buildLeaderboard();
    await _db
        .from('game_rooms')
        .update({'status': 'finished'}).eq('id', _roomId!);
    await _insertEvent('game_over', {'leaderboard': leaderboard});
  }

  Future<void> _insertEvent(String type, Map<String, dynamic> payload) async {
    await _db.from('game_events').insert({
      'room_id': _roomId,
      'event_type': type,
      'payload': payload,
    });
  }

  // ── Player: send answer ──────────────────────────────────────────────────────
  // Server-side validation: client never knows correctIndex before reveal.

  void sendAnswer(int questionIndex, int answerIndex) {
    if (_roomId == null || _playerId == null) return;
    _submitAnswerRpc(questionIndex, answerIndex)
        .catchError((e) => debugPrint('[GameService] submitAnswer: $e'));
  }

  Future<void> _submitAnswerRpc(int questionIndex, int answerIndex) async {
    try {
      final raw = await _db.rpc('rpc_submit_answer', params: {
        'p_room_id': _roomId,
        'p_player_id': _playerId,
        'p_question_index': questionIndex,
        'p_choice': answerIndex,
      });
      final result = Map<String, dynamic>.from(raw as Map);
      _localScore = (result['totalScore'] as num?)?.toInt() ?? _localScore;
      // No correctIndex in payload — UI just shows "answer locked" until reveal.
      onAnswerResult?.call({
        'isCorrect': result['isCorrect'] ?? false,
        'points': result['points'] ?? 0,
        'basePoints': result['basePoints'] ?? 0,
        'streakBonus': result['streakBonus'] ?? 0,
        'comboMultiplier': result['comboMultiplier'] ?? 1.0,
        'streak': result['streak'] ?? 0,
        'totalScore': _localScore,
        'serverValidated': true,
      });
    } catch (e) {
      debugPrint('[GameService] rpc_submit_answer error: $e');
      // Surface a non-scoring lock-in so the UI can stop accepting taps.
      onAnswerResult?.call({
        'isCorrect': false,
        'points': 0,
        'basePoints': 0,
        'streakBonus': 0,
        'comboMultiplier': 1.0,
        'streak': 0,
        'totalScore': _localScore,
        'serverValidated': false,
        'error': e.toString(),
      });
    }
  }

  // ── Admin controls ───────────────────────────────────────────────────────────

  void skipQuestion() {
    if (!_isHost) return;
    _questionTimer?.cancel();
    _processQuestionEnd();
  }

  void endGame() {
    if (!_isHost) return;
    _questionTimer?.cancel();
    _nextQuestionTimer?.cancel();
    _doEndGame().catchError((e) => debugPrint('[GameService] endGame: $e'));
  }

  void resetGame() {
    if (!_isHost) return;
    _doResetGame().catchError((e) => debugPrint('[GameService] resetGame: $e'));
  }

  Future<void> _doResetGame() async {
    _questionTimer?.cancel();
    _nextQuestionTimer?.cancel();
    _currentQuestionIndex = 0;
    await _db.from('game_players').update({'score': 0}).eq('room_id', _roomId!);
    await _db.from('game_answers').delete().eq('room_id', _roomId!);
    await _db.from('game_rooms').update({
      'status': 'waiting',
      'current_question_index': 0,
    }).eq('id', _roomId!);
    await _insertEvent('game_reset', {});
  }

  // ── Disconnect ───────────────────────────────────────────────────────────────

  void disconnect() {
    _questionTimer?.cancel();
    _nextQuestionTimer?.cancel();
    _eventsChannel?.unsubscribe();
    _playersChannel?.unsubscribe();
    _answersChannel?.unsubscribe();
    if (_playerId != null) {
      _db
          .from('game_players')
          .delete()
          .eq('id', _playerId!)
          // ignore: avoid_print
          .then((_) {})
          .catchError((_) {});
    }
    _roomId = null;
    _playerId = null;
    _isHost = false;
    _initialized = false;
  }

  /// Remove all callbacks (call in screen dispose to avoid stale closures).
  void clearCallbacks() {
    onJoined = null;
    onRoomUpdate = null;
    onGameStarted = null;
    onNewQuestion = null;
    onAnswerResult = null;
    onQuestionResult = null;
    onGameOver = null;
    onGameReset = null;
    onError = null;
  }
}
