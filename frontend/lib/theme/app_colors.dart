import 'package:flutter/material.dart';

/// Centralised colour tokens. NEVER hardcode a hex outside this file.
class AppColors {
  AppColors._();

  // ── Background scale ────────────────────────────────────────────────────────
  static const Color bgDeep = Color(0xFF070B1A);
  static const Color bgMid = Color(0xFF0F172A);
  static const Color bgVoid = Color(0xFF140D2D);
  static const Color surface = Color(0xFF1A1235);
  static const Color surfaceElevated = Color(0xFF221847);

  // ── Brand ───────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF7C3AED); // electric violet
  static const Color primaryGlow = Color(0xFFA855F7); // soft lavender glow
  static const Color secondary = Color(0xFFA855F7);
  static const Color accent = Color(0xFF06FFA5); // neon mint

  // ── Semantic ────────────────────────────────────────────────────────────────
  static const Color danger = Color(0xFFFF4D6D);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color success = Color(0xFF10B981);
  static const Color gold = Color(0xFFFFD700);

  // ── Text ────────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB8FFFFFF); // 72%
  static const Color textTertiary = Color(0x7AFFFFFF); // 48%
  static const Color textDisabled = Color(0x52FFFFFF); // 32%

  // ── Glass ───────────────────────────────────────────────────────────────────
  static const Color glassFill = Color(0x14FFFFFF); // 8% white
  static const Color glassFillStrong = Color(0x1FFFFFFF); // 12% white
  static const Color glassBorder = Color(0x24FFFFFF); // 14%
  static const Color glassBorderStrong = Color(0x3DFFFFFF); // 24%

  // ── Quiz answer palette (kept saturated for high recognition) ───────────────
  static const Color answerPink = Color(0xFFE84393);
  static const Color answerBlue = Color(0xFF3B82F6);
  static const Color answerAmber = Color(0xFFF59E0B);
  static const Color answerEmerald = Color(0xFF10B981);

  static const List<Color> answerColors = [
    answerPink,
    answerBlue,
    answerAmber,
    answerEmerald,
  ];

  static const List<List<Color>> answerGradients = [
    [Color(0xFFEC4899), Color(0xFFBE185D)],
    [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
    [Color(0xFFFBBF24), Color(0xFFD97706)],
    [Color(0xFF34D399), Color(0xFF059669)],
  ];

  static const List<IconData> answerIcons = [
    Icons.change_history_rounded,
    Icons.diamond_rounded,
    Icons.circle_rounded,
    Icons.square_rounded,
  ];

  /// Random vivid color picker (deterministic by index — useful for avatars).
  static Color avatarFor(int seed) {
    const palette = [
      Color(0xFFEC4899),
      Color(0xFF60A5FA),
      Color(0xFFFBBF24),
      Color(0xFF34D399),
      Color(0xFFA78BFA),
      Color(0xFF06FFA5),
      Color(0xFFFB7185),
      Color(0xFF38BDF8),
    ];
    return palette[seed.abs() % palette.length];
  }
}
