import 'dart:async';

import '../../../config.dart';
import '../../../services/socket_service.dart';
import '../../quiz/data/models/quiz_question.dart';
import 'models/player.dart';
import 'models/session.dart';

/// Thin facade over the legacy [SocketService] singleton.
///
/// Faza 1 — owns join/start flow + player roster stream.
/// Faza 2 — also exposes question / outcome / reveal streams + submitAnswer
///          (delegates to server-side [SocketService.sendAnswer], which calls
///          `rpc_submit_answer` under the hood).
class GameRepository {
  GameRepository._();
  static final GameRepository instance = GameRepository._();

  final SocketService _socket = SocketService.instance;
  bool _connected = false;

  // ── Streams (broadcast — Riverpod consumers subscribe) ────────────────────
  final _players = StreamController<List<Player>>.broadcast();
  final _gameStarted = StreamController<void>.broadcast();
  final _gameReset = StreamController<void>.broadcast();
  final _questions = StreamController<QuizQuestion>.broadcast();
  final _outcomes = StreamController<AnswerOutcome>.broadcast();
  final _reveals = StreamController<QuestionReveal>.broadcast();
  final _gameOver = StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<Player>> get players$ => _players.stream;
  Stream<void> get gameStarted$ => _gameStarted.stream;
  Stream<void> get gameReset$ => _gameReset.stream;
  Stream<QuizQuestion> get questions$ => _questions.stream;
  Stream<AnswerOutcome> get outcomes$ => _outcomes.stream;
  Stream<QuestionReveal> get reveals$ => _reveals.stream;
  Stream<List<Map<String, dynamic>>> get gameOver$ => _gameOver.stream;

  // ── Wiring ────────────────────────────────────────────────────────────────

  void _ensureConnected() {
    if (_connected) return;
    _socket.connect(AppConfig.serverUrl);
    _connected = true;

    _socket.onRoomUpdate = (data) {
      final list = (data['players'] as List? ?? const [])
          .map((p) => Player.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList(growable: false);
      _players.add(list);
    };
    _socket.onGameStarted = () => _gameStarted.add(null);
    _socket.onGameReset = () => _gameReset.add(null);

    _socket.onNewQuestion = (data) {
      _questions.add(QuizQuestion.fromMap(Map<String, dynamic>.from(data)));
    };
    _socket.onAnswerResult = (data) {
      _outcomes.add(AnswerOutcome.fromMap(Map<String, dynamic>.from(data)));
    };
    _socket.onQuestionResult = (data) {
      _reveals.add(QuestionReveal.fromMap(Map<String, dynamic>.from(data)));
    };
    _socket.onGameOver = (data) {
      final lb = (data['leaderboard'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _gameOver.add(lb);
    };
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<PlayerSession> join(String nickname, {bool asHost = false}) {
    _ensureConnected();
    final completer = Completer<PlayerSession>();

    _socket.onJoined = (data) {
      _socket.onJoined = null;
      _socket.onError = null;
      if (!completer.isCompleted) {
        completer.complete(PlayerSession.fromJoinedPayload(data));
      }
    };
    _socket.onError = (msg) {
      _socket.onJoined = null;
      _socket.onError = null;
      if (!completer.isCompleted) {
        completer.completeError(JoinException(msg));
      }
    };

    _socket.join(nickname, asHost: asHost);
    return completer.future;
  }

  void startGame() => _socket.startGame();

  void submitAnswer(int questionIndex, int answerIndex) =>
      _socket.sendAnswer(questionIndex, answerIndex);

  // ── Admin actions (host-only on the server) ──────────────────────────────
  void skipQuestion() => _socket.skipQuestion();
  void endGameEarly() => _socket.endGame();
  void resetGame() => _socket.resetGame();

  void leave() {
    _socket.disconnect();
    _connected = false;
  }
}

class JoinException implements Exception {
  final String message;
  const JoinException(this.message);
  @override
  String toString() => message;
}
