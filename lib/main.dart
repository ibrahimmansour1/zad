import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show PlatformDispatcher, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/routing/app_router.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/core/supabase_client.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/firebase_options.dart';
import 'package:zad_aldaia/generated/l10n.dart';
import 'package:zad_aldaia/services/block_service.dart';

/// Key for storing whether user has completed onboarding
const String kHasOnboardedKey = 'has_onboarded';

void main() async {
  // Initialize binding first
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve splash screen
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // Initialize dependencies
    await ScreenUtil.ensureScreenSize();
    await initializeSupabase();
    await setupGetIt();
    await getIt.allReady();
    await initializeFirebase();

    // Initialize block cache if user is logged in
    if (Supa.isAuthenticated) {
      try {
        await getIt<BlockService>().initializeCache();
      } catch (e) {
        debugPrint('Failed to initialize block cache: $e');
      }
    }

    // Determine initial route
    final initialRoute = await _determineInitialRoute();

    // Remove splash screen and run app
    FlutterNativeSplash.remove();
    runApp(MyApp(initialRoute: initialRoute));
  } catch (e, stack) {
    debugPrint('App initialization failed: $e');
    debugPrint(stack.toString());
    FlutterNativeSplash.remove();
    runApp(const ErrorApp());
  }
}

/// Determine the initial route based on user state
Future<String> _determineInitialRoute() async {
  final sp = getIt<SharedPreferences>();
  final hasOnboarded = sp.getBool(kHasOnboardedKey) ?? false;

  if (!hasOnboarded) {
    // First time user - show onboarding
    return MyRoutes.onboarding;
  }

  if (Supa.isAuthenticated) {
    // Logged in user - go to home
    return MyRoutes.homeScreen;
  }

  // Returning user but not logged in - show user type selection
  return MyRoutes.usertype;
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFF0FAE6),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'حدث خطأ في تهيئة التطبيق',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'App initialization failed',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> initializeSupabase() async {
  await Supa.init(
    url: "https://bsejcxhvihyzrkgylhab.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJzZWpjeGh2aWh5enJrZ3lsaGFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0NzM3MDksImV4cCI6MjA4MTA0OTcwOX0.X2OBroIgDILKcy1PNZtYA_7-SjNKZcDlIiNJWnrgmWQ",
  );
}

Future<void> initializeFirebase() async {
  if (kIsWeb) {
    // Web initialization commented out
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  setupFirebaseCrashlytics();
}

void setupFirebaseCrashlytics() {
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ScreenUtilInit(
          designSize: Size(constraints.maxWidth, constraints.maxHeight),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              initialRoute: initialRoute,
              onGenerateRoute: AppRouter().generateRoutes,
              supportedLocales: S.delegate.supportedLocales,
              localeResolutionCallback: (locale, supportedLocales) {
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale?.languageCode) {
                    return supportedLocale;
                  }
                }
                return supportedLocales.first;
              },
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: ThemeData(
                useMaterial3: true,
                dividerColor: Colors.transparent,
                primaryColor: MyColors.primaryColor,
                fontFamily: "almarai_bold",
                scaffoldBackgroundColor: MyColors.backgroundColor,
                // Color Scheme
                colorScheme: const ColorScheme.light(
                  primary: MyColors.primaryColor,
                  onPrimary: Colors.white,
                  primaryContainer: MyColors.primaryLight,
                  onPrimaryContainer: MyColors.primaryDark,
                  secondary: MyColors.secondaryColor,
                  onSecondary: Colors.white,
                  surface: MyColors.surfaceColor,
                  onSurface: MyColors.textPrimary,
                  error: MyColors.errorColor,
                  onError: Colors.white,
                ),
                // AppBar Theme
                appBarTheme: const AppBarTheme(
                  backgroundColor: MyColors.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  centerTitle: true,
                  titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Card Theme
                cardTheme: CardTheme(
                  color: MyColors.surfaceColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Button Themes
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MyColors.primaryColor,
                    side: const BorderSide(color: MyColors.primaryColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: MyColors.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                // TextField Theme
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: MyColors.offWhite,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: MyColors.offWhite),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: MyColors.offWhite),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: MyColors.primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: MyColors.errorColor),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: MyColors.errorColor, width: 2),
                  ),
                  labelStyle: TextStyle(
                    color: MyColors.textSecondary,
                    fontSize: 14,
                  ),
                  hintStyle: TextStyle(
                    color: MyColors.textTertiary,
                    fontSize: 14,
                  ),
                ),
                // Icon Theme
                iconTheme: const IconThemeData(
                  color: MyColors.primaryColor,
                  size: 24,
                ),
                // SnackBar Theme
                snackBarTheme: SnackBarThemeData(
                  backgroundColor: MyColors.textPrimary,
                  contentTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Dialog Theme
                dialogTheme: DialogTheme(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: MyColors.surfaceColor,
                  elevation: 8,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
