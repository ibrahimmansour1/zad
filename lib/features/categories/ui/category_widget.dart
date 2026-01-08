import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/helpers/admin_password.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/features/categories/data/models/category.dart';
import 'package:zad_aldaia/services/soft_delete_service.dart';

class CategoryWidget extends StatelessWidget {
  final Category category;
  final int itemCount;
  final VoidCallback? onTap;
  final Function(Category)? onMoveUp;
  final Function(Category)? onMoveDown;
  final VoidCallback? onDeleted;

  const CategoryWidget({
    super.key,
    required this.category,
    required this.itemCount,
    this.onTap,
    this.onMoveUp,
    this.onMoveDown,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            MyColors.darkGold,
            Color(0xFF8B6508), // Slightly darker gold
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 1. Icon/Image
                _buildLeading(),
                const SizedBox(width: 16),

                // 2. Title and Items Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title ?? '---',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Exo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$itemCount items',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Admin Actions
                if (Supabase.instance.client.auth.currentUser != null)
                  _buildAdminActions(context),

                // 4. Chevron for public/all
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: (category.image != null && category.image!.isNotEmpty)
            ? (category.image!.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: category.image!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.category, color: Colors.white),
                  )
                : Image.asset(category.image!, fit: BoxFit.cover))
            : const Icon(Icons.category, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
          onPressed: () {
            Navigator.of(context).pushNamed(MyRoutes.addCategoryScreen,
                arguments: {"id": category.id});
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.white70, size: 20),
          onPressed: () => _handleDelete(context),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => onMoveUp?.call(category),
              child: const Icon(Icons.arrow_drop_up,
                  color: Colors.white, size: 24),
            ),
            InkWell(
              onTap: () => onMoveDown?.call(category),
              child: const Icon(Icons.arrow_drop_down,
                  color: Colors.white, size: 24),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final section = category.section ?? '';
    bool verified = false;

    if (section == 'paths') {
      verified =
          await AdminPasswordDialog.verifyDeletePath(context, category.title);
    } else if (section == 'sections') {
      verified = await AdminPasswordDialog.verifyDeleteCategory(
          context, category.title);
    } else if (section == 'branches' || section == 'topics') {
      verified = await AdminPasswordDialog.verifyDeleteSubcategory(
          context, category.title);
    } else {
      verified = await AdminPasswordDialog.verifyDeleteCategory(
          context, category.title);
    }

    if (!verified) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${category.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final tableName = section.isNotEmpty ? section : 'categories';
        // Prefer soft delete; fallback to hard delete if schema lacks flags
        try {
          await SoftDeleteService().softDelete(
            id: category.id,
            tableName: tableName,
          );
        } catch (_) {
          await Supabase.instance.client
              .from(tableName)
              .delete()
              .eq('id', category.id);
        }
        onDeleted?.call();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }
}
