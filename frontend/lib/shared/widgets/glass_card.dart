import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

/// Translucent rounded container — the workhorse surface of the app.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? fill;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final bool strong;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius = AppRadius.xl,
    this.fill,
    this.borderColor,
    this.shadows,
    this.strong = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: padding,
      decoration: BoxDecoration(
        color: fill ?? (strong ? AppColors.glassFillStrong : AppColors.glassFill),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ??
              (strong ? AppColors.glassBorderStrong : AppColors.glassBorder),
        ),
        boxShadow: shadows ?? AppShadows.card,
      ),
      child: child,
    );

    if (onTap == null) return container;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: container,
      ),
    );
  }
}
