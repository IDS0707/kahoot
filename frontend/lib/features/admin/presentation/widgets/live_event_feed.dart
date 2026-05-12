import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../../shared/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_durations.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../data/models/question_breakdown.dart';

/// Scrolling feed of recent admin events. Each new entry slides in from the
/// top with a coloured chip.
class LiveEventFeed extends StatelessWidget {
  final List<AdminEvent> events;
  const LiveEventFeed({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.podcasts_rounded,
                  color: AppColors.accent, size: 16),
              const Gap(AppSpacing.xs),
              Text('LIVE EVENT FEED',
                  style: AppTypography.label(color: AppColors.accent)),
            ],
          ),
          const Gap(AppSpacing.md),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'No events yet…',
                style: AppTypography.caption(color: AppColors.textTertiary),
              ),
            )
          else
            for (var i = 0; i < events.length && i < 8; i++)
              _Row(event: events[i], index: i),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final AdminEvent event;
  final int index;
  const _Row({required this.event, required this.index});

  Color _color() {
    switch (event.kind) {
      case AdminEventKind.join:
        return AppColors.accent;
      case AdminEventKind.leave:
        return AppColors.warning;
      case AdminEventKind.answerCorrect:
        return AppColors.success;
      case AdminEventKind.answerWrong:
        return AppColors.danger;
      case AdminEventKind.system:
        return AppColors.primaryGlow;
    }
  }

  IconData _icon() {
    switch (event.kind) {
      case AdminEventKind.join:
        return Icons.login_rounded;
      case AdminEventKind.leave:
        return Icons.logout_rounded;
      case AdminEventKind.answerCorrect:
        return Icons.check_rounded;
      case AdminEventKind.answerWrong:
        return Icons.close_rounded;
      case AdminEventKind.system:
        return Icons.bolt_rounded;
    }
  }

  String _stamp(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Icon(_icon(), color: c, size: 13),
          const Gap(AppSpacing.xs + 2),
          Expanded(
            child: Text(
              event.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption(color: Colors.white),
            ),
          ),
          Text(
            _stamp(event.at),
            style: AppTypography.mono(size: 10, color: AppColors.textTertiary),
          ),
        ],
      ),
    )
        // Only animate the freshest entries — older ones are static.
        .animate(target: index < 3 ? 1 : 0)
        .slideY(begin: -0.4, duration: AppDurations.fast, curve: AppCurves.standard)
        .fadeIn(duration: AppDurations.fast);
  }
}
