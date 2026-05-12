import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../shared/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_durations.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../data/models/question_breakdown.dart';

/// Live vote distribution per answer slot. Each row animates its width as
/// new answers stream in.
class AnswerHeatmap extends StatelessWidget {
  final List<String> options;
  final QuestionBreakdown breakdown;
  final int? correctIndex;

  const AnswerHeatmap({
    super.key,
    required this.options,
    required this.breakdown,
    this.correctIndex,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = breakdown.buckets.isEmpty
        ? 1
        : breakdown.buckets.fold<int>(
            0, (m, b) => b.count > m ? b.count : m).clamp(1, 1 << 30);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll_rounded,
                  color: AppColors.primaryGlow, size: 16),
              const Gap(AppSpacing.xs),
              Text('LIVE ANSWER HEATMAP',
                  style: AppTypography.label(color: AppColors.primaryGlow)),
              const Spacer(),
              Text(
                '${breakdown.totalAnswered} answers · ${breakdown.correctCount} correct',
                style: AppTypography.caption(color: AppColors.textTertiary),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          for (int i = 0; i < options.length; i++) ...[
            _Row(
              index: i,
              label: options[i],
              count: breakdown.countFor(i),
              maxCount: maxCount,
              isCorrect: correctIndex != null && i == correctIndex,
            ),
            if (i < options.length - 1) const Gap(AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final int index;
  final String label;
  final int count;
  final int maxCount;
  final bool isCorrect;

  const _Row({
    required this.index,
    required this.label,
    required this.count,
    required this.maxCount,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.answerColors[index % 4];
    final pct = maxCount == 0 ? 0.0 : count / maxCount;

    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Icon(
            AppColors.answerIcons[index % 4],
            color: color,
            size: 14,
          ),
        ),
        const Gap(AppSpacing.xs),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              LayoutBuilder(
                builder: (_, c) => AnimatedContainer(
                  duration: AppDurations.medium,
                  curve: AppCurves.standard,
                  height: 26,
                  width: c.maxWidth * pct,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.95),
                        color.withValues(alpha: 0.55),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(
                            color: Colors.white,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isCorrect) ...[
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 14),
                        const Gap(AppSpacing.xs),
                      ],
                      Text(
                        '$count',
                        style: AppTypography.mono(
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
