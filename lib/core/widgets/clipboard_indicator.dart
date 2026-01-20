import 'package:flutter/material.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/services/admin_auth_service.dart';
import 'package:zad_aldaia/services/admin_mode_service.dart';
import 'package:zad_aldaia/services/content_clipboard_service.dart';

/// Floating clipboard indicator that shows when content is copied
/// and allows quick paste actions
class ClipboardIndicator extends StatefulWidget {
  final VoidCallback? onPastePressed;
  final String? targetParentId;
  final String? targetTable;

  const ClipboardIndicator({
    super.key,
    this.onPastePressed,
    this.targetParentId,
    this.targetTable,
  });

  @override
  State<ClipboardIndicator> createState() => _ClipboardIndicatorState();
}

class _ClipboardIndicatorState extends State<ClipboardIndicator>
    with SingleTickerProviderStateMixin {
  late final ContentClipboardService _clipboard;
  late final AdminModeService _adminMode;
  late final AdminAuthService _adminAuth;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _clipboard = getIt<ContentClipboardService>();
    _adminMode = getIt<AdminModeService>();
    _adminAuth = getIt<AdminAuthService>();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    if (_clipboard.hasContent()) {
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _getContentTypeIcon(String? type) {
    switch (type) {
      case 'language':
        return '🌐';
      case 'path':
        return '📂';
      case 'section':
      case 'branch':
      case 'topic':
        return '📁';
      case 'article':
        return '📄';
      case 'item':
      case 'content_item':
        return '📝';
      default:
        return '📋';
    }
  }

  String _getContentTypeName(String? type) {
    switch (type) {
      case 'language':
        return 'Language';
      case 'path':
        return 'Path';
      case 'section':
        return 'Section';
      case 'branch':
        return 'Branch';
      case 'topic':
        return 'Topic';
      case 'article':
        return 'Article';
      case 'item':
      case 'content_item':
        return 'Item';
      default:
        return 'Content';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show for logged in admins in admin mode
    if (!_adminAuth.isAdminLoggedIn || !_adminMode.isAdminMode) {
      return const SizedBox.shrink();
    }

    if (!_clipboard.hasContent()) {
      return const SizedBox.shrink();
    }

    final content = _clipboard.getCopiedContent();
    final typeIcon = _getContentTypeIcon(content?.sourceType);
    final typeName = _getContentTypeName(content?.sourceType);
    final title = content?.data['title'] ?? content?.data['name'] ?? 'Unnamed';

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: MyColors.primaryColor,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onPastePressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(typeIcon, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$typeName copied',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          title.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.content_paste,
                      color: MyColors.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      _clipboard.clear();
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini clipboard indicator for app bars
class ClipboardBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const ClipboardBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final clipboard = getIt<ContentClipboardService>();
    final adminMode = getIt<AdminModeService>();
    final adminAuth = getIt<AdminAuthService>();

    if (!adminAuth.isAdminLoggedIn ||
        !adminMode.isAdminMode ||
        !clipboard.hasContent()) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: onTap,
      tooltip: 'Clipboard: ${clipboard.contentType}',
      icon: Stack(
        children: [
          const Icon(Icons.content_paste, color: Colors.white),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
