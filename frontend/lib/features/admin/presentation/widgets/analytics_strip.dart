import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../shared/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../data/models/question_breakdown.dart';

/// Horizontal strip of 4 KPI tiles. Used at the very top of the admin panel.
class AnalyticsStrip extends StatelessWidget {
  final RoomAnalytics analytics;
  const AnalyticsStrip({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Kpi(
          label: 'PLAYERS',
          value: '${analytics.players}',
          icon: Icons.groups_2_rounded,
          color: AppColors.primaryGlow,
        ),
        const Gap(AppSpacing.sm),
        _Kpi(
          label: 'ACCURACY',
          value: '${analytics.accuracyPct}%',
          icon: Icons.gps_fixed_rounded,
          color: AppColors.accent,
        ),
        const Gap(AppSpacing.sm),
        _Kpi(
          label: 'MVP',
          value: analytics.mvpName ?? '—',
          subValue: analytics.mvpScore > 0 ? '${analytics.mvpScore} pts' : null,
          icon: Icons.workspace_premium_rounded,
          color: AppColors.gold,
        ),
        const Gap(AppSpacing.sm),
        _Kpi(
          label: 'TOP STREAK',
          value: analytics.streakLeaderName ?? '—',
          subValue: analytics.streakLeaderCombo > 0
              ? '${analytics.streakLeaderCombo}x'
              : null,
          icon: Icons.local_fire_department_rounded,
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;
  final Color color;

  const _Kpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const Gap(AppSpacing.xs),
                Text(label, style: AppTypography.label(color: color, size: 9)),
              ],
            ),
            const Gap(AppSpacing.xs + 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h3(color: Colors.white)
                  .copyWith(fontSize: 16, height: 1.0),
            ),
            if (subValue != null) ...[
              const SizedBox(height: 2),
              Text(
                subValue!,
                style: AppTypography.caption(color: AppColors.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
