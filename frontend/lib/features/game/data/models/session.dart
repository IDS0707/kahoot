import 'player.dart';

/// Snapshot of the current player's identity within a room.
class PlayerSession {
  final String playerName;
  final bool isHost;
  final List<Player> players;

  /// Server-issued room code (e.g. "K7F2X4"). Null when an older Supabase
  /// schema is in use; callers should fall back to a derived code in that case.
  final String? roomCode;

  /// Internal UUID of the active room — needed by analytics RPCs.
  final String? roomId;

  const PlayerSession({
    required this.playerName,
    required this.isHost,
    required this.players,
    this.roomCode,
    this.roomId,
  });

  PlayerSession copyWith({
    String? playerName,
    bool? isHost,
    List<Player>? players,
    String? roomCode,
    String? roomId,
  }) =>
      PlayerSession(
        playerName: playerName ?? this.playerName,
        isHost: isHost ?? this.isHost,
        players: players ?? this.players,
        roomCode: roomCode ?? this.roomCode,
        roomId: roomId ?? this.roomId,
      );

  static PlayerSession fromJoinedPayload(Map<String, dynamic> data) {
    final list = (data['players'] as List? ?? const [])
        .map((p) => Player.fromMap(Map<String, dynamic>.from(p as Map)))
        .toList(growable: false);
    return PlayerSession(
      playerName: data['name'] as String,
      isHost: data['isHost'] as bool? ?? false,
      players: list,
      roomCode: data['roomCode'] as String?,
      roomId: data['roomId'] as String?,
    );
  }
}
