import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../game/application/game_providers.dart';
import '../data/models/question_breakdown.dart';

/// In-memory event feed shown in the admin dashboard.
class AdminFeedNotifier extends AutoDisposeNotifier<List<AdminEvent>> {
  static const int _max = 30;

  @override
  List<AdminEvent> build() => [
        AdminEvent(AdminEventKind.system, 'Game master console online'),
      ];

  void push(AdminEvent e) {
    final next = [e, ...state];
    state = next.length > _max ? next.sublist(0, _max) : next;
  }
}

final adminFeedProvider =
    AutoDisposeNotifierProvider<AdminFeedNotifier, List<AdminEvent>>(
  AdminFeedNotifier.new,
);

/// Polls the live question breakdown every 800 ms while a question is active.
final questionBreakdownProvider =
    StreamProvider.autoDispose.family<QuestionBreakdown, _BreakdownArgs>(
        (ref, args) async* {
  if (args.roomId.isEmpty || args.questionIndex < 0) {
    yield QuestionBreakdown.empty;
    return;
  }
  final db = Supabase.instance.client;
  yield QuestionBreakdown.empty;
  while (true) {
    try {
      final raw = await db.rpc('rpc_question_breakdown', params: {
        'p_room_id': args.roomId,
        'p_question_index': args.questionIndex,
      });
      yield QuestionBreakdown.fromMap(Map<String, dynamic>.from(raw as Map));
    } catch (_) {
      yield QuestionBreakdown.empty;
    }
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }
});

class _BreakdownArgs {
  final String roomId;
  final int questionIndex;
  const _BreakdownArgs(this.roomId, this.questionIndex);

  @override
  bool operator ==(Object o) =>
      o is _BreakdownArgs &&
      o.roomId == roomId &&
      o.questionIndex == questionIndex;
  @override
  int get hashCode => Object.hash(roomId, questionIndex);
}

QuestionBreakdownArgs breakdownArgs(String roomId, int questionIndex) =>
    _BreakdownArgs(roomId, questionIndex);
typedef QuestionBreakdownArgs = _BreakdownArgs;

/// Polls the room-wide analytics every 2 s.
final roomAnalyticsProvider =
    StreamProvider.autoDispose.family<RoomAnalytics, String>((ref, roomId) async* {
  if (roomId.isEmpty) {
    yield RoomAnalytics.empty;
    return;
  }
  final db = Supabase.instance.client;
  yield RoomAnalytics.empty;
  while (true) {
    try {
      final raw = await db.rpc('rpc_room_analytics', params: {
        'p_room_id': roomId,
      });
      yield RoomAnalytics.fromMap(Map<String, dynamic>.from(raw as Map));
    } catch (_) {
      yield RoomAnalytics.empty;
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }
});

/// Convenience: last seen room id (admin's session).
final activeRoomIdProvider = StateProvider<String>((_) => '');
final activeQuestionIndexProvider = StateProvider<int>((_) => -1);

/// Wires the admin controller actions (skip / reset / end / start game).
final adminActionsProvider = Provider<AdminActions>((ref) {
  return AdminActions(ref);
});

class AdminActions {
  final Ref _ref;
  AdminActions(this._ref);

  void skip() {
    final repo = _ref.read(gameRepositoryProvider);
    repo.skipQuestion();
    _ref.read(adminFeedProvider.notifier).push(
          AdminEvent(AdminEventKind.system, 'Host skipped the question'),
        );
  }

  void reset() {
    final repo = _ref.read(gameRepositoryProvider);
    repo.resetGame();
    _ref.read(adminFeedProvider.notifier).push(
          AdminEvent(AdminEventKind.system, 'Game reset to lobby'),
        );
  }

  void endGame() {
    final repo = _ref.read(gameRepositoryProvider);
    repo.endGameEarly();
    _ref.read(adminFeedProvider.notifier).push(
          AdminEvent(AdminEventKind.system, 'Host ended the game'),
        );
  }
}
