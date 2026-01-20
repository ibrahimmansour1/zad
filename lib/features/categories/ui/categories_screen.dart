import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/helpers/admin_password.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/core/widgets/admin_breadcrumb.dart';
import 'package:zad_aldaia/core/widgets/admin_mode_toggle.dart';
import 'package:zad_aldaia/core/widgets/clipboard_floating_button.dart';
import 'package:zad_aldaia/core/widgets/global_home_button.dart';
import 'package:zad_aldaia/features/categories/data/models/category.dart';
import 'package:zad_aldaia/features/categories/logic/categories_cubit.dart';
import 'package:zad_aldaia/services/admin_mode_service.dart';
import 'package:zad_aldaia/services/content_clipboard_service.dart';
import 'package:zad_aldaia/services/soft_delete_service.dart';

import '../../../core/theming/my_text_style.dart';

class CategoriesScreen extends StatefulWidget {
  final String? parentId;
  final String? title;
  final NavigationPath? navigationPath;

  const CategoriesScreen(
      {super.key, required this.parentId, this.title, this.navigationPath});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late CategoriesCubit cubit;

  @override
  void initState() {
    cubit = context.read<CategoriesCubit>();
    loadData();
    super.initState();
  }

  loadData() {
    cubit.loadCategories({'parent_id': widget.parentId}
      ..removeWhere((key, value) => value == null));
  }

  @override
  Widget build(BuildContext context) {
    String? targetTable;
    if (widget.parentId != null) {
      // Determine child table based on parent type
      // This is simplified - you may need to get parent type from state
      targetTable = 'categories'; // Default to categories
    }

    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      floatingActionButton: widget.parentId != null
          ? ClipboardFloatingButton(
              targetParentId: widget.parentId,
              targetTable: targetTable,
              targetTitle: widget.title,
              onPasted: loadData,
            )
          : null,
      appBar: AppBar(
        backgroundColor: MyColors.primaryColor,
        titleTextStyle: MyTextStyle.font16WhiteBold,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title ?? 'Categories'),
        actions: [
          const AdminModeIndicator(),
          const AdminModeQuickToggle(),
          GlobalHomeButton(),
          if (Supabase.instance.client.auth.currentUser != null &&
              getIt<AdminModeService>().isAdminMode)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pushNamed(
                  MyRoutes.addCategoryScreen,
                  arguments: {"parent_id": widget.parentId},
                );
              },
            ),
        ],
      ),
      body: SizedBox.expand(
        child: BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) {
            if (state is ListLoadedState) {
              if (state.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/png/empty_box.png',
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No categories found',
                        style: MyTextStyle.font18BlackBold,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Add new categories to get started',
                        style: MyTextStyle.font16Grey,
                      ),
                    ],
                  ),
                );
              }
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView.builder(
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCategoryCard(item, index, state.items),
                    );
                  },
                ),
              );
            } else if (state is LoadingState) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(MyColors.primaryColor),
                ),
              );
            } else if (state is ErrorState) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading categories',
                      style: MyTextStyle.font18BlackBold,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: MyTextStyle.font16Grey,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Category item, int index, List<Category> items) {
    return GestureDetector(
      onTap: () {
        if (item.childrenCount > 0) {
          Navigator.of(context).pushNamed(
            MyRoutes.categories,
            arguments: {"category_id": item.id, "title": item.title},
          );
        } else {
          Navigator.of(context).pushNamed(
            MyRoutes.articles,
            arguments: {"category_id": item.id, "title": item.title},
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: MyColors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: MyColors.primaryColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      MyColors.primaryColor.withOpacity(0.2),
                      MyColors.primaryLight.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    item.childrenCount > 0
                        ? Icons.folder_outlined
                        : Icons.article_outlined,
                    color: MyColors.primaryColor,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title ?? 'Untitled',
                      style: MyTextStyle.headingSmall.copyWith(
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: MyColors.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.childrenCount > 0 ? item.childrenCount : item.articlesCount} items',
                        style: MyTextStyle.labelSmall.copyWith(
                          color: MyColors.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (Supabase.instance.client.auth.currentUser != null &&
                  getIt<AdminModeService>().isAdminMode)
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
                              size: 18, color: MyColors.primaryColor),
                          const SizedBox(width: 8),
                          Text('Edit', style: MyTextStyle.bodySmall),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy,
                              size: 18, color: MyColors.primaryColor),
                          const SizedBox(width: 8),
                          Text('Copy', style: MyTextStyle.bodySmall),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'move_up',
                      enabled: index > 0,
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward,
                              size: 18, color: MyColors.primaryColor),
                          const SizedBox(width: 8),
                          Text('Move Up', style: MyTextStyle.bodySmall),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'move_down',
                      enabled: index < items.length - 1,
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward,
                              size: 18, color: MyColors.primaryColor),
                          const SizedBox(width: 8),
                          Text('Move Down', style: MyTextStyle.bodySmall),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete,
                              size: 18, color: MyColors.errorColor),
                          const SizedBox(width: 8),
                          Text('Delete',
                              style: MyTextStyle.bodySmall
                                  .copyWith(color: MyColors.errorColor)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.of(context).pushNamed(
                        MyRoutes.addCategoryScreen,
                        arguments: {"id": item.id},
                      );
                    } else if (value == 'copy') {
                      _handleCopy(item);
                    } else if (value == 'delete') {
                      await _deleteCategory(item);
                    } else if (value == 'move_up' && index > 0) {
                      // Use atomic move operation
                      await cubit.moveCategoryUp(item.id, widget.parentId);
                    } else if (value == 'move_down' &&
                        index < items.length - 1) {
                      // Use atomic move operation
                      await cubit.moveCategoryDown(item.id, widget.parentId);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCategory(Category item) async {
    // Determine the type based on section field
    final section = item.section ?? '';
    bool verified = false;

    if (section == 'paths') {
      verified =
          await AdminPasswordDialog.verifyDeletePath(context, item.title);
    } else if (section == 'sections') {
      verified =
          await AdminPasswordDialog.verifyDeleteCategory(context, item.title);
    } else if (section == 'branches' || section == 'topics') {
      verified = await AdminPasswordDialog.verifyDeleteSubcategory(
          context, item.title);
    } else {
      // Default to category password
      verified =
          await AdminPasswordDialog.verifyDeleteCategory(context, item.title);
    }

    if (!verified) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete "${item.title}"?\n\nThis action cannot be undone.'),
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
        // Use soft delete
        final tableName = section.isNotEmpty ? section : 'categories';
        final softDeleteService = getIt<SoftDeleteService>();
        await softDeleteService.softDelete(
          tableName: tableName,
          id: item.id,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${item.title}" moved to Recycle Bin')),
        );

        loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleCopy(Category item) {
    final section = item.section ?? 'categories';
    final clipboard = getIt<ContentClipboardService>();
    clipboard.copy(
      id: item.id,
      type: section,
      data: {
        'title': item.title,
        'section': section,
        'parent_id': widget.parentId,
      },
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${item.title}" copied to clipboard'),
        action: SnackBarAction(
          label: 'CLEAR',
          onPressed: () => clipboard.clear(),
        ),
      ),
    );
  }
}
