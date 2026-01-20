import 'package:flutter/material.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/services/admin_auth_service.dart';
import 'package:zad_aldaia/services/admin_mode_service.dart';

/// Widget to toggle between Admin and User mode
class AdminModeToggle extends StatefulWidget {
  const AdminModeToggle({super.key});

  @override
  State<AdminModeToggle> createState() => _AdminModeToggleState();
}

class _AdminModeToggleState extends State<AdminModeToggle> {
  late final AdminModeService _modeService;
  late final AdminAuthService _authService;

  @override
  void initState() {
    super.initState();
    _modeService = getIt<AdminModeService>();
    _authService = getIt<AdminAuthService>();
    _modeService.addListener(_onModeChanged);
  }

  @override
  void dispose() {
    _modeService.removeListener(_onModeChanged);
    super.dispose();
  }

  void _onModeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleToggle() async {
    final isAdminMode = _modeService.isAdminMode;

    if (!_authService.isAdminLoggedIn && !isAdminMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin login required to switch modes')),
      );
      return;
    }
    await _modeService.toggleMode();
  }

  @override
  Widget build(BuildContext context) {
    // Only show toggle if admin is logged in
    if (!_authService.isAdminLoggedIn) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            _modeService.isAdminMode ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _modeService.isAdminMode
              ? Colors.red.shade300
              : Colors.blue.shade300,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _modeService.isAdminMode
                ? Icons.admin_panel_settings
                : Icons.person,
            size: 18,
            color: _modeService.isAdminMode
                ? Colors.red.shade700
                : Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            _modeService.currentModeLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _modeService.isAdminMode
                  ? Colors.red.shade700
                  : Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: _modeService.isAdminMode,
            onChanged: (_) => _handleToggle(),
            activeColor: Colors.red.shade700,
            inactiveThumbColor: Colors.blue.shade700,
          ),
        ],
      ),
    );
  }
}

/// Compact admin mode indicator
class AdminModeIndicator extends StatefulWidget {
  const AdminModeIndicator({super.key});

  @override
  State<AdminModeIndicator> createState() => _AdminModeIndicatorState();
}

class _AdminModeIndicatorState extends State<AdminModeIndicator> {
  late final AdminModeService _modeService;

  @override
  void initState() {
    super.initState();
    _modeService = getIt<AdminModeService>();
    _modeService.addListener(_onModeChanged);
  }

  @override
  void dispose() {
    _modeService.removeListener(_onModeChanged);
    super.dispose();
  }

  void _onModeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_modeService.isAdminMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.admin_panel_settings,
              size: 14, color: Colors.red.shade700),
          const SizedBox(width: 4),
          Text(
            'ADMIN',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small icon button for quick mode switching in app bars
class AdminModeQuickToggle extends StatefulWidget {
  const AdminModeQuickToggle({super.key});

  @override
  State<AdminModeQuickToggle> createState() => _AdminModeQuickToggleState();
}

class _AdminModeQuickToggleState extends State<AdminModeQuickToggle> {
  late final AdminModeService _modeService;
  late final AdminAuthService _authService;

  @override
  void initState() {
    super.initState();
    _modeService = getIt<AdminModeService>();
    _authService = getIt<AdminAuthService>();
    _modeService.addListener(_onModeChanged);
  }

  @override
  void dispose() {
    _modeService.removeListener(_onModeChanged);
    super.dispose();
  }

  void _onModeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleMode() async {
    final isAdminMode = _modeService.isAdminMode;

    if (!_authService.isAdminLoggedIn && !isAdminMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login as admin to enable Admin Mode')),
      );
      return;
    }

    await _modeService.toggleMode();
  }

  @override
  Widget build(BuildContext context) {
    // Only show toggle if admin is logged in
    if (!_authService.isAdminLoggedIn) {
      return const SizedBox.shrink();
    }

    final isAdmin = _modeService.isAdminMode;

    return IconButton(
      tooltip: isAdmin ? 'Switch to User Mode' : 'Switch to Admin Mode',
      onPressed: _toggleMode,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Icon(
          isAdmin ? Icons.admin_panel_settings : Icons.person,
          key: ValueKey(isAdmin),
          color: isAdmin ? Colors.red.shade700 : Colors.blue.shade700,
        ),
      ),
    );
  }
}
