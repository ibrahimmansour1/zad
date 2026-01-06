import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/helpers/admin_password.dart';
import 'package:zad_aldaia/core/helpers/share.dart';
import 'package:zad_aldaia/core/helpers/translator.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
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
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: bgColor != null
          ? BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.item.title ?? 'Text Content',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF005A32),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Color(0xFF005A32)),
              onPressed: _copyToClipboard,
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
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Colors.amber.shade800),
                      const SizedBox(width: 6),
                      Text(
                        'Note',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    widget.item.note!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.amber.shade900,
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
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
          _buildActionBar(),
        ],
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
                icon: const Icon(Icons.share, color: Color(0xFF005A32)),
                onPressed: () => Share.item(widget.item),
              ),
            ],
          ),
          Row(
            children: [
              if (Supabase.instance.client.auth.currentUser != null) ...[
                IconButton(
                  icon:
                      const Icon(Icons.arrow_upward, color: Color(0xFF005A32)),
                  onPressed: () => widget.onItemUp?.call(widget.item),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward,
                      color: Color(0xFF005A32)),
                  onPressed: () => widget.onItemDown?.call(widget.item),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF005A32)),
                  onPressed: () => Navigator.of(context).pushNamed(
                      MyRoutes.addItemScreen,
                      arguments: {"id": widget.item.id}),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _handleDelete(),
                ),
              ],
              if (widget.isSelected != null)
                IconButton(
                  icon: Icon(
                    widget.isSelected!
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: const Color(0xFF005A32),
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
