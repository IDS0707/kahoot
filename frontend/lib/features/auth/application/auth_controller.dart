import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/nickname_validator.dart';
import '../../game/application/game_providers.dart';
import '../../game/data/models/session.dart';

/// Drives the join flow. Exposes [AsyncValue<PlayerSession?>]:
/// - `data(null)`   — idle (initial)
/// - `loading()`    — joining in flight
/// - `data(session)` — joined successfully
/// - `error(...)`   — server rejected (room full, name taken, etc.)
class AuthController extends AutoDisposeAsyncNotifier<PlayerSession?> {
  @override
  Future<PlayerSession?> build() async => null;

  Future<void> join({required String nickname, required bool asHost}) async {
    final clean = NicknameValidator.sanitize(nickname);
    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(
      () => ref.read(gameRepositoryProvider).join(clean, asHost: asHost),
    );

    state = result;
    if (result is AsyncData<PlayerSession?> && result.value != null) {
      ref.read(sessionProvider.notifier).state = result.value;
    }
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}

final authControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, PlayerSession?>(
  AuthController.new,
);
