import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/helpers/admin_password.dart';
import 'package:zad_aldaia/core/helpers/share.dart';
import 'package:zad_aldaia/core/helpers/translator.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/core/theming/my_text_style.dart';
import 'package:zad_aldaia/features/items/data/models/item.dart';
import 'package:zad_aldaia/generated/l10n.dart';

class TextItem extends StatefulWidget {
  final Item item;
  final bool? isSelected;
  final Function(Item)? onSelect;
  final Function(Item)? onItemUp;
  final Function(Item)? onItemDown;
  final Function(Item)? onDeleted;

  const TextItem(
      {super.key,
      required this.item,
      this.onSelect,
      this.isSelected,
      this.onItemUp,
      this.onItemDown,
      this.onDeleted});

  @override
  State<TextItem> createState() => _TextItemState();
}

class _TextItemState extends State<TextItem> {
  late String content;
  bool isTranslating = false;
  late Map<String, String> languageMap;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    languageMap = {
      S.of(context).original_text: "Original Text",
      S.of(context).english: "en",
      S.of(context).spanish: "es",
      S.of(context).chinese: "zh",
      S.of(context).hindi: "hi",
      S.of(context).arabic: "ar",
      S.of(context).french: "fr",
      S.of(context).bengali: "bn",
      S.of(context).russian: "ru",
      S.of(context).portuguese: "pt",
      S.of(context).urdu: "ur",
      S.of(context).german: "de",
      S.of(context).japanese: "ja",
      S.of(context).punjabi: "pa",
      S.of(context).telugu: "te",
    };
  }

  @override
  void initState() {
    super.initState();
    content = widget.item.content ?? '';
  }

  @override
  Widget build(BuildContext context) {
    // Parse background color if provided
    Color? bgColor;
    if (widget.item.backgroundColor != null &&
        widget.item.backgroundColor!.isNotEmpty) {
      try {
        final colorStr = widget.item.backgroundColor!;
        if (colorStr.startsWith('#')) {
          // Handle hex color
          final hexColor = colorStr.replaceAll('#', '');
          bgColor = Color(int.parse('FF$hexColor', radix: 16));
        } else {
          // Handle named colors
          final colorMap = {
            'lightblue': const Color(0xFFE5F3FF),
            'lightyellow': const Color(0xFFFFF9E5),
            'lightgreen': const Color(0xFFE5FFE5),
            'lightpink': const Color(0xFFFFE5E5),
            'lightgray': const Color(0xFFF5F5F5),
          };
          bgColor = colorMap[colorStr.toLowerCase()];
        }
      } catch (e) {
        // If parsing fails, use no background color
        bgColor = null;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: bgColor != null
          ? BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: bgColor != null ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.copy, color: MyColors.primaryColor),
                onPressed: _copyToClipboard,
                tooltip: 'Copy',
              ),
              Expanded(
                child: Text(
                  widget.item.title ?? 'Text Content',
                  style: MyTextStyle.headingSmall.copyWith(
                    color: MyColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          children: [
          if (widget.item.note != null && widget.item.note!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: MyColors.infoColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: MyColors.infoColor),
                      const SizedBox(width: 6),
                      Text(
                        'Note',
                        style: MyTextStyle.labelMedium.copyWith(
                          color: MyColors.infoColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    widget.item.note!,
                    style: MyTextStyle.bodySmall.copyWith(
                      color: MyColors.textPrimary,
                    ),
                  ),
                ],
              ),
            )
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              content,
              style: MyTextStyle.bodyMedium,
            ),
          ),
          _buildActionBar(),
        ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildTranslationButton(),
              IconButton(
                icon: const Icon(Icons.share, color: MyColors.primaryColor),
                onPressed: () => Share.item(widget.item),
              ),
            ],
          ),
          Row(
            children: [
              if (Supabase.instance.client.auth.currentUser != null) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_upward, color: MyColors.primaryColor),
                  onPressed: () => widget.onItemUp?.call(widget.item),
                  tooltip: 'Move up',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, color: MyColors.primaryColor),
                  onPressed: () => widget.onItemDown?.call(widget.item),
                  tooltip: 'Move down',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: MyColors.primaryColor),
                  onPressed: () => Navigator.of(context).pushNamed(
                      MyRoutes.addItemScreen,
                      arguments: {"id": widget.item.id}),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: MyColors.errorColor),
                  onPressed: () => _handleDelete(),
                  tooltip: 'Delete',
                ),
              ],
              if (widget.isSelected != null)
                IconButton(
                  icon: Icon(
                    widget.isSelected!
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: MyColors.primaryColor,
                  ),
                  onPressed: () => widget.onSelect?.call(widget.item),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationButton() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.translate,
          color: isTranslating ? Colors.grey : const Color(0xFF005A32)),
      onSelected: _handleTranslation,
      itemBuilder: (context) => languageMap.entries
          .map((e) => PopupMenuItem(
                value: e.value,
                child: Text(e.key),
              ))
          .toList(),
    );
  }

  void _handleTranslation(String lang) async {
    if (lang == "Original Text") {
      setState(() => content = widget.item.content ?? '');
      return;
    }

    setState(() => isTranslating = true);
    final translation = await Translator.text(widget.item.content, lang);
    if (translation != null) {
      setState(() => content = HtmlUnescape().convert(translation));
    }
    setState(() => isTranslating = false);
  }

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Content copied to clipboard')),
    );
  }

  Future<void> _handleDelete() async {
    final verified =
        await AdminPasswordDialog.verifyDeleteItem(context, widget.item.title);
    if (!verified) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete this item?\n\n"${widget.item.title}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('article_items')
            .delete()
            .eq('id', widget.item.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully')),
          );
          widget.onDeleted?.call(widget.item);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error deleting item: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
