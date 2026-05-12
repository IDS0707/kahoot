import 'package:flutter/services.dart';

/// Centralised haptic API. Stub-friendly so individual screens don't have to
/// know which platform service to call. Always silently no-op on errors.
class Haptics {
  Haptics._();

  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> heavy() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Used on success (correct answer, level up).
  static Future<void> success() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Used on failure (wrong answer, error).
  static Future<void> error() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
