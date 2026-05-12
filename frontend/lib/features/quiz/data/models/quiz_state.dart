import 'quiz_question.dart';

/// Phase of the player's quiz screen.
enum QuizPhase {
  /// Boot — waiting for the first question to arrive over realtime.
  warmup,

  /// Question is showing, player can pick.
  picking,

  /// Player picked or time ran out — locked, awaiting reveal from host.
  locked,

  /// Host revealed the correct answer; brief explanation phase.
  revealed,

  /// Game finished — leaderboard taking over.
  finished,
}

/// Immutable snapshot of the quiz screen state.
class QuizState {
  final QuizPhase phase;
  final QuizQuestion? question;
  final int secondsLeft;
  final int? selectedIndex;
  final AnswerOutcome? outcome;
  final QuestionReveal? reveal;
  final int totalScore;
  final int streak;
  final double comboMultiplier;

  const QuizState({
    required this.phase,
    this.question,
    this.secondsLeft = 0,
    this.selectedIndex,
    this.outcome,
    this.reveal,
    this.totalScore = 0,
    this.streak = 0,
    this.comboMultiplier = 1.0,
  });

  const QuizState.warmup() : this(phase: QuizPhase.warmup);

  QuizState copyWith({
    QuizPhase? phase,
    QuizQuestion? question,
    int? secondsLeft,
    int? selectedIndex,
    AnswerOutcome? outcome,
    QuestionReveal? reveal,
    int? totalScore,
    int? streak,
    double? comboMultiplier,
    bool resetSelection = false,
    bool resetOutcome = false,
    bool resetReveal = false,
  }) =>
      QuizState(
        phase: phase ?? this.phase,
        question: question ?? this.question,
        secondsLeft: secondsLeft ?? this.secondsLeft,
        selectedIndex:
            resetSelection ? null : (selectedIndex ?? this.selectedIndex),
        outcome: resetOutcome ? null : (outcome ?? this.outcome),
        reveal: resetReveal ? null : (reveal ?? this.reveal),
        totalScore: totalScore ?? this.totalScore,
        streak: streak ?? this.streak,
        comboMultiplier: comboMultiplier ?? this.comboMultiplier,
      );
}
