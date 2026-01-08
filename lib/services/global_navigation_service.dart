import 'package:flutter/material.dart';
import 'package:zad_aldaia/core/routing/routes.dart';

/// Service to manage global navigation (especially home navigation)
class GlobalNavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Get current context from navigator
  BuildContext? get currentContext => navigatorKey.currentContext;

  /// Navigate to home from anywhere
  void navigateToHome() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    var reachedHome = false;

    // Prefer popping back to an existing Home route so we don't nuke state
    navigator.popUntil((route) {
      final isHome = route.settings.name == MyRoutes.homeScreen;
      if (isHome) {
        reachedHome = true;
      }
      return isHome || route.isFirst;
    });

    // If home was not in the stack, push it without clearing history
    if (!reachedHome) {
      navigator.pushNamed(MyRoutes.homeScreen);
    }
  }

  /// Navigate to home without removing stack (allows back navigation)
  void pushHome() {
    if (currentContext == null) return;

    Navigator.of(currentContext!).pushNamed(MyRoutes.homeScreen);
  }

  /// Pop to home if it exists in stack, otherwise push
  void popOrPushHome() {
    if (currentContext == null) return;

    // Try to pop until home
    Navigator.of(currentContext!).popUntil(
      (route) => route.settings.name == MyRoutes.homeScreen || route.isFirst,
    );
  }

  /// Check if we can go back
  bool canGoBack() {
    if (currentContext == null) return false;
    return Navigator.of(currentContext!).canPop();
  }

  /// Go back one screen
  void goBack() {
    if (currentContext == null) return;
    if (canGoBack()) {
      Navigator.of(currentContext!).pop();
    }
  }

  /// Navigate to any route by name
  void navigateTo(String routeName, {Object? arguments}) {
    if (currentContext == null) return;

    Navigator.of(currentContext!).pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Replace current route with another
  void replaceTo(String routeName, {Object? arguments}) {
    if (currentContext == null) return;

    Navigator.of(currentContext!).pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Clear all and navigate to route
  void navigateAndClearStack(String routeName, {Object? arguments}) {
    if (currentContext == null) return;

    Navigator.of(currentContext!).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
}
