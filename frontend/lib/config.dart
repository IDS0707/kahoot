/// Application-wide configuration.
///
/// Replace the two constants below with your Supabase project credentials.
/// Get them from: Supabase Dashboard → Settings → API
class AppConfig {
  AppConfig._();

  /// https://<your-project-id>.supabase.co
  static const String supabaseUrl = 'https://fplaxmdkdugxwctqlejm.supabase.co';

  /// The anon / public key from your Supabase project
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwbGF4bWRrZHVneHdjdHFsZWptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3MTk3MzEsImV4cCI6MjA5MjI5NTczMX0.4SnliFu0dK6CwbigUsU2eO-l0pvtdi3K8BFD4DjxzNo';

  /// Legacy field kept so existing connect() calls compile without change.
  static const String serverUrl = supabaseUrl;
}
