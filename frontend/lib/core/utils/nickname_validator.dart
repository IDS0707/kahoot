import '../constants/app_constants.dart';

class NicknameValidator {
  NicknameValidator._();

  /// Returns null when valid, otherwise a user-facing error message.
  static String? validate(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'Please enter a nickname';
    if (value.length < AppConstants.minNicknameLength) {
      return 'At least ${AppConstants.minNicknameLength} characters required';
    }
    if (value.length > AppConstants.maxNicknameLength) {
      return 'Max ${AppConstants.maxNicknameLength} characters';
    }
    return null;
  }

  /// Truncate + trim to make a safe display nickname.
  static String sanitize(String raw) {
    final t = raw.trim();
    return t.length > AppConstants.maxNicknameLength
        ? t.substring(0, AppConstants.maxNicknameLength)
        : t;
  }
}
