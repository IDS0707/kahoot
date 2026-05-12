import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/sound_fx.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/cinematic_timer.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neon_chip.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_durations.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../auth/presentation/login_screen.dart';
import '../../game/application/game_providers.dart';
import '../../game/data/models/player.dart';
import '../../leaderboard/data/models/leaderboard_entry.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../quiz/data/models/quiz_question.dart';
import '../application/admin_controller.dart';
import '../data/models/question_breakdown.dart';
import 'widgets/analytics_strip.dart';
import 'widgets/answer_heatmap.dart';
import 'widgets/control_button.dart';
import 'widgets/live_event_feed.dart';

/// Game master control center. Visible only to the host.
class AdminPanelScreen extends ConsumerStatefulWidget {
  final String playerName;
  final String roomId;

  const AdminPanelScreen({
    super.key,
    required this.playerName,
    required this.roomId,
  });

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  // Local mirror of the latest realtime payloads.
  QuizQuestion? _question;
  QuestionReveal? _reveal;
  int _secondsLeft = 0;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(activeRoomIdProvider.notifier).state = widget.roomId;
    });
  }

  @override
  Widget build(BuildContext context) {
    // New question.
    ref.listen<AsyncValue<QuizQuestion>>(
      _questionStreamProvider,
      (_, next) {
        next.whenData((q) {
          setState(() {
            _question = q;
            _reveal = null;
            _secondsLeft = q.timeLimit;
            _gameOver = false;
          });
          ref.read(activeQuestionIndexProvider.notifier).state = q.index;
          ref.read(adminFeedProvider.notifier).push(
                AdminEvent(
                  AdminEventKind.system,
                  'Question ${q.index + 1} live · ${q.timeLimit}s',
                ),
              );
          _startTicker();
        });
      },
    );
    ref.listen<AsyncValue<QuestionReveal>>(
      _revealStreamProvider,
      (_, next) {
        next.whenData((r) {
          setState(() {
            _reveal = r;
            _secondsLeft = 0;
          });
          ref.read(adminFeedProvider.notifier).push(
                AdminEvent(AdminEventKind.system, 'Answer revealed'),
              );
        });
      },
    );
    // Player joins → feed entry.
    ref.listen<AsyncValue<List<Player>>>(
      playersProvider,
      (prev, next) {
        final prevList = prev?.value ?? const [];
        final nextList = next.value ?? const [];
        for (final p in nextList) {
          if (!prevList.any((q) => q.name == p.name)) {
            ref.read(adminFeedProvider.notifier).push(
                  AdminEvent(AdminEventKind.join, '"${p.name}" joined'),
                );
          }
        }
        for (final p in prevList) {
          if (!nextList.any((q) => q.name == p.name)) {
            ref.read(adminFeedProvider.notifier).push(
                  AdminEvent(AdminEventKind.leave, '"${p.name}" left'),
                );
          }
        }
      },
    );
    // Game over → push leaderboard.
    ref.listen<AsyncValue<List<Map<String, dynamic>>>>(
      _gameOverStreamProvider,
      (_, next) {
        next.whenData((lb) {
          if (_gameOver) return;
          _gameOver = true;
          final entries = lb
              .map((m) => LeaderboardEntry.fromMap(Map<String, dynamic>.from(m)))
              .toList();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => LeaderboardScreen(
                  leaderboard: entries,
                  playerName: widget.playerName,
                  totalScore: 0,
                  isAdmin: true,
                ),
              ),
            );
          });
        });
      },
    );
    // Reset → back to lobby.
    ref.listen<AsyncValue<void>>(_resetStreamProvider, (_, next) {
      next.whenData((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      });
    });

    final compact = context.isCompact;
    final tablet = context.isTablet;

    return Scaffold(
      body: AppBackground(
        intense: _secondsLeft <= 5 && _question != null && _reveal == null,
        particles: true,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.md : AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  playerName: widget.playerName,
                  question: _question,
                  reveal: _reveal,
                  secondsLeft: _secondsLeft,
                ),
                const Gap(AppSpacing.md),
                Consumer(builder: (_, r, __) {
                  final analytics = r
                      .watch(roomAnalyticsProvider(widget.roomId))
                      .maybeWhen(data: (d) => d, orElse: () => RoomAnalytics.empty);
                  return AnalyticsStrip(analytics: analytics);
                }),
                const Gap(AppSpacing.md),
                Expanded(
                  child: tablet
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _CenterColumn(state: this)),
                            const Gap(AppSpacing.md),
                            Expanded(flex: 2, child: _SideColumn(state: this)),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              _CenterColumn(state: this),
                              const Gap(AppSpacing.md),
                              _SideColumn(state: this),
                              const Gap(AppSpacing.md),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Local 1-Hz countdown so the timer stays in sync without polling. ────
  void _startTicker() {
    Future.doWhile(() async {
      if (!mounted || _question == null) return false;
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_question == null) return false;
      if (_reveal != null) return false;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      }
      return _secondsLeft > 0 && _reveal == null;
    });
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String playerName;
  final QuizQuestion? question;
  final QuestionReveal? reveal;
  final int secondsLeft;

  const _TopBar({
    required this.playerName,
    required this.question,
    required this.reveal,
    required this.secondsLeft,
  });

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final phase = reveal != null
        ? 'REVEAL'
        : (question != null ? 'LIVE' : 'STANDBY');
    final phaseColor = reveal != null
        ? AppColors.accent
        : (question != null ? AppColors.success : AppColors.textTertiary);

    return GlassCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: compact ? AppSpacing.sm : AppSpacing.md,
      ),
      strong: true,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.gold,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.6),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.black, size: 24),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('GAME MASTER',
                        style: AppTypography.label(color: AppColors.gold)),
                    const Gap(AppSpacing.sm),
                    NeonChip(
                      label: phase,
                      color: phaseColor,
                      fontSize: 9,
                      filled: phase == 'LIVE',
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(playerName,
                    style: AppTypography.h3().copyWith(fontSize: 16)),
              ],
            ),
          ),
          if (question != null && reveal == null)
            CinematicTimer(
              secondsLeft: secondsLeft,
              total: question!.timeLimit,
              size: compact ? 56 : 70,
            ),
        ],
      ),
    ).animate().fadeIn(duration: AppDurations.medium);
  }
}

// ── Center column: question + heatmap ────────────────────────────────────────

class _CenterColumn extends StatelessWidget {
  final _AdminPanelScreenState state;
  const _CenterColumn({required this.state});

  @override
  Widget build(BuildContext context) {
    final q = state._question;

    if (q == null) {
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.huge),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.timer_rounded,
                  color: AppColors.textTertiary, size: 48),
              const Gap(AppSpacing.md),
              Text('Waiting for the first question…',
                  style: AppTypography.body()),
              const Gap(AppSpacing.xs),
              Text('Players will see what you see, in realtime.',
                  style: AppTypography.caption()),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuestionPreview(question: q),
        const Gap(AppSpacing.md),
        Consumer(builder: (_, ref, __) {
          final args = breakdownArgs(
              ref.watch(activeRoomIdProvider), q.index);
          final breakdown = ref.watch(questionBreakdownProvider(args)).maybeWhen(
                data: (b) => b,
                orElse: () => QuestionBreakdown.empty,
              );
          return AnswerHeatmap(
            options: q.options,
            breakdown: breakdown,
            correctIndex: state._reveal?.correctIndex,
          );
        }),
      ],
    );
  }
}

class _QuestionPreview extends StatelessWidget {
  final QuizQuestion question;
  const _QuestionPreview({required this.question});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeonChip(
                label: 'Q ${question.index + 1} / ${question.total}',
                color: AppColors.primaryGlow,
                icon: Icons.help_outline_rounded,
                fontSize: 10,
              ),
              const Gap(AppSpacing.sm),
              NeonChip(
                label: question.difficulty.toUpperCase(),
                color: AppColors.warning,
                filled: true,
                fontSize: 9,
              ),
              const Spacer(),
              NeonChip(
                label: question.category
                    .split('_')
                    .map((w) => w.isEmpty
                        ? w
                        : '${w[0].toUpperCase()}${w.substring(1)}')
                    .join(' '),
                color: AppColors.accent,
                fontSize: 10,
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          Text(
            question.question,
            style: AppTypography.h2().copyWith(fontSize: 18, height: 1.4),
          ),
        ],
      ),
    ).animate(key: ValueKey(question.index)).fadeIn(duration: AppDurations.medium);
  }
}

// ── Side column: controls + event feed ──────────────────────────────────────

class _SideColumn extends ConsumerWidget {
  final _AdminPanelScreenState state;
  const _SideColumn({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(adminActionsProvider);
    final feed = ref.watch(adminFeedProvider);
    final canControl = state._question != null && state._reveal == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text('CINEMATIC CONTROLS', style: AppTypography.label()),
        ),
        ControlButton(
          icon: Icons.skip_next_rounded,
          label: 'Skip Question',
          hint: 'Reveal answer & advance immediately',
          color: AppColors.warning,
          onPressed: canControl
              ? () => _confirm(
                    context,
                    title: 'Skip question?',
                    message: 'Players who haven\'t answered will be locked out.',
                    confirmLabel: 'Skip',
                    color: AppColors.warning,
                    onConfirm: actions.skip,
                  )
              : null,
        ),
        const Gap(AppSpacing.sm),
        ControlButton(
          icon: Icons.stop_circle_rounded,
          label: 'End Game',
          hint: 'Show the final podium right now',
          color: AppColors.danger,
          onPressed: () => _confirm(
            context,
            title: 'End game early?',
            message: 'This jumps straight to the leaderboard ceremony.',
            confirmLabel: 'End Game',
            color: AppColors.danger,
            onConfirm: actions.endGame,
          ),
        ),
        const Gap(AppSpacing.sm),
        ControlButton(
          icon: Icons.restart_alt_rounded,
          label: 'Reset Lobby',
          hint: 'Wipe scores, send everyone back to login',
          color: AppColors.accent,
          onPressed: () => _confirm(
            context,
            title: 'Reset the room?',
            message: 'All scores & answers will be cleared.',
            confirmLabel: 'Reset',
            color: AppColors.accent,
            onConfirm: actions.reset,
          ),
        ),
        const Gap(AppSpacing.lg),
        LiveEventFeed(events: feed),
      ],
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color color,
    required VoidCallback onConfirm,
  }) async {
    Haptics.light();
    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'confirm',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: AppDurations.fast,
      pageBuilder: (_, __, ___) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: GlassCard(
            strong: true,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.h2()),
                const Gap(AppSpacing.sm),
                Text(message, style: AppTypography.body()),
                const Gap(AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel',
                          style: AppTypography.button(color: AppColors.textSecondary)),
                    ),
                    const Gap(AppSpacing.sm),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(confirmLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(
            CurvedAnimation(parent: anim, curve: AppCurves.spring),
          ),
          child: child,
        ),
      ),
    );
    if (ok == true) {
      SoundFx.play(AppSound.submit);
      onConfirm();
    }
  }
}

// ── Stream provider shims that pull from GameRepository ──────────────────────

final _questionStreamProvider = StreamProvider<QuizQuestion>((ref) {
  return ref.watch(gameRepositoryProvider).questions$;
});
final _revealStreamProvider = StreamProvider<QuestionReveal>((ref) {
  return ref.watch(gameRepositoryProvider).reveals$;
});
final _gameOverStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(gameRepositoryProvider).gameOver$;
});
final _resetStreamProvider = StreamProvider<void>((ref) {
  return ref.watch(gameRepositoryProvider).gameReset$;
});
