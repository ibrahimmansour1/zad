import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage admin mode vs user mode switching
class AdminModeService extends ChangeNotifier {
  static const String _adminModeKey = 'admin_mode_enabled';

  bool _isAdminMode = false;

  /// Check if currently in admin mode
  bool get isAdminMode => _isAdminMode;

  /// Check if currently in user mode
  bool get isUserMode => !_isAdminMode;

  /// Initialize and load saved mode preference
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAdminMode = prefs.getBool(_adminModeKey) ?? false;

      debugPrint(
          '[AdminMode] Initialized: ${_isAdminMode ? "Admin" : "User"} mode');
      notifyListeners();
    } catch (e) {
      debugPrint('[AdminMode] Initialization error: $e');
      _isAdminMode = false;
    }
  }

  /// Switch to admin mode
  Future<void> enableAdminMode() async {
    if (_isAdminMode) return; // Already in admin mode

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_adminModeKey, true);

      _isAdminMode = true;
      debugPrint('[AdminMode] Switched to Admin mode');
      notifyListeners();
    } catch (e) {
      debugPrint('[AdminMode] Enable admin mode error: $e');
      throw Exception('Failed to enable admin mode: $e');
    }
  }

  /// Switch to user mode
  Future<void> enableUserMode() async {
    if (!_isAdminMode) return; // Already in user mode

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_adminModeKey, false);

      _isAdminMode = false;
      debugPrint('[AdminMode] Switched to User mode');
      notifyListeners();
    } catch (e) {
      debugPrint('[AdminMode] Enable user mode error: $e');
      throw Exception('Failed to enable user mode: $e');
    }
  }

  /// Toggle between admin and user mode
  Future<void> toggleMode() async {
    if (_isAdminMode) {
      await enableUserMode();
    } else {
      await enableAdminMode();
    }
  }

  /// Get current mode as string (for UI display)
  String get currentModeLabel => _isAdminMode ? 'Admin Mode' : 'User Mode';

  /// Get icon for current mode
  String get modeIcon => _isAdminMode ? '🔧' : '👤';
}
