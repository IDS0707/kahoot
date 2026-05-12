import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_durations.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../game/data/models/player.dart';

/// Glassy tile shown for each connected player in the lobby grid.
class PlayerTile extends StatelessWidget {
  final Player player;
  final int index;
  final bool isMe;

  const PlayerTile({
    super.key,
    required this.player,
    required this.index,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.avatarFor(index);

    return AnimatedContainer(
      duration: AppDurations.medium,
      curve: AppCurves.standard,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.32),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isMe
              ? AppColors.accent.withValues(alpha: 0.7)
              : color.withValues(alpha: 0.42),
          width: isMe ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withValues(alpha: 0.4),
                child: Text(
                  player.name.isEmpty ? '?' : player.name[0].toUpperCase(),
                  style: AppTypography.h3(),
                ),
              ),
              if (player.isHost)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.7),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.star_rounded,
                        size: 14, color: Colors.black),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption(
                color: Colors.white,
                weight: FontWeight.w800,
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(height: 2),
            Text(
              'YOU',
              style: AppTypography.label(color: AppColors.accent, size: 9),
            ),
          ],
        ],
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.6, 0.6),
          delay: Duration(milliseconds: index * 60),
          duration: 380.ms,
          curve: AppCurves.spring,
        )
        .fadeIn(delay: Duration(milliseconds: index * 60));
  }
}
