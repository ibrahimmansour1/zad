import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/features/auth/auth_cubit.dart';
import 'package:zad_aldaia/features/categories/logic/categories_cubit.dart';
import 'package:zad_aldaia/features/categories/ui/AddNewCategoryCard.dart';
import 'package:zad_aldaia/features/categories/ui/category_grid_widget.dart';

class SectionsScreen extends StatefulWidget {
  const SectionsScreen({super.key});

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  late final CategoriesCubit cubit = getIt<CategoriesCubit>();
  late final AuthCubit authCubit = getIt<AuthCubit>();

  @override
  void initState() {
    loadData();
    super.initState();
  }

  loadData() {
    cubit.getChildCategories(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAE6),
      body: BlocProvider(
        create: (context) => cubit,
        child: BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) {
            if (state is ErrorState) {
              return Center(child: Text(state.error));
            }
            if (state is LoadingState) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ListLoadedState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.isOffline)
                    Container(
                      width: double.infinity,
                      color: Colors.orange.shade800,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Offline Mode - Using cached data',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 40),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25.0),
                    child: Text(
                      'Explore Islamic Knowledge',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Exo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.0,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: state.items.length +
                          (Supabase.instance.client.auth.currentUser != null
                              ? 1
                              : 0),
                      itemBuilder: (context, index) {
                        if (Supabase.instance.client.auth.currentUser != null &&
                            index == 0) {
                          return const AddNewCategoryCard();
                        }
                        final adjustedIndex =
                            Supabase.instance.client.auth.currentUser != null
                                ? index - 1
                                : index;
                        final item = state.items[adjustedIndex];
                        return CategoryGridWidget(
                          category: item,
                          itemCount: item.childrenCount,
                          onDeleted: () => loadData(),
                          onTap: () {
                            if (item.childrenCount > 0) {
                              Navigator.of(context)
                                  .pushNamed(MyRoutes.categories, arguments: {
                                "category_id": item.id,
                                "title": item.title
                              });
                            } else {
                              Navigator.of(context).pushNamed(MyRoutes.articles,
                                  arguments: {
                                    "category_id": item.id,
                                    "title": item.title
                                  });
                            }
                          },
                          onMoveUp: (category) async {
                            if (adjustedIndex > 0) {
                              await cubit.swapCategoriesOrder(
                                  id1: item.id,
                                  id2: state.items[adjustedIndex - 1].id,
                                  index1: adjustedIndex,
                                  index2: adjustedIndex - 1);
                              loadData();
                            }
                          },
                          onMoveDown: (category) async {
                            if (adjustedIndex < state.items.length - 1) {
                              await cubit.swapCategoriesOrder(
                                  id1: item.id,
                                  id2: state.items[adjustedIndex + 1].id,
                                  index1: adjustedIndex,
                                  index2: adjustedIndex + 1);
                              loadData();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }
            return Center(child: Text('STATE: ${state.runtimeType}'));
          },
        ),
      ),
    );
  }
}
