/// One row of the final leaderboard.
class LeaderboardEntry {
  final int rank;
  final String name;
  final int score;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.score,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> m) => LeaderboardEntry(
        rank: (m['rank'] as num?)?.toInt() ?? 0,
        name: m['name'] as String? ?? '—',
        score: (m['score'] as num?)?.toInt() ?? 0,
      );
}
