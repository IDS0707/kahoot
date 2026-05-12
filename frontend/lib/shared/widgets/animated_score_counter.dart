import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_durations.dart';
import '../../theme/app_typography.dart';

/// Smoothly rolls from one integer to another. Optionally pulses + glows
/// while animating to feel rewarding (used on the leaderboard podium).
class AnimatedScoreCounter extends StatelessWidget {
  final int value;
  final double fontSize;
  final Color color;
  final Duration duration;
  final bool pulse;
  final String? suffix;

  const AnimatedScoreCounter({
    super.key,
    required this.value,
    this.fontSize = 28,
    this.color = Colors.white,
    this.duration = const Duration(milliseconds: 900),
    this.pulse = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      key: ValueKey(value),
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: AppCurves.standard,
      builder: (_, v, __) {
        final t = v / (value == 0 ? 1 : value);
        final glow = pulse ? (t < 1.0 ? 1.0 : 0.4) : 0.4;
        return Text(
          suffix == null ? '$v' : '$v $suffix',
          style: AppTypography.mono(
            size: fontSize,
            color: color,
            weight: FontWeight.w900,
          ).copyWith(
            shadows: [
              Shadow(
                color: AppColors.gold.withValues(alpha: glow * 0.6),
                blurRadius: pulse ? 22 : 8,
              ),
            ],
          ),
        );
      },
    );
  }
}
