import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/helpers/language.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/core/theming/my_text_style.dart';
import 'package:zad_aldaia/core/widgets/admin_mode_toggle.dart';
import 'package:zad_aldaia/features/auth/auth_cubit.dart';
import 'package:zad_aldaia/features/categories/logic/categories_cubit.dart';
import 'package:zad_aldaia/features/import/json_import_screen.dart';
import 'package:zad_aldaia/services/admin_auth_service.dart';
import 'package:zad_aldaia/services/admin_mode_service.dart';
import 'package:zad_aldaia/services/admin_permission_service.dart';
import 'package:zad_aldaia/services/backup_service.dart';
import 'package:zad_aldaia/services/offline_content_service.dart';

import 'sections_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final authCubit = getIt<AuthCubit>();
  final cubit = getIt<CategoriesCubit>();
  final adminAuth = getIt<AdminAuthService>();
  final adminMode = getIt<AdminModeService>();
  final adminPermissionService = getIt<AdminPermissionService>();
  int _selectedIndex = 1;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> adminPasswordFormKey = GlobalKey<FormState>();
  String? passwordError;
  bool checkingPassword = false;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const Placeholder(),
      const SectionsScreen(),
      const Placeholder(),
      const Placeholder(),
      const Placeholder(),
    ];

    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: pages[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildHeader() {
    final user = Supabase.instance.client.auth.currentUser;
    final avatarImage = user != null
        ? 'assets/images/png/imam_icon.png'
        : 'assets/images/png/muslim_icon.png';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MyColors.primaryColor,
            MyColors.primaryDark,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: MyColors.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Assalam Alakum 👋',
                      style: MyTextStyle.displaySmall.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome Back!',
                      style: MyTextStyle.bodyLarge.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage(avatarImage),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const AdminModeIndicator(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surfaceColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: GNav(
            gap: 8,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            duration: const Duration(milliseconds: 300),
            tabBackgroundColor: MyColors.primaryColor,
            activeColor: Colors.white,
            color: MyColors.textSecondary,
            tabs: const [
              GButton(icon: LineIcons.search, text: 'Search'),
              GButton(icon: LineIcons.home, text: 'Home'),
              GButton(icon: LineIcons.cog, text: 'Settings'),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              if (index == 0) {
                Navigator.of(context).pushNamed(MyRoutes.searchScreen);
              } else if (index == 2) {
                showSettingsMenu(context);
              } else {
                setState(() => _selectedIndex = index);
              }
            },
          ),
        ),
      ),
    );
  }

  void showSettingsMenu(BuildContext rootContext) {
    bool isLanguageExpanded = false;

    showModalBottomSheet(
      context: rootContext,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return FutureBuilder<String>(
          future: Lang.get(),
          builder: (context, snapshot) {
            final currentLang = snapshot.data ?? Lang.defaultLang;

            return StatefulBuilder(
              builder: (context, setState) {
                return FractionallySizedBox(
                  heightFactor: 0.6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: MyColors.backgroundColor,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),

                        Text(
                          'Language Cible',
                          style: MyTextStyle.headingMedium,
                        ),
                        const SizedBox(height: 10),

                        // Animated Container (Selector + Dropdown)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: MyColors.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() =>
                                    isLanguageExpanded = !isLanguageExpanded),
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Image.asset(
                                          'assets/images/flags/$currentLang.png',
                                          width: 32,
                                          height: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _getLanguageDisplayName(currentLang),
                                          style: MyTextStyle.headingSmall,
                                        ),
                                      ],
                                    ),
                                    AnimatedRotation(
                                      turns: isLanguageExpanded ? 0.5 : 0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.green.shade900,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Expanded List inside the same container
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 300),
                                crossFadeState: isLanguageExpanded
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                                firstChild: Column(
                                  children: Lang.values
                                      .where((lang) => lang != currentLang)
                                      .map((lang) => ListTile(
                                            contentPadding:
                                                const EdgeInsets.only(left: 0),
                                            leading: Image.asset(
                                              'assets/images/flags/$lang.png',
                                              width: 28,
                                              height: 28,
                                            ),
                                            title: Text(
                                                _getLanguageDisplayName(lang)),
                                            onTap: () async {
                                              await Lang.set(lang);
                                              setState(() =>
                                                  isLanguageExpanded = false);
                                              Navigator.pushReplacement(
                                                rootContext,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const HomeScreen(),
                                                ),
                                              );
                                            },
                                          ))
                                      .toList(),
                                ),
                                secondChild: const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Offline Content section - available to all users
                        const Text(
                          'Offline Content',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Icon(Icons.download_for_offline,
                                color: Colors.teal.shade700),
                            title: const Text("Download for Offline Use"),
                            subtitle: const Text(
                                "Save content to use without internet"),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () async {
                              Navigator.of(sheetContext).pop();
                              await OfflineContentService
                                  .showLanguageSelectorAndDownload(rootContext);
                            },
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Only show Account Settings if admin is logged in
                        if (adminAuth.isAdminLoggedIn) ...[
                          const Text(
                            'Admin Settings',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: AdminModeToggle(),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: Icon(Icons.language,
                                      color: Colors.green.shade700),
                                  title: const Text("Manage Languages"),
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 16),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    Navigator.of(rootContext)
                                        .pushNamed(MyRoutes.languages);
                                  },
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: Icon(Icons.backup,
                                      color: Colors.blue.shade700),
                                  title: const Text("Backup to JSON"),
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 16),
                                  onTap: () async {
                                    Navigator.of(sheetContext).pop();
                                    await BackupService.saveAndShareJson(
                                        rootContext);
                                  },
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: Icon(Icons.table_chart,
                                      color: Colors.green.shade600),
                                  title: const Text("Backup to CSV"),
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 16),
                                  onTap: () async {
                                    Navigator.of(sheetContext).pop();
                                    await BackupService.saveAndShareCSV(
                                        rootContext);
                                  },
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: Icon(Icons.upload_file,
                                      color: Colors.orange.shade700),
                                  title: const Text("Import from JSON"),
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 16),
                                  onTap: () async {
                                    Navigator.of(sheetContext).pop();
                                    await BackupService.importFromJson(
                                        rootContext);
                                  },
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: Icon(Icons.auto_fix_high,
                                      color: Colors.purple.shade700),
                                  title: const Text("Advanced JSON Import"),
                                  subtitle: const Text(
                                      "Map custom JSON to app fields",
                                      style: TextStyle(fontSize: 12)),
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 16),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    Navigator.of(rootContext).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const JsonImportScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(Icons.logout,
                                      color: Colors.red),
                                  title: const Text("Logout",
                                      style: TextStyle(color: Colors.red)),
                                  onTap: () async {
                                    Navigator.of(sheetContext).pop();
                                    await adminAuth.logout();
                                    adminPermissionService.clearCache();
                                    await adminMode.enableUserMode();
                                    await Supabase.instance.client.auth
                                        .signOut();
                                    Navigator.of(rootContext)
                                        .pushNamedAndRemoveUntil(
                                      MyRoutes.usertype,
                                      (route) => false,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _getLanguageDisplayName(String langCode) {
    switch (langCode) {
      case 'english':
        return 'English';
      case 'espanol':
        return 'Español';
      case 'portugues':
        return 'Português';
      case 'francais':
        return 'Français';
      case 'filipino':
        return 'Filipino';
      default:
        return 'English';
    }
  }
}
