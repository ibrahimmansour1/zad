import 'package:flutter/material.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/core/theming/my_text_style.dart';
import 'package:zad_aldaia/services/content_clipboard_service.dart';
import 'package:zad_aldaia/services/content_paste_service.dart';

/// Dialog for pasting content with different modes
class PasteContentDialog extends StatefulWidget {
  final String targetParentId;
  final String targetTable;
  final String? targetTitle;

  const PasteContentDialog({
    super.key,
    required this.targetParentId,
    required this.targetTable,
    this.targetTitle,
  });

  /// Show the paste dialog and return the result
  static Future<PasteResult?> show({
    required BuildContext context,
    required String targetParentId,
    required String targetTable,
    String? targetTitle,
  }) async {
    return showDialog<PasteResult>(
      context: context,
      builder: (context) => PasteContentDialog(
        targetParentId: targetParentId,
        targetTable: targetTable,
        targetTitle: targetTitle,
      ),
    );
  }

  @override
  State<PasteContentDialog> createState() => _PasteContentDialogState();
}

class _PasteContentDialogState extends State<PasteContentDialog> {
  final _clipboard = getIt<ContentClipboardService>();
  final _pasteService = getIt<ContentPasteService>();
  final _titleController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  PasteMode _selectedMode = PasteMode.clone;

  @override
  void initState() {
    super.initState();
    final content = _clipboard.getCopiedContent();
    if (content != null) {
      final originalTitle = content.data['title'] ?? content.data['name'] ?? '';
      _titleController.text = '$originalTitle (Copy)';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
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

  Future<void> _handlePaste() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _pasteService.paste(
        targetParentId: widget.targetParentId,
        targetTableName: widget.targetTable,
        mode: _selectedMode,
        customTitle: _selectedMode != PasteMode.move
            ? _titleController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _clipboard.getCopiedContent();
    if (content == null) {
      return AlertDialog(
        title: const Text('No Content'),
        content: const Text('Nothing in clipboard to paste.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    final icon = _getContentTypeIcon(content.sourceType);
    final originalTitle =
        content.data['title'] ?? content.data['name'] ?? 'Unnamed';

    return AlertDialog(
      title: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          const Expanded(child: Text('Paste Content')),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.content_copy, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Source: $originalTitle',
                            style: MyTextStyle.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Type: ${content.sourceType}',
                            style: MyTextStyle.bodySmall.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Target info
              if (widget.targetTitle != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MyColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder_open, color: MyColors.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Paste into: ${widget.targetTitle}',
                          style: MyTextStyle.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: MyColors.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Paste mode selection
              const Text(
                'Choose paste mode:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Clone option
              _buildModeOption(
                mode: PasteMode.clone,
                icon: Icons.copy_all,
                title: 'Clone (Copy)',
                description: 'Create an independent copy with all children',
                color: Colors.blue,
              ),
              const SizedBox(height: 8),

              // Move option
              _buildModeOption(
                mode: PasteMode.move,
                icon: Icons.drive_file_move,
                title: 'Move',
                description: 'Move content from original location to here',
                color: Colors.orange,
              ),
              const SizedBox(height: 8),

              // Reference option (disabled for now with message)
              _buildModeOption(
                mode: PasteMode.reference,
                icon: Icons.link,
                title: 'Link (Reference)',
                description: 'Create a link to original content (updates sync)',
                color: Colors.purple,
                enabled: false, // References require special table setup
              ),
              const SizedBox(height: 16),

              // Custom title field (for clone mode)
              if (_selectedMode == PasteMode.clone) ...[
                const Text(
                  'New title:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter title for the copy',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
              ],

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handlePaste,
          style: ElevatedButton.styleFrom(
            backgroundColor: MyColors.primaryColor,
          ),
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.content_paste, color: Colors.white),
          label: Text(
            _isLoading ? 'Pasting...' : 'Paste',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildModeOption({
    required PasteMode mode,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    bool enabled = true,
  }) {
    final isSelected = _selectedMode == mode;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? () => setState(() => _selectedMode = mode) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : Colors.black87,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (!enabled)
                      Text(
                        '(Coming soon)',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
