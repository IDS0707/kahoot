/// Immutable player model. Built from raw realtime payloads.
class Player {
  final String name;
  final int score;
  final bool isHost;

  const Player({
    required this.name,
    required this.score,
    required this.isHost,
  });

  factory Player.fromMap(Map<String, dynamic> m) => Player(
        name: m['name'] as String? ?? 'Unknown',
        score: (m['score'] as num?)?.toInt() ?? 0,
        // Realtime payloads sometimes use 'isHost' (camelCase from Socket.IO)
        // and sometimes 'is_host' (snake_case from Postgres rows).
        isHost: (m['isHost'] ?? m['is_host']) == true,
      );

  Player copyWith({String? name, int? score, bool? isHost}) => Player(
        name: name ?? this.name,
        score: score ?? this.score,
        isHost: isHost ?? this.isHost,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          other.name == name &&
          other.score == score &&
          other.isHost == isHost;

  @override
  int get hashCode => Object.hash(name, score, isHost);
}
