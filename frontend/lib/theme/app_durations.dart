import 'package:flutter/animation.dart';

/// Standard animation durations + curves. Premium motion has consistent timing.
class AppDurations {
  AppDurations._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration xslow = Duration(milliseconds: 650);
  static const Duration cinematic = Duration(milliseconds: 900);
}

class AppCurves {
  AppCurves._();

  /// Apple-style emphasized easing.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Standard easing for most transitions.
  static const Curve standard = Curves.easeOutCubic;

  /// Springy enter — buttons, badges popping in.
  static const Curve spring = Curves.elasticOut;

  /// Gentle bounce — score counters, podium settling.
  static const Curve bounceOut = Curves.elasticOut;
}
