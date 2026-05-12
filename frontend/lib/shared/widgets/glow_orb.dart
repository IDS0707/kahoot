import 'package:flutter/material.dart';

/// Soft, breathing glow orb. Used for ambient depth in backgrounds.
///
/// Uses RepaintBoundary so the (heavy) blur shader doesn't invalidate
/// the rest of the tree on every animation frame.
class GlowOrb extends StatefulWidget {
  final Color color;
  final double size;
  final double intensity;
  final Duration breathDuration;

  const GlowOrb({
    super.key,
    required this.color,
    this.size = 220,
    this.intensity = 1.0,
    this.breathDuration = const Duration(seconds: 6),
  });

  @override
  State<GlowOrb> createState() => _GlowOrbState();
}

class _GlowOrbState extends State<GlowOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.breathDuration,
  )..repeat(reverse: true);

  late final Animation<double> _scale =
      Tween<double>(begin: 0.92, end: 1.08).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.07 * widget.intensity),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.16 * widget.intensity),
                  blurRadius: 90,
                  spreadRadius: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
