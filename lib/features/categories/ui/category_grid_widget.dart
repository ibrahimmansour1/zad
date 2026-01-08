import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/helpers/admin_password.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/core/theming/my_text_style.dart';
import 'package:zad_aldaia/features/categories/data/models/category.dart';

class CategoryGridWidget extends StatefulWidget {
  final Category category;
  final int itemCount;
  final VoidCallback? onTap;
  final Function(Category)? onMoveUp;
  final Function(Category)? onMoveDown;
  final VoidCallback? onDeleted;

  const CategoryGridWidget({
    super.key,
    required this.category,
    required this.itemCount,
    this.onTap,
    this.onMoveUp,
    this.onMoveDown,
    this.onDeleted,
  });

  @override
  State<CategoryGridWidget> createState() => _CategoryGridWidgetState();
}

class _CategoryGridWidgetState extends State<CategoryGridWidget>
    with SingleTickerProviderStateMixin {
  final double _scale = 1.0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 200),
        child: AnimatedOpacity(
          opacity: widget.category.isActive ? 1.0 : 0.6,
          duration: const Duration(milliseconds: 300),
          child: Container(
            decoration: BoxDecoration(
              color: MyColors.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: MyColors.primaryColor.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onTap,
                splashColor: MyColors.primaryColor.withOpacity(0.1),
                highlightColor: MyColors.primaryColor.withOpacity(0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Section
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              MyColors.primaryColor.withOpacity(0.8),
                              MyColors.primaryLight.withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            if (widget.category.image != null &&
                                widget.category.image!.isNotEmpty)
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  child: widget.category.image!
                                          .startsWith('http')
                                      ? Image.network(
                                          widget.category.image!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _buildFallbackIcon(),
                                        )
                                      : Image.asset(
                                          widget.category.image!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _buildFallbackIcon(),
                                        ),
                                ),
                              )
                            else
                              _buildFallbackIcon(),
                            // Gradient overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Content Section
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.category.title ?? '-',
                                style: MyTextStyle.headingSmall.copyWith(
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        MyColors.primaryColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.folder_outlined,
                                        size: 16,
                                        color: MyColors.primaryColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${widget.itemCount}',
                                        style: MyTextStyle.labelSmall.copyWith(
                                          color: MyColors.primaryColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (Supabase.instance.client.auth.currentUser !=
                                    null)
                                  PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      Icons.more_vert,
                                      size: 20,
                                      color: MyColors.textSecondary,
                                    ),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit,
                                                size: 18,
                                                color: MyColors.primaryColor),
                                            const SizedBox(width: 8),
                                            Text('Edit',
                                                style: MyTextStyle.bodySmall),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'up',
                                        child: Row(
                                          children: [
                                            Icon(Icons.arrow_upward,
                                                size: 18,
                                                color: MyColors.primaryColor),
                                            const SizedBox(width: 8),
                                            Text('Move Up',
                                                style: MyTextStyle.bodySmall),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'down',
                                        child: Row(
                                          children: [
                                            Icon(Icons.arrow_downward,
                                                size: 18,
                                                color: MyColors.primaryColor),
                                            const SizedBox(width: 8),
                                            Text('Move Down',
                                                style: MyTextStyle.bodySmall),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete,
                                                size: 18,
                                                color: MyColors.errorColor),
                                            const SizedBox(width: 8),
                                            Text('Delete',
                                                style: MyTextStyle.bodySmall
                                                    .copyWith(
                                                        color: MyColors
                                                            .errorColor)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'edit':
                                          Navigator.of(context).pushNamed(
                                            MyRoutes.addCategoryScreen,
                                            arguments: {
                                              "id": widget.category.id
                                            },
                                          );
                                          break;
                                        case 'up':
                                          widget.onMoveUp
                                              ?.call(widget.category);
                                          break;
                                        case 'down':
                                          widget.onMoveDown
                                              ?.call(widget.category);
                                          break;
                                        case 'delete':
                                          _handleDelete(context);
                                          break;
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MyColors.primaryColor.withOpacity(0.8),
            MyColors.primaryLight.withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.folder_outlined,
          size: 48,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final section = widget.category.section ?? '';
    bool verified = false;

    if (section == 'paths') {
      verified = await AdminPasswordDialog.verifyDeletePath(
          context, widget.category.title);
    } else if (section == 'sections') {
      verified = await AdminPasswordDialog.verifyDeleteCategory(
          context, widget.category.title);
    } else if (section == 'branches' || section == 'topics') {
      verified = await AdminPasswordDialog.verifyDeleteSubcategory(
          context, widget.category.title);
    } else {
      verified = await AdminPasswordDialog.verifyDeleteCategory(
          context, widget.category.title);
    }

    if (!verified) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete "${widget.category.title}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
        await Supabase.instance.client
            .from(tableName)
            .delete()
            .eq('id', widget.category.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('"${widget.category.title}" deleted successfully!')),
          );
          widget.onDeleted?.call();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
