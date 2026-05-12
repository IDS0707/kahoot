import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/haptics.dart';
import '../../admin/presentation/admin_panel_screen.dart' as admin_v3;
import '../../quiz/presentation/quiz_screen.dart' as quiz_v2;
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glow_button.dart';
import '../../../shared/widgets/loading_dots.dart';
import '../../../shared/widgets/neon_chip.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_durations.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../game/application/game_providers.dart';
import '../../game/data/models/player.dart';
import '../../game/data/models/session.dart';
import 'widgets/player_tile.dart';

class WaitingRoomScreen extends ConsumerStatefulWidget {
  final PlayerSession session;
  const WaitingRoomScreen({super.key, required this.session});

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  bool _starting = false;

  void _start() {
    setState(() => _starting = true);
    Haptics.heavy();
    ref.read(gameRepositoryProvider).startGame();
  }

  void _onGameStarted() {
    final isHost = widget.session.isHost;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: AppDurations.slow,
        pageBuilder: (_, __, ___) => isHost
            ? admin_v3.AdminPanelScreen(
                playerName: widget.session.playerName,
                roomId: widget.session.roomId ?? '',
              )
            : quiz_v2.QuizScreen(playerName: widget.session.playerName),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // React to game_started event from anywhere.
    ref.listen(gameStartedProvider, (_, next) {
      next.whenData((_) => _onGameStarted());
    });

    final asyncPlayers = ref.watch(playersProvider);
    final players = asyncPlayers.maybeWhen(
      data: (list) => list,
      orElse: () => widget.session.players,
    );

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _Header(session: widget.session),
              const Gap(AppSpacing.md),
              _StatsRow(playerCount: players.length),
              const Gap(AppSpacing.md),
              Expanded(child: _PlayerGrid(players: players, me: widget.session.playerName)),
              _Bottom(
                isHost: widget.session.isHost,
                playerCount: players.length,
                isStarting: _starting,
                onStart: _start,
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
  final PlayerSession session;
  const _Header({required this.session});

  /// Always prefer the server-issued [PlayerSession.roomCode]. Older
  /// Supabase schemas (no migration 001) won't have it — derive a stable
  /// fallback from the player name so the header still renders something.
  String _roomCode() {
    final fromServer = session.roomCode;
    if (fromServer != null && fromServer.isNotEmpty) return fromServer;
    final s = '${session.playerName}-PRESENT-PERFECT';
    final h = s.codeUnits.fold<int>(7, (acc, c) => (acc * 31 + c) & 0xFFFFFF);
    final code = h.toRadixString(36).toUpperCase().padLeft(6, '0');
    return code.substring(code.length - 6);
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final code = _roomCode();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? AppSpacing.lg : AppSpacing.xxl,
        AppSpacing.lg,
        compact ? AppSpacing.lg : AppSpacing.xxl,
        0,
      ),
      child: GlassCard(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.md : AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.glow(AppColors.primary, intensity: 0.6),
              ),
              child: const Icon(Icons.groups_rounded,
                  color: Colors.white, size: 22),
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LOBBY', style: AppTypography.label()),
                  const SizedBox(height: 2),
                  Text(
                    'Welcome, ${session.playerName}',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h3(),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.sm),
            _RoomCodePill(code: code),
            if (session.isHost) ...[
              const Gap(AppSpacing.sm),
              const NeonChip(
                label: 'HOST',
                icon: Icons.admin_panel_settings_rounded,
                color: AppColors.gold,
                filled: true,
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, duration: 450.ms);
  }
}

class _RoomCodePill extends StatelessWidget {
  final String code;
  const _RoomCodePill({required this.code});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        Haptics.light();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room code copied: $code'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surface,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tag_rounded, color: AppColors.accent, size: 14),
            const Gap(AppSpacing.xs),
            Text(code, style: AppTypography.mono(size: 13, color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}

// ── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int playerCount;
  const _StatsRow({required this.playerCount});

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.lg : AppSpacing.xxl,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.groups_2_rounded,
              label: '$playerCount player${playerCount == 1 ? '' : 's'}',
              color: Colors.white,
              accent: AppColors.primaryGlow,
            ),
          ),
          const Gap(AppSpacing.sm),
          const Expanded(
            child: _StatCard(
              icon: Icons.podcasts_rounded,
              label: 'Realtime',
              color: AppColors.accent,
              accent: AppColors.accent,
              pulse: true,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color accent;
  final bool pulse;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.accent,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accent, size: 18),
          const Gap(AppSpacing.sm),
          Text(
            label,
            style: AppTypography.caption(color: color, weight: FontWeight.w800),
          ),
        ],
      ),
    );
    if (!pulse) return card;
    return card
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1800.ms,
          color: accent.withValues(alpha: 0.4),
        );
  }
}

// ── Player grid ──────────────────────────────────────────────────────────────

class _PlayerGrid extends StatelessWidget {
  final List<Player> players;
  final String me;
  const _PlayerGrid({required this.players, required this.me});

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final tablet = context.isTablet;

    if (players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.glassFill,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  size: 38, color: AppColors.textTertiary),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1800.ms, color: AppColors.primaryGlow),
            const Gap(AppSpacing.lg),
            Text('Waiting for players…', style: AppTypography.h3()),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: tablet ? 200 : (compact ? 145 : 170),
        mainAxisSpacing: compact ? AppSpacing.sm : AppSpacing.md,
        crossAxisSpacing: compact ? AppSpacing.sm : AppSpacing.md,
        childAspectRatio: compact ? 1.05 : 1.15,
      ),
      itemCount: players.length,
      itemBuilder: (_, i) => PlayerTile(
        player: players[i],
        index: i,
        isMe: players[i].name == me,
      ),
    );
  }
}

// ── Bottom (host CTA / waiting indicator) ────────────────────────────────────

class _Bottom extends StatelessWidget {
  final bool isHost;
  final int playerCount;
  final bool isStarting;
  final VoidCallback onStart;

  const _Bottom({
    required this.isHost,
    required this.playerCount,
    required this.isStarting,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final pad = EdgeInsets.fromLTRB(
      compact ? AppSpacing.lg : AppSpacing.xxl,
      AppSpacing.md,
      compact ? AppSpacing.lg : AppSpacing.xxl,
      compact ? AppSpacing.lg : AppSpacing.xxl,
    );

    if (isHost) {
      final canStart = playerCount > 0 && !isStarting;
      return Padding(
        padding: pad,
        child: GlowButton(
          label: isStarting
              ? 'Launching…'
              : (playerCount == 0
                  ? 'Waiting for players'
                  : 'Start Game · $playerCount'),
          icon: isStarting ? null : Icons.play_arrow_rounded,
          isLoading: isStarting,
          variant: GlowButtonVariant.success,
          onPressed: canStart ? onStart : null,
        ),
      );
    }

    return Padding(
      padding: pad,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            const LoadingDots(color: AppColors.primaryGlow, size: 6),
            const Gap(AppSpacing.md),
            Expanded(
              child: Text(
                'Waiting for the host to launch the game…',
                style: AppTypography.body(weight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
