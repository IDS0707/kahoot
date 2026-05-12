import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Responsive helpers — call as `context.isCompact`, `context.w`, etc.
extension ContextX on BuildContext {
  Size get _size => MediaQuery.sizeOf(this);
  double get w => _size.width;
  double get h => _size.height;

  EdgeInsets get safe => MediaQuery.paddingOf(this);

  /// Tight devices (small phones).
  bool get isCompact => w < AppConstants.bpCompact;

  /// Regular phones (default).
  bool get isRegular => w >= AppConstants.bpCompact && w < AppConstants.bpTablet;

  /// Tablets / web wide.
  bool get isTablet => w >= AppConstants.bpTablet;

  /// Pick a value based on form-factor. Falls back to regular when not specified.
  T responsive<T>({
    required T regular,
    T? compact,
    T? tablet,
  }) {
    if (isCompact && compact != null) return compact;
    if (isTablet && tablet != null) return tablet;
    return regular;
  }

  ThemeData get theme => Theme.of(this);
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
}
