import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/database/my_database.dart';
import 'package:zad_aldaia/core/networking/api_service.dart';
import 'package:zad_aldaia/core/networking/dio_factory.dart';
import 'package:zad_aldaia/features/articles/data/repos/articles_repo.dart';
import 'package:zad_aldaia/features/articles/logic/articles_cubit.dart';
import 'package:zad_aldaia/features/auth/auth_cubit.dart';
import 'package:zad_aldaia/features/categories/data/repos/categories_repo.dart';
import 'package:zad_aldaia/features/categories/logic/categories_cubit.dart';
import 'package:zad_aldaia/features/items/data/repos/items_repo.dart';
import 'package:zad_aldaia/features/items/logic/items_cubit.dart';
import 'package:zad_aldaia/features/upload/upload_cubit.dart';
import 'package:zad_aldaia/services/admin_auth_service.dart';
import 'package:zad_aldaia/services/admin_mode_service.dart';
import 'package:zad_aldaia/services/admin_permission_service.dart';
import 'package:zad_aldaia/services/auth_service.dart';
import 'package:zad_aldaia/services/block_service.dart';
import 'package:zad_aldaia/services/content_clipboard_service.dart';
import 'package:zad_aldaia/services/content_ordering_service.dart';
import 'package:zad_aldaia/services/content_paste_service.dart';
import 'package:zad_aldaia/services/content_service.dart';
import 'package:zad_aldaia/services/global_navigation_service.dart';
import 'package:zad_aldaia/services/image_management_service.dart';
import 'package:zad_aldaia/services/post_service.dart';
import 'package:zad_aldaia/services/reference_service.dart';
import 'package:zad_aldaia/services/soft_delete_service.dart';
import 'package:zad_aldaia/services/storage_service.dart';

final getIt = GetIt.instance;

Future<void> setupGetIt() async {
  // Core dependencies
  getIt.registerLazySingleton<MyDatabase>(() => MyDatabase());
  final SharedPreferences sp = await SharedPreferences.getInstance();
  final Dio dio = DioFactory.getDio();
  final SupabaseClient supabaseClient = Supabase.instance.client;
  getIt.registerSingleton<SharedPreferences>(sp);
  getIt.registerSingleton<Dio>(dio);
  getIt.registerSingleton<SupabaseClient>(supabaseClient);

  // Register all services as singletons
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<PostService>(() => PostService());
  getIt.registerLazySingleton<BlockService>(() => BlockService());
  getIt.registerLazySingleton<ContentService>(() => ContentService());
  getIt.registerLazySingleton<StorageService>(() => StorageService());

  // Admin services
  getIt.registerSingleton<GlobalNavigationService>(GlobalNavigationService());
  getIt.registerSingleton<AdminAuthService>(AdminAuthService());
  getIt.registerSingleton<AdminModeService>(AdminModeService());
  getIt.registerSingleton<AdminPermissionService>(AdminPermissionService());
  getIt.registerSingleton<ImageManagementService>(ImageManagementService());
  getIt.registerSingleton<ContentClipboardService>(ContentClipboardService());
  getIt.registerSingleton<ContentOrderingService>(ContentOrderingService());
  getIt.registerSingleton<ReferenceService>(ReferenceService());
  getIt.registerSingleton<ContentPasteService>(
    ContentPasteService(getIt<ContentClipboardService>()),
  );
  getIt.registerSingleton<SoftDeleteService>(
    SoftDeleteService(imageService: getIt<ImageManagementService>()),
  );

  // Initialize admin services
  await getIt<AdminAuthService>().initialize();
  await getIt<AdminModeService>().initialize();

  // If admin session is gone, do not allow stale admin mode
  if (!getIt<AdminAuthService>().isAdminLoggedIn &&
      getIt<AdminModeService>().isAdminMode) {
    await getIt<AdminModeService>().enableUserMode();
  }

  // Cubits and repos
  getIt.registerFactory<AuthCubit>(
      () => AuthCubit(supabase: getIt(), sp: getIt()));
  getIt.registerFactory<CategoriesRepo>(() => CategoriesRepo());
  getIt.registerFactory<CategoriesCubit>(() => CategoriesCubit(getIt()));
  getIt.registerFactory<ApiService>(() => ApiService(dio));
  getIt.registerFactory<UploadCubit>(() => UploadCubit(getIt()));
  getIt.registerFactory<ArticlesRepo>(() => ArticlesRepo());
  getIt.registerFactory<ArticlesCubit>(() => ArticlesCubit(getIt()));
  getIt.registerFactory<ItemsRepo>(() => ItemsRepo());
  getIt.registerFactory<ItemsCubit>(() => ItemsCubit(getIt()));
}
