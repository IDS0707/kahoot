/// Public question payload — never carries the correct index.
class QuizQuestion {
  final int index;
  final int total;
  final String question;
  final List<String> options;
  final int timeLimit;
  final String difficulty;
  final String category;

  const QuizQuestion({
    required this.index,
    required this.total,
    required this.question,
    required this.options,
    required this.timeLimit,
    this.difficulty = 'medium',
    this.category = 'present_perfect',
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> m) => QuizQuestion(
        index: (m['index'] as num).toInt(),
        total: (m['total'] as num?)?.toInt() ?? 1,
        question: m['question'] as String,
        options: List<String>.from(m['options'] as List),
        timeLimit: (m['timeLimit'] as num?)?.toInt() ?? 15,
        difficulty: (m['difficulty'] as String?) ?? 'medium',
        category: (m['category'] as String?) ?? 'present_perfect',
      );
}

/// Server-validated answer outcome.
class AnswerOutcome {
  final bool isCorrect;
  final int basePoints;
  final int streakBonus;
  final double comboMultiplier;
  final int points;
  final int totalScore;
  final int streak;
  final bool serverValidated;

  const AnswerOutcome({
    required this.isCorrect,
    required this.basePoints,
    required this.streakBonus,
    required this.comboMultiplier,
    required this.points,
    required this.totalScore,
    required this.streak,
    required this.serverValidated,
  });

  factory AnswerOutcome.fromMap(Map<String, dynamic> m) => AnswerOutcome(
        isCorrect: m['isCorrect'] == true,
        basePoints: (m['basePoints'] as num?)?.toInt() ?? 0,
        streakBonus: (m['streakBonus'] as num?)?.toInt() ?? 0,
        comboMultiplier:
            (m['comboMultiplier'] as num?)?.toDouble() ?? 1.0,
        points: (m['points'] as num?)?.toInt() ?? 0,
        totalScore: (m['totalScore'] as num?)?.toInt() ?? 0,
        streak: (m['streak'] as num?)?.toInt() ?? 0,
        serverValidated: m['serverValidated'] == true,
      );

  bool get hasCombo => comboMultiplier > 1.0 && streakBonus > 0;
}

/// Reveal payload — shipped server-side via question_result event.
class QuestionReveal {
  final int questionIndex;
  final int correctIndex;
  final String correctAnswer;
  final String? explanation;

  const QuestionReveal({
    required this.questionIndex,
    required this.correctIndex,
    required this.correctAnswer,
    this.explanation,
  });

  factory QuestionReveal.fromMap(Map<String, dynamic> m) => QuestionReveal(
        questionIndex: (m['questionIndex'] as num).toInt(),
        correctIndex: (m['correctIndex'] as num).toInt(),
        correctAnswer: m['correctAnswer'] as String? ?? '',
        explanation: m['explanation'] as String?,
      );
}
