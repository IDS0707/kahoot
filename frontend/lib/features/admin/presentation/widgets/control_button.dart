import 'package:flutter/material.dart';

import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/sound_fx.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_durations.dart';
import '../../../../theme/app_typography.dart';

/// Tactile cinematic control button used across the admin dashboard.
class ControlButton extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  const ControlButton({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  bool _pressed = false;
  bool _hovered = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final glowAlpha = !_enabled
        ? 0.0
        : _pressed
            ? 0.65
            : (_hovered ? 0.55 : 0.32);

    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            _enabled ? () => setState(() => _pressed = false) : null,
        onTap: _enabled
            ? () {
                Haptics.medium();
                SoundFx.play(AppSound.click);
                widget.onPressed?.call();
              }
            : null,
        child: AnimatedScale(
          duration: AppDurations.instant,
          scale: _pressed ? 0.97 : 1.0,
          child: AnimatedOpacity(
            duration: AppDurations.fast,
            opacity: _enabled ? 1.0 : 0.45,
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              fill: color.withValues(alpha: 0.10),
              borderColor: color.withValues(alpha: glowAlpha + 0.15),
              shadows: [
                BoxShadow(
                  color: color.withValues(alpha: glowAlpha * 0.7),
                  blurRadius: 22,
                  offset: const Offset(0, 6),
                ),
              ],
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: AppTypography.h3(color: Colors.white)
                              .copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.hint,
                          style: AppTypography.caption(),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: _enabled
                        ? color.withValues(alpha: _hovered ? 1.0 : 0.55)
                        : AppColors.textDisabled,
                    size: 14,
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
