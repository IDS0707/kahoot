import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_repository.dart';
import '../data/models/player.dart';
import '../data/models/session.dart';

/// DI hook — easy to override in tests.
final gameRepositoryProvider = Provider<GameRepository>(
  (ref) => GameRepository.instance,
);

/// Live player list (broadcast). Defaults to empty until first room_update.
final playersProvider = StreamProvider<List<Player>>((ref) {
  final repo = ref.watch(gameRepositoryProvider);
  return repo.players$;
});

/// One-shot signal that the host pressed "Start Game".
final gameStartedProvider = StreamProvider<void>((ref) {
  return ref.watch(gameRepositoryProvider).gameStarted$;
});

/// One-shot signal that the host reset the game.
final gameResetProvider = StreamProvider<void>((ref) {
  return ref.watch(gameRepositoryProvider).gameReset$;
});

/// Holds the current player's session (set after a successful join).
final sessionProvider = StateProvider<PlayerSession?>((_) => null);
