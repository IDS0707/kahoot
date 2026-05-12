import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Small pill — "HOST", "REALTIME", "Q 3 / 10", room codes, etc.
class NeonChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color? textColor;
  final bool filled;
  final double fontSize;

  const NeonChip({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.accent,
    this.textColor,
    this.filled = false,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: filled ? Colors.black : fg, size: fontSize + 2),
            const SizedBox(width: AppSpacing.xs + 2),
          ],
          Text(
            label,
            style: AppTypography.label(
              color: filled ? Colors.black : fg,
              size: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
