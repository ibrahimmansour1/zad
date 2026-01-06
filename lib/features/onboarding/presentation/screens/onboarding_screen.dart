import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intro_screen_onboarding_flutter/introduction.dart';
import 'package:intro_screen_onboarding_flutter/introscreenonboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/features/onboarding/presentation/screens/user_type_screen.dart';
import 'package:zad_aldaia/main.dart';

class OnboardingScreen extends StatelessWidget {
  OnboardingScreen({super.key});

  final List<Introduction> list = [
    Introduction(
      title: 'Welcome to Zad Al-Daiya',
      subTitle:
          'A comprehensive da\'wah platform for spreading Islam and educating new Muslims',
      imageUrl: 'assets/images/png/onboarding1.png',
      titleTextStyle: TextStyle(
        fontSize: 18.sp,
        fontFamily: 'Exo',
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      subTitleTextStyle: TextStyle(
        fontSize: 14.sp,
        color: Colors.black.withOpacity(0.5),
      ),
    ),
    Introduction(
      title: 'Learn Your Religion Easily',
      subTitle:
          'Lessons, videos, books - everything you need to understand Islam',
      imageUrl: 'assets/images/png/onboarding2.png',
      titleTextStyle: TextStyle(
        fontSize: 18.sp,
        fontFamily: 'Exo',
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      subTitleTextStyle: TextStyle(
        fontSize: 14.sp,
        color: Colors.black.withOpacity(0.5),
      ),
    ),
    Introduction(
      title: 'Be a Caller to Allah',
      subTitle: 'Contribute to spreading Islam and impact others\' lives',
      imageUrl: 'assets/images/png/onboarding4.png',
      titleTextStyle: TextStyle(
        fontSize: 18.sp,
        fontFamily: 'Exo',
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      subTitleTextStyle: TextStyle(
        fontSize: 14.sp,
        color: Colors.black.withOpacity(0.5),
      ),
    ),
  ];

  /// Mark onboarding as completed and navigate to user type screen
  Future<void> _completeOnboarding(BuildContext context) async {
    final sp = getIt<SharedPreferences>();
    await sp.setBool(kHasOnboardedKey, true);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const UserTypeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAE6),
      body: IntroScreenOnboarding(
        backgroudColor: const Color(0xFFF0FAE6),
        foregroundColor: Colors.green.shade700,
        introductionList: list,
        onTapSkipButton: () => _completeOnboarding(context),
        skipTextStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
