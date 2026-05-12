import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_chip.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_durations.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

/// Glassy question surface with animated entry. Re-keys per [questionIndex]
/// so AnimatedSwitcher / animate() picks up the transition automatically.
class QuestionCard extends StatelessWidget {
  final int questionIndex;
  final int totalQuestions;
  final String question;
  final String? difficulty;
  final String? category;

  const QuestionCard({
    super.key,
    required this.questionIndex,
    required this.totalQuestions,
    required this.question,
    this.difficulty,
    this.category,
  });

  Color _difficultyColor() {
    switch (difficulty) {
      case 'easy':
        return AppColors.success;
      case 'hard':
        return AppColors.danger;
      case 'medium':
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor();

    return AnimatedSwitcher(
      duration: AppDurations.slow,
      switchInCurve: AppCurves.spring,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.18),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: AppCurves.standard)),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(
              CurvedAnimation(parent: anim, curve: AppCurves.spring),
            ),
            child: child,
          ),
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey('question_$questionIndex'),
        child: GlassCard(
          strong: true,
          padding: const EdgeInsets.all(AppSpacing.xl),
          shadows: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.32),
              blurRadius: 38,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
            const BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NeonChip(
                    label: 'Q ${questionIndex + 1} / $totalQuestions',
                    color: AppColors.primaryGlow,
                    icon: Icons.help_outline_rounded,
                    fontSize: 11,
                  ),
                  const Gap(AppSpacing.sm),
                  if (difficulty != null)
                    NeonChip(
                      label: difficulty!.toUpperCase(),
                      color: diffColor,
                      filled: true,
                      fontSize: 10,
                    ),
                  const Spacer(),
                  if (category != null)
                    NeonChip(
                      label: _formatCategory(category!),
                      color: AppColors.accent,
                      icon: Icons.school_rounded,
                      fontSize: 10,
                    ),
                ],
              ),
              const Gap(AppSpacing.lg),
              Center(
                child: Text(
                  question,
                  textAlign: TextAlign.center,
                  style: AppTypography.h2().copyWith(
                    fontSize: 22,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ).animate().shimmer(
              delay: 350.ms,
              duration: 1100.ms,
              color: AppColors.primaryGlow.withValues(alpha: 0.15),
            ),
      ),
    );
  }

  String _formatCategory(String c) =>
      c.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}
