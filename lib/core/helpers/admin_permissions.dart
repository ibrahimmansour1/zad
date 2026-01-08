/// Admin permissions granular system
enum AdminPermission {
  // Language operations
  addLanguage,
  editLanguage,
  deleteLanguage,

  // Path operations
  addPath,
  editPath,
  deletePath,

  // Category operations
  addCategory,
  editCategory,
  deleteCategory,

  // Subcategory operations
  deleteSubcategory,

  // Article operations
  deleteArticle,

  // Item operations (text/image/video)
  deleteItem,
}

extension AdminPermissionKey on AdminPermission {
  /// Canonical key for Supabase `admin_permissions.operation` values
  String get key {
    switch (this) {
      case AdminPermission.addLanguage:
      case AdminPermission.editLanguage:
      case AdminPermission.deleteLanguage:
        return 'language';
      case AdminPermission.addPath:
      case AdminPermission.editPath:
      case AdminPermission.deletePath:
        return 'path';
      case AdminPermission.addCategory:
      case AdminPermission.editCategory:
      case AdminPermission.deleteCategory:
        return 'category';
      case AdminPermission.deleteSubcategory:
        return 'subcategory';
      case AdminPermission.deleteArticle:
        return 'article';
      case AdminPermission.deleteItem:
        return 'item';
    }
  }
}

/// Maps each password to its granted permissions
class PermissionPassword {
  final String password;
  final Set<AdminPermission> permissions;

  const PermissionPassword({
    required this.password,
    required this.permissions,
  });
}

/// Centralized password-to-permission mapping
class AdminPermissions {
  static const Map<String, PermissionPassword> passwordMap = {
    'ZAD2442_language': PermissionPassword(
      password: 'ZAD2442_language',
      permissions: {
        AdminPermission.addLanguage,
        AdminPermission.editLanguage,
        AdminPermission.deleteLanguage,
      },
    ),
    'ZAD2442_path': PermissionPassword(
      password: 'ZAD2442_path',
      permissions: {
        AdminPermission.addPath,
        AdminPermission.editPath,
        AdminPermission.deletePath,
      },
    ),
    'ZAD2442_category': PermissionPassword(
      password: 'ZAD2442_category',
      permissions: {
        AdminPermission.addCategory,
        AdminPermission.editCategory,
        AdminPermission.deleteCategory,
      },
    ),
    'ZAD_subcategory': PermissionPassword(
      password: 'ZAD_subcategory',
      permissions: {
        AdminPermission.deleteSubcategory,
      },
    ),
    'zad': PermissionPassword(
      password: 'zad',
      permissions: {
        AdminPermission.deleteArticle,
        AdminPermission.deleteItem,
      },
    ),
  };

  /// Check if password grants the requested permission
  static AdminPermission? getPermissionForPassword(
    String password,
    AdminPermission requested,
  ) {
    for (var entry in passwordMap.entries) {
      if (entry.value.password == password &&
          entry.value.permissions.contains(requested)) {
        return requested;
      }
    }
    return null;
  }

  /// Get all permissions for a password
  static Set<AdminPermission> getPermissionsForPassword(
    String password,
  ) {
    return passwordMap[password]?.permissions ?? {};
  }

  /// Get password for a specific permission (for UI help)
  static String? getPasswordForPermission(AdminPermission permission) {
    for (var entry in passwordMap.entries) {
      if (entry.value.permissions.contains(permission)) {
        return entry.key;
      }
    }
    return null;
  }
}
