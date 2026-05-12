import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Type scale. Display = Space Grotesk, Body = Inter.
/// Always go through these helpers — never call GoogleFonts directly.
class AppTypography {
  AppTypography._();

  // ── Display (Space Grotesk) ─────────────────────────────────────────────────
  static TextStyle display({double size = 44}) => GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: FontWeight.w900,
        height: 1.05,
        letterSpacing: -1.2,
        color: AppColors.textPrimary,
      );

  static TextStyle h1({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.6,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle h2({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle h3({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: color ?? AppColors.textPrimary,
      );

  // ── Body (Inter) ────────────────────────────────────────────────────────────
  static TextStyle bodyLg({Color? color, FontWeight? weight}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: weight ?? FontWeight.w500,
        height: 1.5,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle body({Color? color, FontWeight? weight}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: weight ?? FontWeight.w500,
        height: 1.45,
        color: color ?? AppColors.textSecondary,
      );

  static TextStyle caption({Color? color, FontWeight? weight}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: weight ?? FontWeight.w500,
        height: 1.4,
        color: color ?? AppColors.textTertiary,
      );

  // ── Tactical labels (uppercase, letter-spaced) ──────────────────────────────
  static TextStyle label({Color? color, double size = 11}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        color: color ?? AppColors.textTertiary,
      );

  // ── Mono / numbers (timer, scores) ──────────────────────────────────────────
  static TextStyle mono({double size = 18, Color? color, FontWeight? weight}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w800,
        color: color ?? AppColors.textPrimary,
        height: 1.0,
      );

  static TextStyle button({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: color ?? AppColors.textPrimary,
      );
}
