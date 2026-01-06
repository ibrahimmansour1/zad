import 'package:flutter/material.dart';

/// Admin password constants for different operations
class AdminPasswords {
  static const String language = 'ZAD2442_language';
  static const String path = 'ZAD2442_path';
  static const String category = 'ZAD2442_category';
  static const String subcategory = 'ZAD_subcategory';
  static const String article = 'ZAD_article';
  static const String item = 'ZAD_item';
}

class AdminPasswordDialog {
  static Future<bool> verify({
    required BuildContext context,
    required String requiredPassword,
    required String operationType,
    String? itemName,
  }) async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Admin Verification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to $operationType${itemName != null ? ' "$itemName"' : ''}.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter the admin password to continue:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => obscurePassword = !obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onSubmitted: (_) {
                  if (passwordController.text == requiredPassword) {
                    Navigator.of(context).pop(true);
                  } else {
                    setState(() => errorMessage = 'Incorrect password');
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text == requiredPassword) {
                  Navigator.of(context).pop(true);
                } else {
                  setState(() => errorMessage = 'Incorrect password');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Verify',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  /// Verify for delete language operation
  static Future<bool> verifyDeleteLanguage(
      BuildContext context, String? languageName) {
    return verify(
      context: context,
      requiredPassword: AdminPasswords.language,
      operationType: 'delete this language',
      itemName: languageName,
    );
  }

  /// Verify for add language operation
  static Future<bool> verifyAddLanguage(BuildContext context) {
    return verify(
      context: context,
      requiredPassword: AdminPasswords.language,
      operationType: 'add a new language',
    );
  }

  /// Verify for delete path operation
  static Future<bool> verifyDeletePath(BuildContext context, String? pathName) {
    return verify(
      context: context,
      requiredPassword: AdminPasswords.path,
      operationType: 'delete this path',
      itemName: pathName,
    );
  }

  /// Verify for delete category operation
  static Future<bool> verifyDeleteCategory(
      BuildContext context, String? categoryName) {
    return verify(
      context: context,
      requiredPassword: AdminPasswords.category,
      operationType: 'delete this category',
      itemName: categoryName,
    );
  }

  /// Verify for delete subcategory operation
  static Future<bool> verifyDeleteSubcategory(
      BuildContext context, String? subcategoryName) {
    return verify(
      context: context,
      requiredPassword: AdminPasswords.subcategory,
      operationType: 'delete this subcategory',
      itemName: subcategoryName,
    );
  }

  /// Verify for delete article operation
  static Future<bool> verifyDeleteArticle(
      BuildContext context, String? articleName) {
    return verify(
      context: context,
      requiredPassword: AdminPasswords.article,
      operationType: 'delete this article',
      itemName: articleName,
    );
  }

  /// Verify for delete item operation
  static Future<bool> verifyDeleteItem(BuildContext context, String? itemName) {
    return verify(
      context: context,
      requiredPassword: AdminPasswords.item,
      operationType: 'delete this item',
      itemName: itemName,
    );
  }
}
