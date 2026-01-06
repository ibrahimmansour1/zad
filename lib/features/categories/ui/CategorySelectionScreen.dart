import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/features/categories/data/models/category.dart';
import 'package:zad_aldaia/features/categories/logic/categories_cubit.dart';

class CategorySelectionScreen extends StatefulWidget {
  final String? initialParentId;
  final bool forArticles;

  const CategorySelectionScreen({super.key, this.initialParentId, required this.forArticles});

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  late final CategoriesCubit cubit = getIt<CategoriesCubit>();
  List<Category> breadcrumb = [];

  @override
  void initState() {
    super.initState();
    cubit.getChildCategories(widget.initialParentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Category"),
        centerTitle: true,
        actions: [
          if (breadcrumb.isNotEmpty)
            IconButton(
              onPressed: () {
                if (widget.forArticles && breadcrumb.last.childrenCount > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This category has deep branches')));
                  return;
                }
                if (!widget.forArticles && breadcrumb.last.articlesCount > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This category has some articles')));
                  return;
                }
                Navigator.pop(context, breadcrumb.last);
              },
              icon: Icon(Icons.done),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBreadcrumbWidget(context),
          Expanded(
            child: BlocProvider(
              create: (context) => cubit,
              child: BlocBuilder<CategoriesCubit, CategoriesState>(
                builder: (context, state) {
                  if (state is ListLoadedState) {
                    if (state.items.isEmpty) {
                      return const Center(child: Text('empty.'));
                    }
                    return ListView.builder(
                      itemCount: state.items.length,
                      itemBuilder: (context, index) {
                        final category = state.items[index];

                        return ListTile(
                          title: Text(category.title ?? '---'),
                          trailing: const Icon(Icons.chevron_right),
                          // trailing:
                          //     category.hasChildren
                          //         ? const Icon(Icons.chevron_right)
                          //         : null, //Tooltip(message: "Select ${category.title}", child: const Icon(Icons.check_circle_outline, color: Colors.green)),
                          onTap: () => _onCategoryTap(category),
                        );
                      },
                    );
                  }
                  return const Center(child: Text('UnHanDleD state'));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onCategoryTap(Category category) async {
    if (breadcrumb.contains(category)) {
      var found = false;
      breadcrumb.removeWhere((element) {
        if (found) return true;
        if (element.id == category.id) {
          found = true;
        }
        return false;
      });
    } else {
      breadcrumb.add(category);
    }
    setState(() {});
    cubit.getChildCategories(category.id);
  }

  Widget _buildBreadcrumbWidget(BuildContext context) {
    List<Widget> breadcrumbItems = [];

    // "Root" or "All Categories" button
    breadcrumbItems.add(
      InkWell(
        // onTap: () => _onCategoryTap(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Text(
            "/",
            style: TextStyle(
              color: breadcrumb.isEmpty ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.secondary,
              fontWeight: breadcrumb.isEmpty ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );

    for (int i = 0; i < breadcrumb.length; i++) {
      final item = breadcrumb[i];
      breadcrumbItems.add(const Icon(Icons.chevron_right, size: 20, color: Colors.grey));
      breadcrumbItems.add(
        InkWell(
          onTap: () => _onCategoryTap(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Text(
              item.title ?? '---',
              style: TextStyle(
                color: (i == breadcrumb.length - 1) ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.secondary,
                fontWeight: (i == breadcrumb.length - 1) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Row(children: breadcrumbItems));
  }
}
