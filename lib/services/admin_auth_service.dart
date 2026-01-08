import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage persistent admin authentication
class AdminAuthService {
  static const String _adminLoggedInKey = 'admin_logged_in';
  static const String _adminEmailKey = 'admin_email';
  static const String _adminSessionKey = 'admin_session_timestamp';
  static const int _sessionExpiryHours = 24; // Session expires after 24 hours

  bool _isAdminLoggedIn = false;
  String? _adminEmail;
  DateTime? _sessionTimestamp;

  /// Check if admin is currently logged in
  bool get isAdminLoggedIn => _isAdminLoggedIn && !_isSessionExpired();

  /// Get admin email if logged in
  String? get adminEmail => isAdminLoggedIn ? _adminEmail : null;

  /// Check if session is expired
  bool _isSessionExpired() {
    if (_sessionTimestamp == null) return true;
    final now = DateTime.now();
    final difference = now.difference(_sessionTimestamp!);
    return difference.inHours >= _sessionExpiryHours;
  }

  /// Initialize and load saved admin state from SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isAdminLoggedIn = prefs.getBool(_adminLoggedInKey) ?? false;
      _adminEmail = prefs.getString(_adminEmailKey);

      final sessionTimestampString = prefs.getString(_adminSessionKey);
      if (sessionTimestampString != null) {
        _sessionTimestamp = DateTime.parse(sessionTimestampString);
      }

      // Auto-logout if session expired
      if (_isAdminLoggedIn && _isSessionExpired()) {
        debugPrint('[AdminAuth] Session expired, logging out automatically');
        await logout();
      } else if (_isAdminLoggedIn) {
        debugPrint('[AdminAuth] Admin auto-logged in: $_adminEmail');
      }
    } catch (e) {
      debugPrint('[AdminAuth] Initialization error: $e');
      _isAdminLoggedIn = false;
    }
  }

  /// Save admin login state
  Future<void> login(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      await prefs.setBool(_adminLoggedInKey, true);
      await prefs.setString(_adminEmailKey, email);
      await prefs.setString(_adminSessionKey, now.toIso8601String());

      _isAdminLoggedIn = true;
      _adminEmail = email;
      _sessionTimestamp = now;

      debugPrint('[AdminAuth] Admin logged in: $email');
    } catch (e) {
      debugPrint('[AdminAuth] Login save error: $e');
      throw Exception('Failed to save admin login state: $e');
    }
  }

  /// Logout admin and clear saved state
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_adminLoggedInKey);
      await prefs.remove(_adminEmailKey);
      await prefs.remove(_adminSessionKey);

      _isAdminLoggedIn = false;
      _adminEmail = null;
      _sessionTimestamp = null;

      debugPrint('[AdminAuth] Admin logged out');
    } catch (e) {
      debugPrint('[AdminAuth] Logout error: $e');
      throw Exception('Failed to logout: $e');
    }
  }

  /// Refresh session timestamp (call on app resume or important actions)
  Future<void> refreshSession() async {
    if (!_isAdminLoggedIn) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      await prefs.setString(_adminSessionKey, now.toIso8601String());
      _sessionTimestamp = now;

      debugPrint('[AdminAuth] Session refreshed');
    } catch (e) {
      debugPrint('[AdminAuth] Session refresh error: $e');
    }
  }

  /// Get remaining session time in hours
  int? get sessionRemainingHours {
    if (!isAdminLoggedIn || _sessionTimestamp == null) return null;

    final now = DateTime.now();
    final elapsed = now.difference(_sessionTimestamp!);
    final remaining = _sessionExpiryHours - elapsed.inHours;

    return remaining > 0 ? remaining : 0;
  }

  /// Manually invalidate session (useful for security)
  Future<void> invalidateSession() async {
    await logout();
    debugPrint('[AdminAuth] Session invalidated');
  }
}
