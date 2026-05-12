import 'package:flutter/material.dart';

import '../../core/utils/haptics.dart';
import '../../core/utils/sound_fx.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_durations.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

enum GlowButtonVariant { primary, success, danger, gold, custom }

/// Tactile gradient button with press scaling, glow halo, and built-in
/// loading state. Replaces every "ad-hoc" gradient button across the app.
class GlowButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final GlowButtonVariant variant;
  final Gradient? customGradient;
  final Color? customGlow;
  final double height;
  final bool fullWidth;

  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.variant = GlowButtonVariant.primary,
    this.customGradient,
    this.customGlow,
    this.height = 58,
    this.fullWidth = true,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _pressed = false;

  Gradient _gradient() {
    switch (widget.variant) {
      case GlowButtonVariant.primary:
        return AppGradients.primary;
      case GlowButtonVariant.success:
        return AppGradients.success;
      case GlowButtonVariant.danger:
        return AppGradients.danger;
      case GlowButtonVariant.gold:
        return AppGradients.gold;
      case GlowButtonVariant.custom:
        return widget.customGradient ?? AppGradients.primary;
    }
  }

  Color _glow() {
    if (widget.customGlow != null) return widget.customGlow!;
    switch (widget.variant) {
      case GlowButtonVariant.primary:
        return AppColors.primary;
      case GlowButtonVariant.success:
        return AppColors.success;
      case GlowButtonVariant.danger:
        return AppColors.danger;
      case GlowButtonVariant.gold:
        return AppColors.gold;
      case GlowButtonVariant.custom:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.isLoading;
    final glow = _glow();

    final inner = AnimatedContainer(
      duration: AppDurations.fast,
      width: widget.fullWidth ? double.infinity : null,
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: disabled ? _disabledGradient() : _gradient(),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: disabled
            ? null
            : AppShadows.glow(glow, intensity: _pressed ? 0.55 : 1.0),
      ),
      child: Center(
        child: widget.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    widget.label,
                    style: AppTypography.button(
                      color: widget.variant == GlowButtonVariant.gold
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: disabled
          ? null
          : () {
              Haptics.light();
              SoundFx.play(AppSound.click);
              widget.onPressed?.call();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: AppDurations.instant,
        curve: AppCurves.standard,
        child: inner,
      ),
    );
  }

  Gradient _disabledGradient() {
    final g = _gradient() as LinearGradient;
    return LinearGradient(
      begin: g.begin,
      end: g.end,
      colors: g.colors
          .map((c) => c.withValues(alpha: 0.32))
          .toList(growable: false),
    );
  }
}
