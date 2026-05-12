import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/haptics.dart';
import '../../../core/utils/sound_fx.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/aurora_title.dart';
import '../../../shared/widgets/celebration_confetti.dart';
import '../../../shared/widgets/glow_button.dart';
import '../../../shared/widgets/neon_chip.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_durations.dart';
import '../../../theme/app_spacing.dart';
import '../../auth/presentation/login_screen.dart';
import '../../game/application/game_providers.dart';
import '../data/models/leaderboard_entry.dart';
import 'widgets/leaderboard_row.dart';
import 'widgets/podium.dart';

/// Final podium ceremony. Adopts the v2 cinematic design system.
class LeaderboardScreen extends ConsumerStatefulWidget {
  final List<LeaderboardEntry> leaderboard;
  final String playerName;
  final int totalScore;
  final bool isAdmin;

  const LeaderboardScreen({
    super.key,
    required this.leaderboard,
    required this.playerName,
    required this.totalScore,
    this.isAdmin = false,
  });

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  Object? _confettiTrigger;

  @override
  void initState() {
    super.initState();
    Haptics.success();
    SoundFx.play(AppSound.victory);
    // Confetti fires after the podium settles.
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _confettiTrigger = DateTime.now());
    });
  }

  int get _myRank {
    if (widget.isAdmin) return -1;
    final i = widget.leaderboard.indexWhere((e) => e.name == widget.playerName);
    return i >= 0 ? widget.leaderboard[i].rank : widget.leaderboard.length;
  }

  void _playAgain() {
    Haptics.medium();
    SoundFx.play(AppSound.click);
    ref.read(gameRepositoryProvider).leave();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = widget.leaderboard.take(3).toList();
    final rest = widget.leaderboard.skip(3).toList();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _Header(rank: _myRank, score: widget.totalScore, isAdmin: widget.isAdmin),
                  const Gap(AppSpacing.sm),
                  if (top.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Podium(top: top, selfName: widget.playerName),
                    ),
                  Expanded(
                    child: rest.isEmpty
                        ? const SizedBox.shrink()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            itemCount: rest.length,
                            itemBuilder: (_, i) => LeaderboardRow(
                              entry: rest[i],
                              index: i,
                              isMe: rest[i].name == widget.playerName,
                            ),
                          ),
                  ),
                  _Footer(onPlayAgain: _playAgain),
                ],
              ),
              // Full-screen confetti cannon over the top.
              IgnorePointer(
                child: SizedBox.expand(
                  child: CelebrationConfetti(
                    trigger: _confettiTrigger,
                    preset: ConfettiPreset.victory,
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

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int rank;
  final int score;
  final bool isAdmin;
  const _Header({required this.rank, required this.score, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Text('🏆', style: TextStyle(fontSize: 48))
              .animate()
              .scale(
                begin: const Offset(0, 0),
                duration: 700.ms,
                curve: AppCurves.spring,
              ),
          const Gap(AppSpacing.xs),
          const AuroraTitle('Game Over')
              .animate()
              .fadeIn(delay: 200.ms),
          const Gap(AppSpacing.sm),
          if (!isAdmin)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NeonChip(
                  label: rank > 0 ? 'YOUR RANK · #$rank' : 'YOUR RANK · —',
                  color: AppColors.primaryGlow,
                  icon: Icons.flag_rounded,
                  fontSize: 11,
                ),
                const Gap(AppSpacing.sm),
                NeonChip(
                  label: '$score PTS',
                  color: AppColors.gold,
                  filled: true,
                  icon: Icons.bolt_rounded,
                  fontSize: 11,
                ),
              ],
            ).animate().fadeIn(delay: 400.ms)
          else
            NeonChip(
              label: 'ADMIN VIEW',
              color: AppColors.gold,
              icon: Icons.admin_panel_settings_rounded,
              filled: true,
            ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

// ── Footer (Play Again) ──────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final VoidCallback onPlayAgain;
  const _Footer({required this.onPlayAgain});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: GlowButton(
        label: 'Play Again',
        icon: Icons.replay_rounded,
        onPressed: onPlayAgain,
      ).animate().slideY(
            begin: 0.4,
            delay: 1800.ms,
            duration: AppDurations.medium,
          ).fadeIn(delay: 1800.ms),
    );
  }
}
