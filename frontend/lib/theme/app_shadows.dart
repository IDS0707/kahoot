import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Layered shadow recipes. Combine ambient + glow for premium depth.
class AppShadows {
  AppShadows._();

  /// Ambient depth — used on every elevated surface.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// Glow recipe for primary CTAs.
  static List<BoxShadow> glow(Color color, {double intensity = 1.0}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.45 * intensity),
          blurRadius: 28 * intensity,
          spreadRadius: 1 * intensity,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.18 * intensity),
          blurRadius: 60 * intensity,
          spreadRadius: 6 * intensity,
        ),
      ];

  /// Soft inner-feeling shadow for chips/labels.
  static const List<BoxShadow> chip = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> primaryGlow({double intensity = 1.0}) =>
      glow(AppColors.primary, intensity: intensity);

  static List<BoxShadow> accentGlow({double intensity = 1.0}) =>
      glow(AppColors.accent, intensity: intensity);
}
