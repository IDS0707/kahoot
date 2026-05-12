import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Reusable confetti cannon. Pass [trigger]; whenever it changes the cannon
/// fires once. Two presets: small `combo` burst, large `victory` cascade.
enum ConfettiPreset { combo, victory }

class CelebrationConfetti extends StatefulWidget {
  /// Anything that uniquely identifies the next firing event. Often the
  /// streak count or the game-over timestamp.
  final Object? trigger;
  final ConfettiPreset preset;
  final ConfettiController? controller;

  /// Where on screen the cannon sits. Defaults to top-center for victory and
  /// center for combo bursts.
  final Alignment? alignment;

  const CelebrationConfetti({
    super.key,
    this.trigger,
    this.preset = ConfettiPreset.combo,
    this.controller,
    this.alignment,
  });

  @override
  State<CelebrationConfetti> createState() => _CelebrationConfettiState();
}

class _CelebrationConfettiState extends State<CelebrationConfetti> {
  late final ConfettiController _ctrl =
      widget.controller ??
          ConfettiController(
            duration: widget.preset == ConfettiPreset.victory
                ? const Duration(seconds: 5)
                : const Duration(milliseconds: 900),
          );

  @override
  void didUpdateWidget(covariant CelebrationConfetti old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger && widget.trigger != null) {
      _fire();
    }
  }

  void _fire() {
    if (_ctrl.state == ConfettiControllerState.playing) {
      _ctrl.stop();
    }
    _ctrl.play();
  }

  @override
  void dispose() {
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVictory = widget.preset == ConfettiPreset.victory;
    final colors = isVictory
        ? const [
            AppColors.gold,
            AppColors.primaryGlow,
            AppColors.accent,
            AppColors.warning,
            AppColors.danger,
            AppColors.info,
            Colors.white,
          ]
        : const [
            AppColors.accent,
            AppColors.primaryGlow,
            AppColors.gold,
            Colors.white,
          ];

    return Align(
      alignment: widget.alignment ??
          (isVictory ? Alignment.topCenter : Alignment.center),
      child: ConfettiWidget(
        confettiController: _ctrl,
        blastDirectionality: isVictory
            ? BlastDirectionality.explosive
            : BlastDirectionality.directional,
        blastDirection: isVictory ? 0 : math.pi / 2,
        emissionFrequency: isVictory ? 0.05 : 0.18,
        numberOfParticles: isVictory ? 26 : 16,
        gravity: isVictory ? 0.18 : 0.32,
        maxBlastForce: isVictory ? 28 : 16,
        minBlastForce: isVictory ? 8 : 6,
        particleDrag: 0.05,
        shouldLoop: false,
        colors: colors,
      ),
    );
  }
}
