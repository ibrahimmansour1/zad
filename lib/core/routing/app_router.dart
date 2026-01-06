import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/features/admin/supabase_test_screen.dart';
import 'package:zad_aldaia/features/articles/ui/article_form_screen.dart';
import 'package:zad_aldaia/features/articles/ui/articles_screen.dart';
import 'package:zad_aldaia/features/categories/logic/categories_cubit.dart';
import 'package:zad_aldaia/features/categories/ui/categories_screen.dart';
import 'package:zad_aldaia/features/categories/ui/category_form_screen.dart';
import 'package:zad_aldaia/features/categories/ui/home_screen.dart';
import 'package:zad_aldaia/features/categories/ui/sections_screen.dart';
import 'package:zad_aldaia/features/items/ui/item_form_screen.dart';
import 'package:zad_aldaia/features/items/ui/items_screen.dart';
import 'package:zad_aldaia/features/items/ui/search_screen.dart';
import 'package:zad_aldaia/features/languages/admin_languages_screen.dart';
import 'package:zad_aldaia/features/languages/languages_screen.dart';
import 'package:zad_aldaia/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:zad_aldaia/features/onboarding/presentation/screens/user_type_screen.dart';

class AppRouter {
  Route? generateRoutes(RouteSettings settings) {
    final arguments = settings.arguments as Map? ?? {};

    switch (settings.name) {
      case MyRoutes.onboarding:
        return MaterialPageRoute(builder: (context) => OnboardingScreen());
      case MyRoutes.usertype:
        return MaterialPageRoute(builder: (context) => UserTypeScreen());
      case MyRoutes.languages:
        return MaterialPageRoute(builder: (context) => const AdminLanguagesScreen());
      case MyRoutes.homeScreen:
        return MaterialPageRoute(builder: (context) => HomeScreen());
      case MyRoutes.sectionScreen:
        return MaterialPageRoute(builder: (context) => SectionsScreen());
      case MyRoutes.categories:
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
              create: (context) => getIt<CategoriesCubit>(),
              child: CategoriesScreen(
                  title: arguments["title"],
                  parentId: arguments["category_id"])),
        );
      case MyRoutes.addCategoryScreen:
        return MaterialPageRoute(
            builder: (context) =>
                CategoryFormScreen(categoryId: arguments["id"]));
      case MyRoutes.addArticleScreen:
        return MaterialPageRoute(
            builder: (context) =>
                ArticleFormScreen(
                  articleId: arguments["id"],
                  categoryId: arguments["category_id"],
                  categoryTitle: arguments["category_title"],
                ));
      case MyRoutes.articles:
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
              create: (context) => getIt<CategoriesCubit>(),
              child: ArticlesScreen(
                  title: arguments["title"],
                  categoryId: arguments["category_id"])),
        );
      case MyRoutes.items:
        return MaterialPageRoute(
            builder: (context) => ItemsScreen(
                articleId: arguments["id"], title: arguments["title"]));
      case MyRoutes.searchScreen:
        return MaterialPageRoute(builder: (context) => SearchScreen());

      case MyRoutes.addItemScreen:
        return MaterialPageRoute(
            builder: (context) => ItemFormScreen(
                itemId: arguments["id"], articleId: arguments["article_id"]));
      case MyRoutes.supabaseTest:
        return MaterialPageRoute(
            builder: (context) => const SupabaseTestScreen());
      default:
        return null;
    }
  }
}
