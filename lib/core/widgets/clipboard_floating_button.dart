import 'package:flutter/material.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/core/widgets/paste_content_dialog.dart';
import 'package:zad_aldaia/services/admin_auth_service.dart';
import 'package:zad_aldaia/services/admin_mode_service.dart';
import 'package:zad_aldaia/services/content_clipboard_service.dart';

/// Floating action button that shows when clipboard has content
/// Allows quick paste from anywhere
class ClipboardFloatingButton extends StatefulWidget {
  final String? targetParentId;
  final String? targetTable;
  final String? targetTitle;
  final VoidCallback? onPasted;

  const ClipboardFloatingButton({
    super.key,
    this.targetParentId,
    this.targetTable,
    this.targetTitle,
    this.onPasted,
  });

  @override
  State<ClipboardFloatingButton> createState() =>
      _ClipboardFloatingButtonState();
}

class _ClipboardFloatingButtonState extends State<ClipboardFloatingButton> {
  late final ContentClipboardService _clipboard;
  late final AdminModeService _adminMode;
  late final AdminAuthService _adminAuth;

  @override
  void initState() {
    super.initState();
    _clipboard = getIt<ContentClipboardService>();
    _adminMode = getIt<AdminModeService>();
    _adminAuth = getIt<AdminAuthService>();
    // Listen to clipboard changes
    _clipboard.addListener(_onClipboardChange);
  }

  @override
  void dispose() {
    _clipboard.removeListener(_onClipboardChange);
    super.dispose();
  }

  void _onClipboardChange() {
    if (mounted) setState(() {});
  }

  String _getContentTypeIcon(String type) {
    switch (type) {
      case 'language':
      case 'languages':
        return '🌐';
      case 'path':
      case 'paths':
        return '📂';
      case 'section':
      case 'sections':
      case 'branch':
      case 'branches':
      case 'topic':
      case 'topics':
        return '📁';
      case 'article':
      case 'articles':
        return '📄';
      case 'item':
      case 'article_items':
      case 'content_item':
        return '📝';
      default:
        return '📋';
    }
  }

  Future<void> _showPasteDialog() async {
    if (widget.targetParentId == null || widget.targetTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot paste here - target location not specified'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await PasteContentDialog.show(
      context: context,
      targetParentId: widget.targetParentId!,
      targetTable: widget.targetTable!,
      targetTitle: widget.targetTitle,
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content pasted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onPasted?.call();
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
    final typeIcon = _getContentTypeIcon(content?.sourceType ?? '');
    final title = content?.data['title'] ?? content?.data['name'] ?? 'Content';

    return FloatingActionButton.extended(
      onPressed: _showPasteDialog,
      backgroundColor: MyColors.primaryColor,
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(typeIcon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          const Icon(Icons.content_paste, color: Colors.white, size: 20),
        ],
      ),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paste',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            title.toString(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
