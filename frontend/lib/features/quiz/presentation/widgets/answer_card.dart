import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/sound_fx.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_durations.dart';
import '../../../../theme/app_typography.dart';

/// Visual phase of an answer card during a quiz round.
enum AnswerPhase {
  /// Active and tappable.
  open,

  /// Player has chosen this card; awaiting reveal.
  locked,

  /// Other cards while one is locked: dimmed but still visible.
  dimmed,

  /// Reveal phase: this card is the correct one (with badge).
  revealedCorrect,

  /// Reveal phase: player picked this and it's wrong.
  revealedWrongChosen,

  /// Reveal phase: any other wrong card.
  revealedOther,
}

/// Premium animated quiz answer button. Pure visual — no game logic.
class AnswerCard extends StatefulWidget {
  final int index; // 0..3, used to pick palette/icon
  final String label;
  final AnswerPhase phase;
  final VoidCallback? onTap;

  const AnswerCard({
    super.key,
    required this.index,
    required this.label,
    required this.phase,
    this.onTap,
  });

  @override
  State<AnswerCard> createState() => _AnswerCardState();
}

class _AnswerCardState extends State<AnswerCard> {
  bool _pressed = false;
  bool _hovered = false;

  bool get _interactive => widget.phase == AnswerPhase.open && widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: _interactive ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _interactive ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            _interactive ? () => setState(() => _pressed = false) : null,
        onTap: _interactive
            ? () {
                Haptics.medium();
                SoundFx.play(AppSound.submit);
                widget.onTap?.call();
              }
            : null,
        child: AnimatedScale(
          duration: AppDurations.instant,
          scale: _pressed ? 0.96 : 1.0,
          child: _buildSurface(context),
        ),
      ),
    );
  }

  Widget _buildSurface(BuildContext context) {
    final palette = AppColors.answerGradients[widget.index % 4];
    final icon = AppColors.answerIcons[widget.index % 4];
    final base = palette[0];
    final phase = widget.phase;

    final dim = phase == AnswerPhase.dimmed ||
        phase == AnswerPhase.revealedOther ||
        phase == AnswerPhase.revealedWrongChosen;

    final hot = phase == AnswerPhase.revealedCorrect;
    final lockedSelf = phase == AnswerPhase.locked;
    final wrongSelf = phase == AnswerPhase.revealedWrongChosen;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dim
          ? palette.map((c) => c.withValues(alpha: 0.18)).toList()
          : palette,
    );

    final borderColor = lockedSelf
        ? Colors.white
        : hot
            ? Colors.white
            : wrongSelf
                ? AppColors.danger
                : Colors.white.withValues(alpha: _hovered ? 0.45 : 0.16);

    final glowColor = hot
        ? AppColors.success
        : wrongSelf
            ? AppColors.danger
            : base;

    final glowIntensity = (() {
      if (hot) return 1.1;
      if (wrongSelf) return 0.9;
      if (lockedSelf) return 0.9;
      if (_hovered && _interactive) return 0.7;
      if (dim) return 0.0;
      return _pressed ? 0.55 : 0.4;
    })();

    Widget surface = AnimatedContainer(
      duration: AppDurations.medium,
      curve: AppCurves.standard,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
          width: lockedSelf || hot || wrongSelf ? 3 : 1,
        ),
        boxShadow: glowIntensity == 0
            ? null
            : [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.45 * glowIntensity),
                  blurRadius: 24 * glowIntensity,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.20 * glowIntensity),
                  blurRadius: 60 * glowIntensity,
                  spreadRadius: 4 * glowIntensity,
                ),
              ],
      ),
      child: Stack(
        children: [
          // Decorative shape icon top-left.
          Positioned(
            top: 12,
            left: 14,
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: dim ? 0.28 : 0.55),
              size: 18,
            ),
          ),
          // Label.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 36, 14, 14),
            child: Center(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h3(
                  color: dim ? Colors.white.withValues(alpha: 0.55) : Colors.white,
                ),
              ),
            ),
          ),
          // Reveal badges.
          if (hot)
            Positioned(
              top: 10,
              right: 12,
              child: const _RevealBadge(
                color: AppColors.success,
                icon: Icons.check_rounded,
              ).animate().scale(
                    begin: const Offset(0, 0),
                    duration: 380.ms,
                    curve: AppCurves.spring,
                  ),
            ),
          if (wrongSelf)
            Positioned(
              top: 10,
              right: 12,
              child: const _RevealBadge(
                color: AppColors.danger,
                icon: Icons.close_rounded,
              ).animate().scale(
                    begin: const Offset(0, 0),
                    duration: 380.ms,
                    curve: AppCurves.spring,
                  ),
            ),
          if (lockedSelf)
            Positioned(
              top: 10,
              right: 12,
              child: const _RevealBadge(
                color: Colors.white,
                icon: Icons.lock_rounded,
                tint: AppColors.bgDeep,
              ).animate().fadeIn(duration: 220.ms),
            ),
        ],
      ),
    );

    // Wrong-answer shake.
    if (wrongSelf) {
      surface = surface.animate().shake(
            hz: 6,
            duration: 380.ms,
            offset: const Offset(4, 0),
          );
    }

    return surface;
  }
}

class _RevealBadge extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color tint;
  const _RevealBadge({
    required this.color,
    required this.icon,
    this.tint = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Icon(icon, color: tint, size: 18),
    );
  }
}

/// Helper that maps quiz state to per-card phases. Keeps screen code clean.
class AnswerPhases {
  AnswerPhases._();

  /// Phase before the player has answered.
  static AnswerPhase preAnswer(int index, int? selected) {
    if (selected == null) return AnswerPhase.open;
    return selected == index ? AnswerPhase.locked : AnswerPhase.dimmed;
  }

  /// Phase after the reveal payload arrives.
  static AnswerPhase afterReveal(int index, int? selected, int correct) {
    if (index == correct) return AnswerPhase.revealedCorrect;
    if (selected == index) return AnswerPhase.revealedWrongChosen;
    return AnswerPhase.revealedOther;
  }
}
