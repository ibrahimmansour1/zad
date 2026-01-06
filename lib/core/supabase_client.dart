import 'package:supabase_flutter/supabase_flutter.dart';

class Supa {
  static late final SupabaseClient client;

  static Future<void> init({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    client = Supabase.instance.client;
  }

  /// Get the current authenticated user
  static User? get currentUser => client.auth.currentUser;

  /// Get the current user's ID (convenience getter)
  static String? get currentUserId => currentUser?.id;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get auth state changes stream
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  /// Get the current session
  static Session? get currentSession => client.auth.currentSession;

  /// Check if the session is expired
  static bool get isSessionExpired {
    final session = currentSession;
    if (session == null) return true;
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= expiresAt;
  }
}
