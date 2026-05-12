import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/utils/haptics.dart';
import '../../core/utils/sound_fx.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Circular countdown with phase-based colour transitions, breathing glow,
/// and dramatic urgency at the buzzer.
///
/// Drives:
///   - colour shift  : green → mint → amber → red
///   - pulse glow    : intensifies under 5 s
///   - shake effect  : last 3 s
///   - haptic ticks  : 5,4,3,2,1 (light) + final (heavy)
///
/// Stateless from a logic perspective: parent passes [secondsLeft] / [total]
/// each frame; the widget animates between them.
class CinematicTimer extends StatefulWidget {
  final int secondsLeft;
  final int total;
  final double size;

  /// Fires once when the timer crosses each integer second under 6 s.
  final void Function(int second)? onCriticalTick;

  const CinematicTimer({
    super.key,
    required this.secondsLeft,
    required this.total,
    this.size = 110,
    this.onCriticalTick,
  });

  @override
  State<CinematicTimer> createState() => _CinematicTimerState();
}

class _CinematicTimerState extends State<CinematicTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  int? _lastSecond;

  @override
  void didUpdateWidget(covariant CinematicTimer old) {
    super.didUpdateWidget(old);
    final s = widget.secondsLeft;
    if (s != _lastSecond) {
      _lastSecond = s;
      // Critical-zone haptic + sound + callback.
      if (s > 0 && s <= 5) {
        Haptics.selection();
        SoundFx.play(AppSound.countdownTick);
        widget.onCriticalTick?.call(s);
      } else if (s == 0) {
        Haptics.heavy();
        SoundFx.play(AppSound.countdownEnd);
        widget.onCriticalTick?.call(0);
      }
      // Speed up the pulse near the end.
      final critical = s <= 5;
      final newDur = Duration(milliseconds: critical ? 380 : 800);
      if (_pulse.duration != newDur) {
        _pulse.duration = newDur;
        if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color _phaseColor() {
    final t = widget.secondsLeft / math.max(widget.total, 1);
    if (t > 0.66) return AppColors.success;
    if (t > 0.4) return AppColors.accent;
    if (t > 0.2) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final color = _phaseColor();
    final critical = widget.secondsLeft <= 5;
    final shaking = widget.secondsLeft > 0 && widget.secondsLeft <= 3;
    final progress =
        (widget.secondsLeft / math.max(widget.total, 1)).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) {
          final pulseT = Curves.easeInOut.transform(_pulse.value);
          final glow = critical ? 0.55 + 0.6 * pulseT : 0.35 + 0.25 * pulseT;
          final shakeDx =
              shaking ? math.sin(pulseT * math.pi * 6) * 2.5 : 0.0;
          final scale = critical ? 1.0 + 0.06 * pulseT : 1.0;

          return Transform.translate(
            offset: Offset(shakeDx, 0),
            child: Transform.scale(
              scale: scale,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow halo.
                    Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: glow.clamp(0.0, 1.0)),
                            blurRadius: critical ? 36 : 22,
                            spreadRadius: critical ? 4 : 1,
                          ),
                        ],
                      ),
                    ),
                    // Track + progress arc.
                    SizedBox.expand(
                      child: CustomPaint(
                        painter: _RingPainter(progress: progress, color: color),
                      ),
                    ),
                    // Inner backplate.
                    Container(
                      margin: EdgeInsets.all(widget.size * 0.18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.12),
                        border: Border.all(
                          color: color.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                    ),
                    // Number.
                    Text(
                      '${widget.secondsLeft}',
                      style: AppTypography.mono(
                        size: widget.size * 0.36,
                        color: color,
                        weight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 1.0 = full, 0.0 = empty
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    final stroke = size.width * 0.07;

    // Track.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.08),
    );

    // Progress arc (starts at top, sweeps clockwise as time elapses).
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          color,
          color.withValues(alpha: 0.6),
          color,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      paint,
    );

    // Tip dot (lights up the moving end of the arc).
    if (progress > 0.0 && progress < 1.0) {
      final angle = -math.pi / 2 + math.pi * 2 * progress;
      final tip = center +
          Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(
        tip,
        stroke * 0.7,
        Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
