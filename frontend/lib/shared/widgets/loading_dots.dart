import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Three pulsing dots — used as a "host is preparing" indicator.
class LoadingDots extends StatefulWidget {
  final Color color;
  final double size;

  const LoadingDots({
    super.key,
    this.color = AppColors.primaryGlow,
    this.size = 8,
  });

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_ctrl.value - i * 0.18) % 1.0;
            final scale = 0.6 + (1 - (phase - 0.5).abs() * 2).clamp(0, 1) * 0.6;
            final opacity = 0.3 + scale * 0.7;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size * 0.35),
              child: Transform.scale(
                scale: scale.toDouble(),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.4),
                        blurRadius: widget.size * 1.5,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
