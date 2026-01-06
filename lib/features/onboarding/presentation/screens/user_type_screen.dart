import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
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
    final Color borderColor = isSelected ? Colors.green.shade700 : Colors.grey.shade300;
    final Color textColor = Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 210,
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 247, 247, 228),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 100, width: 100),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Exo',
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
