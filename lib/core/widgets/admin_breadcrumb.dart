import 'package:flutter/material.dart';
import 'package:zad_aldaia/core/widgets/admin_mode_toggle.dart';
import 'package:zad_aldaia/core/widgets/global_home_button.dart';

/// Model to represent a breadcrumb item in the navigation hierarchy
class BreadcrumbItem {
  final String id;
  final String name;
  final String type; // 'language', 'path', 'category', 'subcategory', 'article'

  BreadcrumbItem({
    required this.id,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
      };

  factory BreadcrumbItem.fromJson(Map<String, dynamic> json) => BreadcrumbItem(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        type: json['type'] ?? '',
      );
}

/// Model to hold the complete navigation path
class NavigationPath {
  final BreadcrumbItem? language;
  final BreadcrumbItem? path;
  final BreadcrumbItem? category;
  final BreadcrumbItem? subcategory;
  final BreadcrumbItem? article;

  NavigationPath({
    this.language,
    this.path,
    this.category,
    this.subcategory,
    this.article,
  });

  NavigationPath copyWith({
    BreadcrumbItem? language,
    BreadcrumbItem? path,
    BreadcrumbItem? category,
    BreadcrumbItem? subcategory,
    BreadcrumbItem? article,
  }) {
    return NavigationPath(
      language: language ?? this.language,
      path: path ?? this.path,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      article: article ?? this.article,
    );
  }

  /// Get a formatted string showing current location
  String get locationString {
    final parts = <String>[];
    if (language != null) parts.add('Language: ${language!.name}');
    if (path != null) parts.add('Path: ${path!.name}');
    if (category != null) parts.add('Category: ${category!.name}');
    if (subcategory != null) parts.add('Sub-Cat: ${subcategory!.name}');
    if (article != null) parts.add('Article: ${article!.name}');
    return parts.join(' > ');
  }

  /// Get a short location string for app bar subtitle
  String get shortLocationString {
    final parts = <String>[];
    if (language != null) parts.add(language!.name);
    if (path != null) parts.add(path!.name);
    if (category != null) parts.add(category!.name);
    if (subcategory != null) parts.add(subcategory!.name);
    return parts.join(' > ');
  }
}

/// Widget to display breadcrumb navigation in admin screens
class AdminBreadcrumb extends StatelessWidget {
  final NavigationPath? navigationPath;
  final String currentTitle;

  const AdminBreadcrumb({
    super.key,
    this.navigationPath,
    required this.currentTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          currentTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Exo',
          ),
        ),
        if (navigationPath != null &&
            navigationPath!.shortLocationString.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildBreadcrumbItems(context),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildBreadcrumbItems(BuildContext context) {
    final items = <Widget>[];

    void addItem(String label, String value, {bool isLast = false}) {
      items.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label: ',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

      if (!isLast) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              Icons.chevron_right,
              size: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        );
      }
    }

    if (navigationPath?.language != null) {
      addItem('Lang', navigationPath!.language!.name,
          isLast: navigationPath!.path == null);
    }
    if (navigationPath?.path != null) {
      addItem('Path', navigationPath!.path!.name,
          isLast: navigationPath!.category == null);
    }
    if (navigationPath?.category != null) {
      addItem('Cat', navigationPath!.category!.name,
          isLast: navigationPath!.subcategory == null);
    }
    if (navigationPath?.subcategory != null) {
      addItem('Sub', navigationPath!.subcategory!.name,
          isLast: navigationPath!.article == null);
    }
    if (navigationPath?.article != null) {
      addItem('Art', navigationPath!.article!.name, isLast: true);
    }

    return items;
  }
}

/// App bar that includes breadcrumb navigation
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final NavigationPath? navigationPath;
  final List<Widget>? actions;
  final Widget? leading;

  const AdminAppBar({
    super.key,
    required this.title,
    this.navigationPath,
    this.actions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 24);

  @override
  Widget build(BuildContext context) {
    final resolvedActions = <Widget>[
      const AdminModeIndicator(),
      const AdminModeQuickToggle(),
      GlobalHomeButton(),
      ...?actions,
    ];

    return AppBar(
      leading: leading,
      title: AdminBreadcrumb(
        currentTitle: title,
        navigationPath: navigationPath,
      ),
      centerTitle: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF005A32), Color(0xFF008A45)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: resolvedActions,
      toolbarHeight: preferredSize.height,
    );
  }
}
