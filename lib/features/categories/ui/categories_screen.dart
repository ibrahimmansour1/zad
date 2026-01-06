import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/helpers/admin_password.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/core/widgets/admin_breadcrumb.dart';
import 'package:zad_aldaia/features/categories/data/models/category.dart';
import 'package:zad_aldaia/features/categories/logic/categories_cubit.dart';

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
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: MyColors.primaryColor,
        titleTextStyle: MyTextStyle.font16WhiteBold,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title ?? 'Categories'),
        actions: [
          if (Supabase.instance.client.auth.currentUser != null)
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
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return _buildCategoryCard(item, index, state.items);
                  },
                ),
              );
            } else if (state is LoadingState) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(MyColors.primaryColor),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
          splashColor: Colors.green.shade100,
          highlightColor: Colors.green.shade50,
          child: Stack(
            children: [
              // Background with subtle gradient
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.shade50,
                      Colors.white,
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF005A32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.childrenCount > 0 ? Icons.folder : Icons.article,
                        color: const Color(0xFF005A32),
                        size: 28,
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      item.title ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Exo',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Item count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF005A32),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item.childrenCount > 0 ? item.childrenCount : item.articlesCount} items',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (Supabase.instance.client.auth.currentUser != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.black54),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: const [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: const [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'move_up',
                        enabled: index > 0,
                        child: Row(
                          children: const [
                            Icon(Icons.arrow_upward, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Move Up'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'move_down',
                        enabled: index < items.length - 1,
                        child: Row(
                          children: const [
                            Icon(Icons.arrow_downward, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Move Down'),
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
                      } else if (value == 'delete') {
                        await _deleteCategory(item);
                      } else if (value == 'move_up' && index > 0) {
                        await cubit.swapCategoriesOrder(
                          id1: item.id,
                          id2: items[index - 1].id,
                          index1: index,
                          index2: index - 1,
                        );
                        loadData();
                      } else if (value == 'move_down' &&
                          index < items.length - 1) {
                        await cubit.swapCategoriesOrder(
                          id1: item.id,
                          id2: items[index + 1].id,
                          index1: index,
                          index2: index + 1,
                        );
                        loadData();
                      }
                    },
                  ),
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
        // Delete from the appropriate table
        final tableName = section.isNotEmpty ? section : 'categories';
        await Supabase.instance.client
            .from(tableName)
            .delete()
            .eq('id', item.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${item.title}" deleted successfully!')),
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
}
