/// Vote bucket for one answer slot in the live admin heatmap.
class VoteBucket {
  final int index;
  final int count;
  const VoteBucket({required this.index, required this.count});

  factory VoteBucket.fromMap(Map<String, dynamic> m) => VoteBucket(
        index: (m['index'] as num).toInt(),
        count: (m['count'] as num?)?.toInt() ?? 0,
      );
}

/// Aggregated stats for the active question (live heatmap + speed).
class QuestionBreakdown {
  final int questionIndex;
  final List<VoteBucket> buckets;
  final int totalAnswered;
  final int correctCount;
  final double? avgSeconds;
  final String? fastestPlayer;
  final double? fastestSeconds;

  const QuestionBreakdown({
    required this.questionIndex,
    required this.buckets,
    required this.totalAnswered,
    required this.correctCount,
    this.avgSeconds,
    this.fastestPlayer,
    this.fastestSeconds,
  });

  static const empty = QuestionBreakdown(
    questionIndex: -1,
    buckets: [],
    totalAnswered: 0,
    correctCount: 0,
  );

  factory QuestionBreakdown.fromMap(Map<String, dynamic> m) =>
      QuestionBreakdown(
        questionIndex: (m['questionIndex'] as num).toInt(),
        buckets: (m['buckets'] as List? ?? const [])
            .map((b) => VoteBucket.fromMap(Map<String, dynamic>.from(b as Map)))
            .toList(growable: false),
        totalAnswered: (m['totalAnswered'] as num?)?.toInt() ?? 0,
        correctCount: (m['correctCount'] as num?)?.toInt() ?? 0,
        avgSeconds: (m['avgSeconds'] as num?)?.toDouble(),
        fastestPlayer: m['fastestPlayer'] as String?,
        fastestSeconds: (m['fastestSeconds'] as num?)?.toDouble(),
      );

  int countFor(int answerIndex) => buckets
      .firstWhere(
        (b) => b.index == answerIndex,
        orElse: () => const VoteBucket(index: -1, count: 0),
      )
      .count;
}

/// Whole-game stats — used by the admin top strip.
class RoomAnalytics {
  final int players;
  final int totalAnswers;
  final int totalCorrect;
  final int accuracyPct;
  final String? mvpName;
  final int mvpScore;
  final String? streakLeaderName;
  final int streakLeaderCombo;

  const RoomAnalytics({
    required this.players,
    required this.totalAnswers,
    required this.totalCorrect,
    required this.accuracyPct,
    this.mvpName,
    this.mvpScore = 0,
    this.streakLeaderName,
    this.streakLeaderCombo = 0,
  });

  static const empty = RoomAnalytics(
    players: 0,
    totalAnswers: 0,
    totalCorrect: 0,
    accuracyPct: 0,
  );

  factory RoomAnalytics.fromMap(Map<String, dynamic> m) => RoomAnalytics(
        players: (m['players'] as num?)?.toInt() ?? 0,
        totalAnswers: (m['totalAnswers'] as num?)?.toInt() ?? 0,
        totalCorrect: (m['totalCorrect'] as num?)?.toInt() ?? 0,
        accuracyPct: (m['accuracyPct'] as num?)?.toInt() ?? 0,
        mvpName: m['mvpName'] as String?,
        mvpScore: (m['mvpScore'] as num?)?.toInt() ?? 0,
        streakLeaderName: m['streakLeaderName'] as String?,
        streakLeaderCombo: (m['streakLeaderCombo'] as num?)?.toInt() ?? 0,
      );
}

/// One entry in the live event feed (joins / answers / kicks).
enum AdminEventKind { join, leave, answerCorrect, answerWrong, system }

class AdminEvent {
  final AdminEventKind kind;
  final String message;
  final DateTime at;

  AdminEvent(this.kind, this.message) : at = DateTime.now();
}
