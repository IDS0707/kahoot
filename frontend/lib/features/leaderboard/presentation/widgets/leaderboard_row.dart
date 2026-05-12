import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../shared/widgets/animated_score_counter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_durations.dart';
import '../../../../theme/app_gradients.dart';
import '../../../../theme/app_typography.dart';
import '../../data/models/leaderboard_entry.dart';

/// Row 4+ of the leaderboard. Top-3 are rendered as a podium separately.
class LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int index; // for staggered intro animation
  final bool isMe;

  const LeaderboardRow({
    super.key,
    required this.entry,
    required this.index,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.avatarFor(entry.rank);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.accent.withValues(alpha: 0.18)
            : AppColors.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? AppColors.accent.withValues(alpha: 0.7)
              : AppColors.glassBorder,
          width: isMe ? 2 : 1,
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('#${entry.rank}',
                textAlign: TextAlign.center,
                style: AppTypography.label(
                  color: AppColors.textTertiary,
                  size: 13,
                )),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.4),
            child: Text(
              entry.name.isEmpty ? '?' : entry.name[0].toUpperCase(),
              style: AppTypography.h3(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyLg(weight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppGradients.gold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScoreCounter(
                  value: entry.score,
                  fontSize: 13,
                  color: Colors.black,
                  duration: const Duration(milliseconds: 700),
                ),
                const SizedBox(width: 4),
                const Text('pts',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    )),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 1400 + index * 90))
        .slideX(
          begin: 0.4,
          duration: 320.ms,
          curve: AppCurves.standard,
        )
        .fadeIn();
  }
}
