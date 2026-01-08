import 'package:flutter/material.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/core/theming/my_text_style.dart';
import 'package:zad_aldaia/features/auth/auth_cubit.dart';
import 'package:zad_aldaia/services/admin_auth_service.dart';
import 'package:zad_aldaia/services/admin_mode_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthCubit authCubit = getIt<AuthCubit>();
  late final AdminAuthService _adminAuthService = getIt<AdminAuthService>();
  late final AdminModeService _adminModeService = getIt<AdminModeService>();
  final GlobalKey<FormState> adminPasswordFormKey = GlobalKey();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? passwordError;
  bool checkingPassword = false;
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: adminPasswordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label: const Text("Back",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                Center(
                  child: Image.asset(
                    'assets/images/png/logo_Z.png',
                    height: 350,
                  ),
                ),
                Center(
                  child: Text(
                    'Login',
                    style: MyTextStyle.headingLarge.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black),
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter your email'
                      : null,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: MyTextStyle.bodyMedium.copyWith(
                      color: MyColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 18.0, horizontal: 16.0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: MyColors.primaryLight, width: 2),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscureText,
                  style: const TextStyle(color: Colors.black),
                  textInputAction: TextInputAction.done,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter password'
                      : null,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: MyTextStyle.bodyMedium.copyWith(
                      color: MyColors.textTertiary,
                    ),
                    errorText: passwordError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: MyColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 18.0, horizontal: 16.0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: MyColors.primaryLight, width: 2),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      if (adminPasswordFormKey.currentState!.validate()) {
                        setState(() {
                          checkingPassword = true;
                        });
                        try {
                          final signedIn = await authCubit.signIn(
                            emailController.text,
                            passwordController.text,
                          );

                          if (signedIn) {
                            passwordError = null;
                            await _adminAuthService
                                .login(emailController.text.trim());
                            await _adminModeService.enableAdminMode();

                            Navigator.of(context).pushReplacementNamed(
                              MyRoutes.homeScreen,
                            );
                          } else {
                            setState(() {
                              passwordError = 'Wrong password';
                            });
                          }
                        } catch (e) {
                          setState(() {
                            passwordError = 'Login failed: $e';
                          });
                        }
                        setState(() {
                          checkingPassword = false;
                        });
                      }
                    },
                    child: checkingPassword
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: MyColors.primaryColor,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Login',
                            style: MyTextStyle.labelLarge.copyWith(
                              color: MyColors.primaryColor,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
