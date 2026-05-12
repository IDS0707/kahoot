import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../shared/widgets/animated_score_counter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_durations.dart';
import '../../../../theme/app_typography.dart';
import '../../data/models/leaderboard_entry.dart';

/// Top-3 podium with gold/silver/bronze pillars, spotlight beams, and a
/// crown on #1. Heights animate in sequence (bronze → silver → gold) so it
/// feels like a real ceremony.
class Podium extends StatelessWidget {
  final List<LeaderboardEntry> top;
  final String? selfName;
  const Podium({super.key, required this.top, this.selfName});

  @override
  Widget build(BuildContext context) {
    final first = top.isNotEmpty ? top[0] : null;
    final second = top.length > 1 ? top[1] : null;
    final third = top.length > 2 ? top[2] : null;

    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Spotlight beams behind the podium.
          const Positioned.fill(child: _Spotlights()),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Pillar(
                entry: second,
                rank: 2,
                height: 160,
                color: const Color(0xFFC0C0C0),
                glow: const Color(0xFFE8E8E8),
                showAfter: 600.ms,
                isSelf: second?.name == selfName,
              ),
              const SizedBox(width: 8),
              _Pillar(
                entry: first,
                rank: 1,
                height: 220,
                color: AppColors.gold,
                glow: const Color(0xFFFFE066),
                showAfter: 1100.ms,
                isSelf: first?.name == selfName,
                isMvp: true,
              ),
              const SizedBox(width: 8),
              _Pillar(
                entry: third,
                rank: 3,
                height: 120,
                color: const Color(0xFFCD7F32),
                glow: const Color(0xFFD08D4A),
                showAfter: 200.ms,
                isSelf: third?.name == selfName,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  final LeaderboardEntry? entry;
  final int rank;
  final double height;
  final Color color;
  final Color glow;
  final Duration showAfter;
  final bool isSelf;
  final bool isMvp;

  const _Pillar({
    required this.entry,
    required this.rank,
    required this.height,
    required this.color,
    required this.glow,
    required this.showAfter,
    this.isSelf = false,
    this.isMvp = false,
  });

  @override
  Widget build(BuildContext context) {
    if (entry == null) return SizedBox(width: 100, height: height);

    return SizedBox(
      width: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Crown on #1.
          if (isMvp)
            const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.gold, size: 36)
                .animate(delay: showAfter + 300.ms, onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -6, duration: 1400.ms, curve: Curves.easeInOut),
          if (isMvp) const SizedBox(height: 4),
          // Avatar bubble.
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [glow, color],
              ),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.7),
                  blurRadius: isMvp ? 28 : 14,
                  spreadRadius: isMvp ? 2 : 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                entry!.name.isEmpty ? '?' : entry!.name[0].toUpperCase(),
                style: AppTypography.h2(color: Colors.black),
              ),
            ),
          )
              .animate(delay: showAfter)
              .scale(
                begin: const Offset(0, 0),
                duration: 600.ms,
                curve: AppCurves.spring,
              ),
          const SizedBox(height: 6),
          // Name + "YOU" tag.
          Text(
            entry!.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.h3(color: Colors.white).copyWith(fontSize: 14),
          ).animate(delay: showAfter + 200.ms).fadeIn(),
          if (isSelf)
            Text('YOU',
                style: AppTypography.label(color: AppColors.accent, size: 10)),
          const SizedBox(height: 4),
          // Pillar.
          AnimatedContainer(
            duration: 700.ms,
            curve: AppCurves.standard,
            width: 96,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.85),
                  color.withValues(alpha: 0.35),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border.all(color: glow.withValues(alpha: 0.7), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.45),
                  blurRadius: 22,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  Text(
                    rank == 1 ? '🥇' : (rank == 2 ? '🥈' : '🥉'),
                    style: const TextStyle(fontSize: 28),
                  )
                      .animate(delay: showAfter + 100.ms)
                      .scale(
                        begin: const Offset(0, 0),
                        duration: 500.ms,
                        curve: AppCurves.spring,
                      ),
                  const SizedBox(height: 4),
                  AnimatedScoreCounter(
                    value: entry!.score,
                    fontSize: 18,
                    pulse: isMvp,
                    duration: const Duration(milliseconds: 1100),
                  ),
                  const Text(
                    'pts',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          )
              .animate(delay: showAfter)
              .scaleY(
                begin: 0,
                end: 1,
                alignment: Alignment.bottomCenter,
                duration: 700.ms,
                curve: AppCurves.standard,
              ),
        ],
      ),
    );
  }
}

class _Spotlights extends StatelessWidget {
  const _Spotlights();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SpotlightPainter());
  }
}

class _SpotlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final h = size.height;
    // Three vertical "stage light" cones.
    for (var i = -1; i <= 1; i++) {
      final dx = cx + i * 110.0;
      final path = Path()
        ..moveTo(dx, 0)
        ..lineTo(dx - 60, h)
        ..lineTo(dx + 60, h)
        ..close();
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (i == 0 ? AppColors.gold : AppColors.primaryGlow)
                .withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
