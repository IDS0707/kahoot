import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Material 3 ThemeData built from our design tokens.
///
/// Also re-exports legacy [AppColors]/gradient aliases so the un-refactored
/// quiz / admin / leaderboard screens (Faza 2 work) keep compiling.
class AppTheme {
  AppTheme._();

  // ── Legacy aliases (Faza 1 keeps the old screens alive) ─────────────────
  static const Color background = AppColors.bgMid;
  static const Color backgroundDark = AppColors.bgDeep;
  static const Color accent = AppColors.primary;
  static const Color accentGlow = AppColors.primaryGlow;
  static const Color accentNeon = AppColors.accent;
  static const Color gold = AppColors.gold;

  static const Color answerRed = AppColors.answerPink;
  static const Color answerBlue = AppColors.answerBlue;
  static const Color answerYellow = AppColors.answerAmber;
  static const Color answerGreen = AppColors.answerEmerald;

  static const List<Color> answerColors = AppColors.answerColors;
  static const List<List<Color>> answerGradients = AppColors.answerGradients;
  static const List<IconData> answerIcons = AppColors.answerIcons;

  /// Per-answer glow shadow colours (alpha-baked).
  static const List<Color> answerGlow = [
    Color(0xAAEC4899),
    Color(0xAA60A5FA),
    Color(0xAAFBBF24),
    Color(0xAA34D399),
  ];

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
    colors: [AppColors.bgDeep, AppColors.bgVoid, AppColors.bgMid],
  );

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        tertiary: AppColors.primaryGlow,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.display(),
        headlineLarge: AppTypography.h1(),
        headlineMedium: AppTypography.h2(),
        headlineSmall: AppTypography.h3(),
        titleLarge: AppTypography.h3(),
        bodyLarge: AppTypography.bodyLg(),
        bodyMedium: AppTypography.body(),
        bodySmall: AppTypography.caption(),
        labelLarge: AppTypography.button(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.bgDeep,
        ),
        titleTextStyle: AppTypography.h2(),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.glassFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: AppTypography.button(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primaryGlow, width: 2),
        ),
        hintStyle: AppTypography.body(color: AppColors.textTertiary),
        labelStyle: AppTypography.caption(color: AppColors.textTertiary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.glassBorderStrong),
        ),
        titleTextStyle: AppTypography.h2(),
        contentTextStyle: AppTypography.body(),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
