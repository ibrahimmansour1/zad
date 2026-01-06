import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/supabase_client.dart';

/// Service for managing authentication
/// Handles sign up, sign in, sign out, and auth state
class AuthService {
  /// Sign up a new user with email and password
  ///
  /// Returns the AuthResponse containing user and session
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await Supa.client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      return response;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  /// Sign in an existing user with email and password
  ///
  /// Returns the AuthResponse containing user and session
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await Supa.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await Supa.client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Get the current authenticated user
  User? get currentUser => Supa.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => Supa.isAuthenticated;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => Supa.authStateChanges;

  /// Reset password for a user
  /// Sends a password reset email
  Future<void> resetPassword(String email) async {
    try {
      await Supa.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Update user metadata
  Future<UserResponse> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await Supa.client.auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
          data: data,
        ),
      );

      return response;
    } catch (e) {
      throw Exception('User update failed: $e');
    }
  }

  /// Sign in with OAuth provider (Google, Apple, etc.)
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    try {
      final response = await Supa.client.auth.signInWithOAuth(provider);
      return response;
    } catch (e) {
      throw Exception('OAuth sign in failed: $e');
    }
  }

  /// Refresh the current session
  Future<AuthResponse> refreshSession() async {
    try {
      final response = await Supa.client.auth.refreshSession();
      return response;
    } catch (e) {
      throw Exception('Session refresh failed: $e');
    }
  }

  /// Get the current session
  Session? get currentSession => Supa.client.auth.currentSession;
}
