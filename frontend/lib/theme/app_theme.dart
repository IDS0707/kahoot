import 'package:flutter/material.dart';

/// Modern dark theme – deep space gradient + neon accents.
class AppTheme {
  AppTheme._();

  // ── Core palette ────────────────────────────────────────────────────────────
  static const Color bgTop = Color(0xFF0D0A1E); // near-black indigo
  static const Color bgMid = Color(0xFF1A0A3C); // deep purple-black
  static const Color bgBottom = Color(0xFF0A0A2E); // midnight blue

  // Keep old names as aliases so existing screens compile without changes
  static const Color background = bgMid;
  static const Color backgroundDark = bgBottom;

  static const Color accent = Color(0xFF7C3AED); // electric violet
  static const Color accentGlow = Color(0xFFA78BFA); // soft lavender glow
  static const Color accentNeon = Color(0xFF06FFA5); // neon mint
  static const Color gold = Color(0xFFFFD700);

  // ── Glassmorphism helpers ────────────────────────────────────────────────────
  static Color glassWhite(double opacity) => Colors.white.withOpacity(opacity);
  static const Color glassBorder = Color(0x22FFFFFF);

  // ── Answer button gradients (4 Kahoot colors, modern tones) ────────────────
  static const Color answerRed = Color(0xFFE84393); // hot pink
  static const Color answerBlue = Color(0xFF3B82F6); // electric blue
  static const Color answerYellow = Color(0xFFF59E0B); // amber
  static const Color answerGreen = Color(0xFF10B981); // emerald

  static const List<Color> answerColors = [
    answerRed,
    answerBlue,
    answerYellow,
    answerGreen,
  ];

  // Darker glow shades for shadow
  static const List<Color> answerGlow = [
    Color(0xAAE84393),
    Color(0xAA3B82F6),
    Color(0xAAF59E0B),
    Color(0xAA10B981),
  ];

  static const List<List<Color>> answerGradients = [
    [Color(0xFFE84393), Color(0xFFBE185D)],
    [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFF10B981), Color(0xFF059669)],
  ];

  // ── Answer shape icons ───────────────────────────────────────────────────────
  static const List<IconData> answerIcons = [
    Icons.change_history_rounded,
    Icons.diamond_rounded,
    Icons.circle_rounded,
    Icons.square_rounded,
  ];

  // ── Main gradient ────────────────────────────────────────────────────────────
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgTop, bgMid, bgBottom],
    stops: [0.0, 0.5, 1.0],
  );

  // ── Material ThemeData ───────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgTop,
        colorScheme: ColorScheme.dark(
          primary: accent,
          secondary: accentNeon,
          surface: const Color(0xFF1E1040),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 17),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0x18FFFFFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0x30FFFFFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0x30FFFFFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFA78BFA), width: 2),
          ),
          hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        cardTheme: CardThemeData(
          color: const Color(0x14FFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0x20FFFFFF)),
          ),
          elevation: 0,
        ),
      );
}
