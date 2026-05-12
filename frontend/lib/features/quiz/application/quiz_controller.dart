import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/application/game_providers.dart';
import '../data/models/quiz_question.dart';
import '../data/models/quiz_state.dart';

/// Owns the per-question lifecycle on the player's screen.
/// Subscribes to the realtime streams from [GameRepository].
class QuizController extends AutoDisposeNotifier<QuizState> {
  Timer? _ticker;
  StreamSubscription<QuizQuestion>? _qSub;
  StreamSubscription<AnswerOutcome>? _aSub;
  StreamSubscription<QuestionReveal>? _rSub;
  StreamSubscription<List<Map<String, dynamic>>>? _gSub;

  @override
  QuizState build() {
    final repo = ref.watch(gameRepositoryProvider);
    _qSub = repo.questions$.listen(_onQuestion);
    _aSub = repo.outcomes$.listen(_onOutcome);
    _rSub = repo.reveals$.listen(_onReveal);
    _gSub = repo.gameOver$.listen(_onGameOver);

    ref.onDispose(() {
      _ticker?.cancel();
      _qSub?.cancel();
      _aSub?.cancel();
      _rSub?.cancel();
      _gSub?.cancel();
    });

    return const QuizState.warmup();
  }

  // ── Stream handlers ───────────────────────────────────────────────────────

  void _onQuestion(QuizQuestion q) {
    _ticker?.cancel();
    state = state.copyWith(
      phase: QuizPhase.picking,
      question: q,
      secondsLeft: q.timeLimit,
      resetSelection: true,
      resetOutcome: true,
      resetReveal: true,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = state.secondsLeft;
      if (s <= 0) {
        _ticker?.cancel();
        // If still picking, force-lock locally — server will send reveal.
        if (state.phase == QuizPhase.picking) {
          state = state.copyWith(phase: QuizPhase.locked, secondsLeft: 0);
        }
        return;
      }
      state = state.copyWith(secondsLeft: s - 1);
    });
  }

  void _onOutcome(AnswerOutcome o) {
    state = state.copyWith(
      phase: QuizPhase.locked,
      outcome: o,
      totalScore: o.totalScore,
      streak: o.streak,
      comboMultiplier: o.comboMultiplier,
    );
  }

  void _onReveal(QuestionReveal r) {
    _ticker?.cancel();
    state = state.copyWith(
      phase: QuizPhase.revealed,
      reveal: r,
      secondsLeft: 0,
    );
  }

  void _onGameOver(List<Map<String, dynamic>> _) {
    _ticker?.cancel();
    state = state.copyWith(phase: QuizPhase.finished);
  }

  // ── Player intents ────────────────────────────────────────────────────────

  void selectAnswer(int index) {
    final s = state;
    if (s.phase != QuizPhase.picking || s.question == null) return;
    state = s.copyWith(selectedIndex: index, phase: QuizPhase.locked);
    ref.read(gameRepositoryProvider).submitAnswer(s.question!.index, index);
  }
}

final quizControllerProvider =
    AutoDisposeNotifierProvider<QuizController, QuizState>(
  QuizController.new,
);
