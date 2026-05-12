import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gradient recipes used across the app. Centralised so we can re-tune
/// the whole brand in one place.
class AppGradients {
  AppGradients._();

  /// Full-screen background — deep space.
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
    colors: [AppColors.bgDeep, AppColors.bgVoid, AppColors.bgMid],
  );

  /// Primary CTA — violet → mint diagonal.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.accent],
  );

  /// Aurora — used for hero titles via ShaderMask.
  static const LinearGradient aurora = LinearGradient(
    colors: [
      AppColors.textPrimary,
      AppColors.primaryGlow,
      AppColors.accent,
    ],
  );

  /// Subtle title shimmer (white → lavender).
  static const LinearGradient titleShimmer = LinearGradient(
    colors: [Colors.white, AppColors.primaryGlow],
  );

  /// Gold gradient for HOST badges, podium #1.
  static const LinearGradient gold = LinearGradient(
    colors: [Color(0xFFFFE066), AppColors.gold, Color(0xFFE0A800)],
  );

  /// Danger CTA.
  static const LinearGradient danger = LinearGradient(
    colors: [Color(0xFFFB7185), AppColors.danger],
  );

  /// Success / play button.
  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF34D399), AppColors.success],
  );

  /// Returns a 2-stop gradient for a quiz-answer index (0-3).
  static LinearGradient answer(int index) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppColors.answerGradients[index % 4],
      );
}
