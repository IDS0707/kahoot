import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_gradients.dart';
import '../../../../theme/app_shadows.dart';

/// Hero brand badge — gradient sphere with rotating ring + pulsing core.
class AnimatedLogo extends StatefulWidget {
  final double size;
  const AnimatedLogo({super.key, this.size = 110});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size * 1.6,
        height: widget.size * 1.6,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer rotating dashed ring.
            AnimatedBuilder(
              animation: _spin,
              builder: (_, __) => Transform.rotate(
                angle: _spin.value * math.pi * 2,
                child: CustomPaint(
                  size: Size(widget.size * 1.5, widget.size * 1.5),
                  painter: _RingPainter(),
                ),
              ),
            ),
            // Pulsing glow halo.
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final t = Curves.easeInOut.transform(_pulse.value);
                return Container(
                  width: widget.size * (1.0 + 0.12 * t),
                  height: widget.size * (1.0 + 0.12 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.primary,
                    boxShadow: AppShadows.glow(
                      AppColors.primary,
                      intensity: 0.7 + 0.6 * t,
                    ),
                  ),
                );
              },
            ),
            // Core icon.
            Icon(
              Icons.bolt_rounded,
              size: widget.size * 0.55,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;

    // Dashed ring.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primaryGlow.withValues(alpha: 0.5);

    const segments = 28;
    const sweep = math.pi * 2 / segments;
    for (var i = 0; i < segments; i++) {
      final start = i * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep * 0.55,
        false,
        paint,
      );
    }

    // Mint accent dots at the cardinal points.
    final dotPaint = Paint()..color = AppColors.accent;
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      canvas.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * radius,
        3.4,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
