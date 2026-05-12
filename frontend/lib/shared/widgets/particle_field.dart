import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A field of slowly-floating glowing particles. Pure-canvas, GPU-cheap.
/// Drop into any Stack as a full-bleed layer.
class ParticleField extends StatefulWidget {
  final int count;
  final List<Color>? colors;
  final double maxRadius;
  final double minRadius;
  final double speed;

  const ParticleField({
    super.key,
    this.count = 26,
    this.colors,
    this.minRadius = 1.6,
    this.maxRadius = 3.6,
    this.speed = 0.06,
  });

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  late final List<_Particle> _particles;
  final _rand = math.Random(42);

  @override
  void initState() {
    super.initState();
    final palette = widget.colors ??
        [
          AppColors.primaryGlow,
          AppColors.accent,
          AppColors.info,
          Colors.white,
        ];
    _particles = List.generate(widget.count, (i) {
      return _Particle(
        seedX: _rand.nextDouble(),
        seedY: _rand.nextDouble(),
        radius:
            widget.minRadius + _rand.nextDouble() * (widget.maxRadius - widget.minRadius),
        color: palette[i % palette.length],
        phase: _rand.nextDouble() * math.pi * 2,
        wobble: 0.4 + _rand.nextDouble() * 0.7,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            painter: _ParticlePainter(
              t: _ctrl.value,
              particles: _particles,
              speed: widget.speed,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double seedX;
  final double seedY;
  final double radius;
  final Color color;
  final double phase;
  final double wobble;

  _Particle({
    required this.seedX,
    required this.seedY,
    required this.radius,
    required this.color,
    required this.phase,
    required this.wobble,
  });
}

class _ParticlePainter extends CustomPainter {
  final double t; // 0..1
  final List<_Particle> particles;
  final double speed;

  _ParticlePainter({
    required this.t,
    required this.particles,
    required this.speed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (final p in particles) {
      final phase = p.phase + t * math.pi * 2 * speed * 12;
      // Gentle vertical drift + horizontal sine wobble.
      final dy = ((p.seedY - t * 0.35) % 1.0) * size.height;
      final dx = (p.seedX * size.width) +
          math.sin(phase) * (12 + 18 * p.wobble);

      final color = p.color.withValues(alpha: 0.65);

      // Outer glow.
      canvas.drawCircle(
        Offset(dx, dy),
        p.radius * 2.4,
        Paint()
          ..color = color.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // Core.
      canvas.drawCircle(
        Offset(dx, dy),
        p.radius,
        glowPaint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}
