import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/helpers/admin_permissions.dart';
import 'package:zad_aldaia/core/supabase_client.dart';

/// Service to manage admin permissions with caching
class AdminPermissionService {
  AdminPermissionService();

  Set<AdminPermission> _grantedPermissions = {};
  DateTime _passwordExpiry = DateTime.now();

  final SupabaseClient _supabase = Supa.client;

  // Cache remote secrets per operation to avoid repeated network calls.
  final Map<AdminPermission, _PermissionSecret?> _secretCache = {};
  final Duration _secretCacheTtl = const Duration(minutes: 10);

  // 5 minute password cache
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Verify if admin has permission for an operation
  /// Shows password dialog if needed, caches result for 5 minutes
  Future<bool> verifyPermission(
    BuildContext context,
    AdminPermission permission, {
    required String operationType,
    String? itemName,
  }) async {
    // Check if cached password still valid
    if (_isCachedPermissionValid(permission)) {
      return true;
    }

    // Show password dialog to get password - returns bool not string
    final verified = await _showPasswordDialog(
      context: context,
      permission: permission,
      operationType: operationType,
      itemName: itemName,
    );

    return verified;
  }

  /// Show password dialog and verify
  Future<bool> _showPasswordDialog({
    required BuildContext context,
    required AdminPermission permission,
    required String operationType,
    String? itemName,
  }) async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    String? errorMessage;
    bool verifying = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock, color: Colors.red.shade700),
              const SizedBox(width: 12),
              const Expanded(child: Text('Admin Verification')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'You are about to $operationType${itemName != null ? ' "$itemName"' : ''}.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Text('Please enter the admin password to continue:',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Admin Password',
                  hintText: 'Enter password',
                  errorText: errorMessage,
                  prefixIcon: const Icon(Icons.password),
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onSubmitted: (_) async {
                  if (verifying) return;
                  setState(() {
                    verifying = true;
                    errorMessage = null;
                  });

                  final password = passwordController.text;
                  final ok = await _validatePermissionPassword(
                    permission,
                    password,
                  );

                  if (ok) {
                    Navigator.of(context).pop(true);
                  } else {
                    setState(() {
                      verifying = false;
                      errorMessage = 'Incorrect password';
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child:
                  Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: verifying
                  ? null
                  : () async {
                      setState(() {
                        verifying = true;
                        errorMessage = null;
                      });

                      final password = passwordController.text;
                      final ok = await _validatePermissionPassword(
                        permission,
                        password,
                      );

                      if (ok) {
                        Navigator.of(context).pop(true);
                      } else {
                        setState(() {
                          verifying = false;
                          errorMessage = 'Incorrect password';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: verifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Verify',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  /// Check if cached password is still valid for this permission
  bool _isCachedPermissionValid(AdminPermission permission) {
    return _grantedPermissions.contains(permission) &&
        DateTime.now().isBefore(_passwordExpiry);
  }

  /// Validate password using remote hash (if present) with local fallback.
  Future<bool> _validatePermissionPassword(
    AdminPermission permission,
    String password,
  ) async {
    if (password.isEmpty) return false;

    // Try remote secret first
    try {
      final secret = await _getSecret(permission);
      if (secret != null && secret.hash != null && secret.salt != null) {
        final computed = _hashPassword(password, secret.salt!);
        if (_constantTimeEquals(computed, secret.hash!)) {
          _grantPermissionsForPassword(password, permission);
          return true;
        }
      }
    } catch (e) {
      debugPrint('[AdminPermission] remote validation failed: $e');
    }

    // Fallback to local mapping
    final granted = AdminPermissions.getPermissionForPassword(
          password,
          permission,
        ) !=
        null;
    if (granted) {
      _grantPermissionsForPassword(password, permission);
    }
    return granted;
  }

  /// Fetch hashed secret from Supabase; cached for a short TTL.
  Future<_PermissionSecret?> _getSecret(AdminPermission permission) async {
    final cached = _secretCache[permission];
    if (cached != null &&
        DateTime.now().difference(cached.loadedAt) < _secretCacheTtl) {
      return cached;
    }

    try {
      final response = await _supabase
          .from('admin_permissions')
          .select('secret_hash, salt, algorithm')
          .eq('operation', permission.key)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final secret = _PermissionSecret(
          hash: response['secret_hash'] as String?,
          salt: response['salt'] as String?,
          algorithm: response['algorithm'] as String?,
          loadedAt: DateTime.now(),
        );
        _secretCache[permission] = secret;
        return secret;
      }
    } catch (e) {
      debugPrint('[AdminPermission] fetch failed for ${permission.key}: $e');
    }

    _secretCache[permission] = _PermissionSecret(loadedAt: DateTime.now());
    return _secretCache[permission];
  }

  String _hashPassword(String password, String salt) {
    final input = utf8.encode('$salt::$password');
    return sha256.convert(input).toString();
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  void _grantPermissionsForPassword(
    String password,
    AdminPermission fallbackPermission,
  ) {
    final permissions =
        AdminPermissions.getPermissionsForPassword(password).isNotEmpty
            ? AdminPermissions.getPermissionsForPassword(password)
            : {fallbackPermission};
    _grantedPermissions = permissions;
    _passwordExpiry = DateTime.now().add(_cacheExpiry);
  }

  /// Clear cached password (useful after logout or on demand)
  void clearCache() {
    _grantedPermissions.clear();
    _passwordExpiry = DateTime.now();
  }

  /// Get remaining cache time in seconds (for UI display)
  int? get cacheRemainingSeconds {
    if (!_isCachedPermissionValid(AdminPermission.addLanguage)) {
      return null;
    }
    return _passwordExpiry.difference(DateTime.now()).inSeconds;
  }

  /// Check if any permission is currently cached
  bool get hasActiveCacheSession =>
      _grantedPermissions.isNotEmpty &&
      DateTime.now().isBefore(_passwordExpiry);
}

class _PermissionSecret {
  final String? hash;
  final String? salt;
  final String? algorithm;
  final DateTime loadedAt;

  _PermissionSecret({
    this.hash,
    this.salt,
    this.algorithm,
    required this.loadedAt,
  });
}
