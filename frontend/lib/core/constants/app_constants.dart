/// App-wide constants. Layout breakpoints, magic strings, etc.
class AppConstants {
  AppConstants._();

  // ── Responsive breakpoints ──────────────────────────────────────────────────
  static const double bpCompact = 380; // tight phones
  static const double bpRegular = 600; // most phones
  static const double bpTablet = 840; // tablets / large web

  // ── Game ────────────────────────────────────────────────────────────────────
  static const String adminCode = 'admin771';
  static const int defaultQuestionTime = 15;
  static const int maxNicknameLength = 20;
  static const int minNicknameLength = 2;

  // ── Network ─────────────────────────────────────────────────────────────────
  static const Duration realtimeReconnectDelay = Duration(seconds: 3);
  static const Duration roomUpdateDebounce = Duration(milliseconds: 120);
}
