import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/sound_fx.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/celebration_confetti.dart';
import '../../../shared/widgets/cinematic_timer.dart';
import '../../../shared/widgets/floating_score.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neon_chip.dart';
import '../../../shared/widgets/streak_badge.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_durations.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../game/application/game_providers.dart';
import '../../game/data/models/player.dart';
import '../../leaderboard/data/models/leaderboard_entry.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../application/quiz_controller.dart';
import '../data/models/quiz_state.dart';
import 'widgets/answer_card.dart';
import 'widgets/question_card.dart';

/// Cinematic quiz arena. Player-only (host uses AdminPanel).
class QuizScreen extends ConsumerStatefulWidget {
  final String playerName;
  const QuizScreen({super.key, required this.playerName});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final List<_FloatingScoreEntry> _floats = [];
  int _floatId = 0;
  Object? _comboConfettiTrigger;

  void _spawnFloatingScore(int points, {bool isBonus = false}) {
    if (points <= 0) return;
    final id = ++_floatId;
    setState(() {
      _floats.add(_FloatingScoreEntry(id: id, points: points, isBonus: isBonus));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizControllerProvider);

    // React to outcome arriving — fire haptics + spawn score popup + sound + combo confetti.
    ref.listen<QuizState>(quizControllerProvider, (prev, next) {
      final p = prev?.outcome;
      final n = next.outcome;
      if (n != null && p != n) {
        if (n.isCorrect) {
          Haptics.success();
          SoundFx.play(AppSound.correct);
          _spawnFloatingScore(n.basePoints);
          if (n.streakBonus > 0) {
            _spawnFloatingScore(n.streakBonus, isBonus: true);
            SoundFx.play(AppSound.streakCombo);
          }
          // Big combos (>= 4 streak) → confetti burst.
          if (n.streak >= 4) {
            setState(() => _comboConfettiTrigger = DateTime.now());
          }
        } else if (n.serverValidated) {
          Haptics.error();
          SoundFx.play(AppSound.wrong);
        }
      }

      // Reveal arrived — short cue.
      if (next.reveal != null && prev?.reveal == null) {
        SoundFx.play(AppSound.questionReveal);
      }

      // Game over → push the new podium leaderboard.
      if (next.phase == QuizPhase.finished &&
          prev?.phase != QuizPhase.finished) {
        // Pull whatever leaderboard came in via game_over; if none, fall back
        // to the live players list.
        final players = ref.read(playersProvider).maybeWhen(
              data: (l) => l.where((p) => !p.isHost).toList(),
              orElse: () => const <Player>[],
            )..sort((a, b) => b.score.compareTo(a.score));
        final entries = <LeaderboardEntry>[
          for (var i = 0; i < players.length; i++)
            LeaderboardEntry(
              rank: i + 1,
              name: players[i].name,
              score: players[i].score,
            ),
        ];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => LeaderboardScreen(
                leaderboard: entries,
                playerName: widget.playerName,
                totalScore: next.totalScore,
              ),
            ),
          );
        });
      }
    });

    return Scaffold(
      body: AppBackground(
        intense: state.secondsLeft <= 5 && state.phase == QuizPhase.picking,
        particles: !context.isCompact,
        child: SafeArea(
          child: state.phase == QuizPhase.warmup
              ? const _Warmup()
              : Stack(
                  children: [
                    _Body(state: state),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _FloatingScoreLayer(
                          entries: _floats,
                          onComplete: (id) => setState(
                              () => _floats.removeWhere((e) => e.id == id)),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CelebrationConfetti(
                          trigger: _comboConfettiTrigger,
                          preset: ConfettiPreset.combo,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Warmup screen ─────────────────────────────────────────────────────────────

class _Warmup extends StatelessWidget {
  const _Warmup();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 3),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1600.ms, color: AppColors.accent),
          const Gap(AppSpacing.xl),
          Text('Get ready', style: AppTypography.h1())
              .animate()
              .fadeIn(duration: 400.ms),
          const Gap(AppSpacing.xs),
          Text('First question incoming…',
                  style: AppTypography.body(color: AppColors.textTertiary))
              .animate()
              .fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

// ── Body (top bar + question + answers) ──────────────────────────────────────

class _Body extends ConsumerWidget {
  final QuizState state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = context.isCompact;
    final q = state.question;
    if (q == null) return const _Warmup();

    return Column(
      children: [
        _TopBar(state: state),
        const Gap(AppSpacing.md),
        _LiveStatusRow(state: state),
        const Gap(AppSpacing.md),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.md : AppSpacing.xl,
          ),
          child: QuestionCard(
            questionIndex: q.index,
            totalQuestions: q.total,
            question: q.question,
            difficulty: q.difficulty,
            category: q.category,
          ),
        ),
        const Gap(AppSpacing.md),
        if (state.outcome != null) _OutcomeBanner(state: state),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? AppSpacing.sm : AppSpacing.lg,
              AppSpacing.sm,
              compact ? AppSpacing.sm : AppSpacing.lg,
              compact ? AppSpacing.md : AppSpacing.lg,
            ),
            child: _AnswerGrid(state: state),
          ),
        ),
      ],
    );
  }
}

// ── Top bar (timer + score chip) ─────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final QuizState state;
  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final q = state.question;
    if (q == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? AppSpacing.md : AppSpacing.xl,
        AppSpacing.lg,
        compact ? AppSpacing.md : AppSpacing.xl,
        0,
      ),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Score pill.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 16),
                  const Gap(AppSpacing.xs),
                  _AnimatedNumber(value: state.totalScore),
                  const Gap(AppSpacing.xs),
                  Text('pts',
                      style: AppTypography.label(
                          color: Colors.white70, size: 10)),
                ],
              ),
            ),
            const Spacer(),
            CinematicTimer(
              secondsLeft: state.secondsLeft,
              total: q.timeLimit,
              size: compact ? 64 : 80,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated odometer-style number ───────────────────────────────────────────

class _AnimatedNumber extends StatelessWidget {
  final int value;
  const _AnimatedNumber({required this.value});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: AppDurations.slow,
      curve: AppCurves.standard,
      builder: (_, v, __) => Text(
        '$v',
        style:
            AppTypography.mono(size: 16, color: Colors.white, weight: FontWeight.w900),
      ),
    );
  }
}

// ── Live status row (rank + streak + answered count) ─────────────────────────

class _LiveStatusRow extends ConsumerWidget {
  final QuizState state;
  const _LiveStatusRow({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = context.isCompact;
    final asyncPlayers = ref.watch(playersProvider);
    final players = asyncPlayers.maybeWhen(
      data: (l) => l,
      orElse: () => const <Player>[],
    );

    // Rank computation (player vs others).
    final me = players.firstWhere(
      (p) => p.score == state.totalScore && !p.isHost,
      orElse: () => const Player(name: '', score: 0, isHost: false),
    );
    final sorted = [...players.where((p) => !p.isHost)]
      ..sort((a, b) => b.score.compareTo(a.score));
    final rank = sorted.indexWhere((p) => p == me) + 1;
    final totalContenders = sorted.length;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.md : AppSpacing.xl,
      ),
      child: Row(
        children: [
          NeonChip(
            label: rank > 0 ? 'RANK #$rank / $totalContenders' : 'RANK —',
            icon: Icons.trending_up_rounded,
            color: AppColors.primaryGlow,
            fontSize: 10,
          ),
          const Gap(AppSpacing.sm),
          StreakBadge(streak: state.streak, multiplier: state.comboMultiplier),
          const Spacer(),
          if (totalContenders > 1)
            NeonChip(
              label: '$totalContenders LIVE',
              icon: Icons.radio_button_checked_rounded,
              color: AppColors.accent,
              fontSize: 10,
            ),
        ],
      ),
    );
  }
}

// ── Outcome banner (correct / wrong / time's up) ─────────────────────────────

class _OutcomeBanner extends StatelessWidget {
  final QuizState state;
  const _OutcomeBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final outcome = state.outcome;
    final reveal = state.reveal;

    Color color;
    IconData icon;
    String label;

    if (state.phase == QuizPhase.revealed && outcome == null) {
      color = AppColors.warning;
      icon = Icons.timer_off_rounded;
      label = "Time's up!";
    } else if (outcome == null) {
      return const SizedBox.shrink();
    } else if (outcome.isCorrect) {
      color = AppColors.success;
      icon = Icons.check_circle_rounded;
      label = outcome.hasCombo
          ? 'Correct! +${outcome.points} (${outcome.comboMultiplier.toStringAsFixed(2)}x combo)'
          : 'Correct! +${outcome.points}';
    } else {
      color = AppColors.danger;
      icon = Icons.cancel_rounded;
      label = state.phase == QuizPhase.revealed
          ? (reveal != null
              ? 'Wrong — answer was "${reveal.correctAnswer}"'
              : 'Wrong answer')
          : 'Locked in';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.h3(color: Colors.white).copyWith(fontSize: 15),
            ),
          ),
        ],
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.85, 0.85),
          duration: AppDurations.medium,
          curve: AppCurves.spring,
        )
        .fadeIn(duration: AppDurations.fast);
  }
}

// ── Answer grid (2x2) ────────────────────────────────────────────────────────

class _AnswerGrid extends ConsumerWidget {
  final QuizState state;
  const _AnswerGrid({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = context.isCompact;
    final q = state.question;
    if (q == null) return const SizedBox.shrink();
    final selected = state.selectedIndex;
    final reveal = state.reveal;
    final phase = state.phase;

    AnswerPhase phaseFor(int i) {
      if (phase == QuizPhase.revealed && reveal != null) {
        return AnswerPhases.afterReveal(i, selected, reveal.correctIndex);
      }
      return AnswerPhases.preAnswer(i, selected);
    }

    Widget cell(int i) {
      if (i >= q.options.length) return const SizedBox.shrink();
      return AnswerCard(
        index: i,
        label: q.options[i],
        phase: phaseFor(i),
        onTap: phase == QuizPhase.picking
            ? () => ref.read(quizControllerProvider.notifier).selectAnswer(i)
            : null,
      );
    }

    final spacing = compact ? AppSpacing.sm : AppSpacing.md;

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: cell(0)),
              SizedBox(width: spacing),
              Expanded(child: cell(1)),
            ],
          ),
        ),
        SizedBox(height: spacing),
        Expanded(
          child: Row(
            children: [
              Expanded(child: cell(2)),
              SizedBox(width: spacing),
              Expanded(child: cell(3)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Floating-score overlay ───────────────────────────────────────────────────

class _FloatingScoreEntry {
  final int id;
  final int points;
  final bool isBonus;
  _FloatingScoreEntry({
    required this.id,
    required this.points,
    required this.isBonus,
  });
}

class _FloatingScoreLayer extends StatelessWidget {
  final List<_FloatingScoreEntry> entries;
  final void Function(int id) onComplete;

  const _FloatingScoreLayer({
    required this.entries,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: entries.map((e) {
        return FloatingScore(
          key: ValueKey('float_${e.id}'),
          points: e.points,
          isBonus: e.isBonus,
          onComplete: () => onComplete(e.id),
        );
      }).toList(),
    );
  }
}
