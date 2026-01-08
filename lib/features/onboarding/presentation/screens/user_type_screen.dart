import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:zad_aldaia/features/categories/ui/home_screen.dart';
import 'package:zad_aldaia/features/onboarding/presentation/screens/login_screen.dart';

class UserTypeScreen extends StatefulWidget {
  const UserTypeScreen({super.key});

  @override
  State<UserTypeScreen> createState() => _UserTypeScreenState();
}

class _UserTypeScreenState extends State<UserTypeScreen> {
  int _selectedIndex = 0;

  void _onSelect(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAE6),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 200),
          Center(
            child: Text(
              'Choose the user type',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Exo',
                fontSize: 35,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Are you a regular user or a Daiya admin?',
              style: TextStyle(
                color: Colors.black.withOpacity(0.4),
                fontFamily: 'Exo',
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _UserTypeCard(
                title: 'Regular User',
                description: 'Access public features of the app',
                imagePath: 'assets/images/png/muslim_icon.png',
                isSelected: _selectedIndex == 0,
                onTap: () => _onSelect(0),
              ),
              _UserTypeCard(
                title: 'Daiya Admin',
                description: 'Manage and monitor\nthe Daiya platform',
                imagePath: 'assets/images/png/imam_icon.png',
                isSelected: _selectedIndex == 1,
                onTap: () => _onSelect(1),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 350,
              child: OpenContainer(
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                closedElevation: 0,
                closedBuilder: (context, action) {
                  return ElevatedButton(
                    onPressed: action,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF005A32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
                openBuilder: (context, _) {
                  return _selectedIndex == 0
                      ? const HomeScreen()
                      : const LoginScreen();
                },
                transitionDuration: const Duration(milliseconds: 600),
                closedColor: Colors.transparent,
                openColor: const Color(0xFFF0FAE6),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 220,
        width: 160,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF005A32).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF005A32) : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF005A32).withOpacity(0.15)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 12 : 8,
              offset: isSelected ? const Offset(0, 6) : const Offset(0, 2),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Container
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF005A32).withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      imagePath,
                      height: 50,
                      width: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Exo',
                      color: Colors.black.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withOpacity(0.45),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  // Selection Indicator
                  if (isSelected)
                    Container(
                      height: 4,
                      width: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF005A32),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
