import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Coin-like floating "+points" popup. Spawn one per scoring event.
/// Self-removes via [onComplete] when the animation ends.
class FloatingScore extends StatefulWidget {
  final int points;
  final bool isBonus;
  final VoidCallback? onComplete;

  const FloatingScore({
    super.key,
    required this.points,
    this.isBonus = false,
    this.onComplete,
  });

  @override
  State<FloatingScore> createState() => _FloatingScoreState();
}

class _FloatingScoreState extends State<FloatingScore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 15),
    TweenSequenceItem(tween: ConstantTween(1), weight: 55),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 30),
  ]).animate(_ctrl);

  late final Animation<double> _dy =
      Tween<double>(begin: 30, end: -40).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.4, end: 1.15)
          .chain(CurveTween(curve: Curves.elasticOut)),
      weight: 30,
    ),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 70),
  ]).animate(_ctrl);

  @override
  void initState() {
    super.initState();
    _ctrl.forward().whenComplete(() {
      if (mounted) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isBonus ? AppColors.gold : AppColors.accent;
    final glow = color.withValues(alpha: 0.6);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _dy.value),
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isBonus
                      ? [const Color(0xFFFFE066), AppColors.gold]
                      : [color.withValues(alpha: 0.85), color],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: glow,
                    blurRadius: 26,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isBonus
                        ? Icons.local_fire_department_rounded
                        : Icons.add_circle_rounded,
                    color: Colors.black,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+${widget.points}',
                    style: AppTypography.mono(
                      size: 18,
                      color: Colors.black,
                      weight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
