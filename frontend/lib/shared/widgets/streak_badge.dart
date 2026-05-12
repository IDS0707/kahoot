import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_durations.dart';
import '../../theme/app_typography.dart';

/// Live streak / combo meter. Renders a flame chip with x-multiplier text.
/// Pops on every increment.
class StreakBadge extends StatelessWidget {
  final int streak;
  final double multiplier;

  const StreakBadge({
    super.key,
    required this.streak,
    this.multiplier = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (streak < 2) return const SizedBox.shrink();

    final hot = streak >= 5;
    final color = hot ? AppColors.danger : AppColors.warning;
    final label = multiplier > 1.0
        ? '${multiplier.toStringAsFixed(2)}x'
        : '${streak}x';

    return AnimatedSwitcher(
      duration: AppDurations.medium,
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: Tween<double>(begin: 0.4, end: 1).animate(
          CurvedAnimation(parent: anim, curve: AppCurves.spring),
        ),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Container(
        key: ValueKey('streak_$streak'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hot
                ? [const Color(0xFFFB7185), AppColors.danger]
                : [const Color(0xFFFBBF24), AppColors.warning],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 16,
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.92, 0.92),
                  end: const Offset(1.12, 1.12),
                  duration: 600.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.label(color: Colors.white, size: 12),
            ),
          ],
        ),
      ),
    );
  }
}
