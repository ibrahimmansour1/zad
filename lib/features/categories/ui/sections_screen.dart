import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/core/theming/my_text_style.dart';
import 'package:zad_aldaia/features/auth/auth_cubit.dart';
import 'package:zad_aldaia/features/categories/data/models/category.dart';
import 'package:zad_aldaia/features/categories/logic/categories_cubit.dart';
import 'package:zad_aldaia/features/categories/ui/AddNewCategoryCard.dart';
import 'package:zad_aldaia/services/admin_mode_service.dart';

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
      backgroundColor: MyColors.backgroundColor,
      body: BlocProvider(
        create: (context) => cubit,
        child: BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) {
            if (state is ErrorState) {
              return Center(child: Text(state.error));
            }
            if (state is LoadingState) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(MyColors.primaryColor),
                ),
              );
            }
            if (state is ListLoadedState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.isOffline)
                    Container(
                      width: double.infinity,
                      color: MyColors.warningColor,
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
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore Islamic Knowledge',
                          style: MyTextStyle.displaySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select a language to continue',
                          style: MyTextStyle.bodyMedium.copyWith(
                            color: MyColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.0,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.items.length +
                          (Supabase.instance.client.auth.currentUser != null &&
                                  getIt<AdminModeService>().isAdminMode
                              ? 1
                              : 0),
                      itemBuilder: (context, index) {
                        if (Supabase.instance.client.auth.currentUser != null &&
                            getIt<AdminModeService>().isAdminMode &&
                            index == 0) {
                          return const AddNewCategoryCard();
                        }
                        final adjustedIndex =
                            Supabase.instance.client.auth.currentUser != null &&
                                    getIt<AdminModeService>().isAdminMode
                                ? index - 1
                                : index;
                        final item = state.items[adjustedIndex];
                        return _buildLanguageCard(
                          context,
                          item,
                          adjustedIndex,
                          state.items,
                          cubit,
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

  Widget _buildLanguageCard(
    BuildContext context,
    Category item,
    int adjustedIndex,
    List<Category> items,
    CategoriesCubit cubit,
  ) {
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: MyColors.primaryColor.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image section
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
                      MyColors.primaryColor.withOpacity(0.1),
                      MyColors.primaryLight.withOpacity(0.08),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    if (item.image != null && item.image!.isNotEmpty)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: item.image!.startsWith('http')
                              ? Image.network(
                                  item.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFallbackIcon(),
                                )
                              : Image.asset(
                                  item.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFallbackIcon(),
                                ),
                        ),
                      )
                    else
                      _buildFallbackIcon(),
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
                              Colors.black.withOpacity(0.15),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Center(
                  child: Text(
                    item.title ?? '-',
                    style: MyTextStyle.headingSmall.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
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
            MyColors.primaryColor.withOpacity(0.15),
            MyColors.primaryLight.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.language,
          size: 48,
          color: MyColors.primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }
}
