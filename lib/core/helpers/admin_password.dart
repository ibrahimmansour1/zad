import 'package:flutter/material.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/helpers/admin_permissions.dart';
import 'package:zad_aldaia/services/admin_permission_service.dart';

/// Admin password constants for different operations
class AdminPasswords {
  static const String language = 'ZAD2442_language';
  static const String path = 'ZAD2442_path';
  static const String category = 'ZAD2442_category';
  static const String subcategory = 'ZAD_subcategory';
  static const String article = 'zad';
  static const String item = 'zad';
}

class AdminPasswordDialog {
  static Future<bool> verify({
    required BuildContext context,
    required AdminPermission permission,
    required String operationType,
    String? itemName,
  }) async {
    return getIt<AdminPermissionService>().verifyPermission(
      context,
      permission,
      operationType: operationType,
      itemName: itemName,
    );
  }

  /// Verify for delete language operation
  static Future<bool> verifyDeleteLanguage(
      BuildContext context, String? languageName) {
    return verify(
      context: context,
      permission: AdminPermission.deleteLanguage,
      operationType: 'delete this language',
      itemName: languageName,
    );
  }

  /// Verify for edit language operation
  static Future<bool> verifyEditLanguage(
      BuildContext context, String? languageName) {
    return verify(
      context: context,
      permission: AdminPermission.editLanguage,
      operationType: 'edit this language',
      itemName: languageName,
    );
  }

  /// Verify for add language operation
  static Future<bool> verifyAddLanguage(BuildContext context) {
    return verify(
      context: context,
      permission: AdminPermission.addLanguage,
      operationType: 'add a new language',
    );
  }

  static Future<bool> verifyAddPath(BuildContext context, String? languageName) {
    return verify(
      context: context,
      permission: AdminPermission.addPath,
      operationType: 'add a new path',
      itemName: languageName,
    );
  }

  static Future<bool> verifyEditPath(BuildContext context, String? pathName) {
    return verify(
      context: context,
      permission: AdminPermission.editPath,
      operationType: 'edit this path',
      itemName: pathName,
    );
  }

  /// Verify for delete path operation
  static Future<bool> verifyDeletePath(BuildContext context, String? pathName) {
    return verify(
      context: context,
      permission: AdminPermission.deletePath,
      operationType: 'delete this path',
      itemName: pathName,
    );
  }

  /// Verify for delete category operation
  static Future<bool> verifyDeleteCategory(
      BuildContext context, String? categoryName) {
    return verify(
      context: context,
      permission: AdminPermission.deleteCategory,
      operationType: 'delete this category',
      itemName: categoryName,
    );
  }

  static Future<bool> verifyAddCategory(
      BuildContext context, String? parentName) {
    return verify(
      context: context,
      permission: AdminPermission.addCategory,
      operationType: 'add a new category',
      itemName: parentName,
    );
  }

  static Future<bool> verifyEditCategory(
      BuildContext context, String? categoryName) {
    return verify(
      context: context,
      permission: AdminPermission.editCategory,
      operationType: 'edit this category',
      itemName: categoryName,
    );
  }

  /// Verify for delete subcategory operation
  static Future<bool> verifyDeleteSubcategory(
      BuildContext context, String? subcategoryName) {
    return verify(
      context: context,
      permission: AdminPermission.deleteSubcategory,
      operationType: 'delete this subcategory',
      itemName: subcategoryName,
    );
  }

  /// Verify for delete article operation
  static Future<bool> verifyDeleteArticle(
      BuildContext context, String? articleName) {
    return verify(
      context: context,
      permission: AdminPermission.deleteArticle,
      operationType: 'delete this article',
      itemName: articleName,
    );
  }

  /// Verify for delete item operation
  static Future<bool> verifyDeleteItem(BuildContext context, String? itemName) {
    return verify(
      context: context,
      permission: AdminPermission.deleteItem,
      operationType: 'delete this item',
      itemName: itemName,
    );
  }
}
