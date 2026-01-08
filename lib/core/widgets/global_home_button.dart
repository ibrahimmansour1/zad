import 'package:flutter/material.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/services/global_navigation_service.dart';

/// Persistent home button that can be added to any screen
class GlobalHomeButton extends StatelessWidget {
  final GlobalNavigationService _navigationService =
      getIt<GlobalNavigationService>();

  GlobalHomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home),
      tooltip: 'Go to Home',
      onPressed: () => _navigationService.navigateToHome(),
    );
  }
}

/// Floating action button for home navigation
class HomeFloatingButton extends StatelessWidget {
  final GlobalNavigationService _navigationService =
      getIt<GlobalNavigationService>();

  HomeFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _navigationService.navigateToHome(),
      tooltip: 'Home',
      child: const Icon(Icons.home),
    );
  }
}

/// Bottom navigation item for home
class HomeNavigationItem {
  static BottomNavigationBarItem get item => const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      );
}
