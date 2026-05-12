import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import 'glow_orb.dart';
import 'particle_field.dart';

/// Full-bleed background: gradient + breathing orbs + floating particles.
/// Compose every screen on top of this so the brand atmosphere is consistent.
class AppBackground extends StatelessWidget {
  final Widget child;

  /// When true, the orb palette skews toward danger/warning — useful on
  /// quiz screens nearing the buzzer.
  final bool intense;

  /// When false the particle layer is omitted (use on long-scroll lists
  /// to save GPU when the layer is mostly off-screen anyway).
  final bool particles;

  const AppBackground({
    super.key,
    required this.child,
    this.intense = false,
    this.particles = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = intense ? AppColors.danger : AppColors.accent;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient orbs (kept off-screen so the user only sees the glow halo).
          const Positioned(
            top: -100,
            left: -80,
            child: GlowOrb(
              color: AppColors.primary,
              size: 280,
              breathDuration: Duration(seconds: 7),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -90,
            child: GlowOrb(
              color: accent,
              size: 260,
              breathDuration: const Duration(seconds: 9),
            ),
          ),
          const Positioned(
            top: 200,
            right: -60,
            child: GlowOrb(
              color: AppColors.info,
              size: 180,
              intensity: 0.7,
              breathDuration: Duration(seconds: 11),
            ),
          ),
          if (particles) const Positioned.fill(child: ParticleField()),
          child,
        ],
      ),
    );
  }
}
