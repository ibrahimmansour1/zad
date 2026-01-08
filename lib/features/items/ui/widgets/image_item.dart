import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/helpers/admin_password.dart';
import 'package:zad_aldaia/core/helpers/share.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/core/theming/my_text_style.dart';
import 'package:zad_aldaia/features/items/data/models/item.dart';

class ImageItem extends StatefulWidget {
  final Item item;
  final bool? isSelected;
  final Function(Item)? onSelect;
  final Function(Item)? onItemUp;
  final Function(Item)? onItemDown;
  final Function(Item)? onDeleted;
  final Future Function(String) onDownloadPressed;

  const ImageItem(
      {super.key,
      required this.item,
      required this.onDownloadPressed,
      this.onSelect,
      this.isSelected,
      this.onItemUp,
      this.onItemDown,
      this.onDeleted});

  @override
  State<ImageItem> createState() => _ImageItemState();
}

class _ImageItemState extends State<ImageItem> {
  bool isDownloading = false;

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
        child: Column(
          children: [
            ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                widget.item.title ?? 'Image',
                style: MyTextStyle.headingSmall.copyWith(
                  color: MyColors.primaryColor,
                ),
              ),
              children: [
                if (widget.item.note != null &&
                    widget.item.note!.isNotEmpty) ...[
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
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.item.imageUrl ?? '',
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                _buildActionBar(),
              ],
            ),
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
              IconButton(
                icon: isDownloading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(),
                      )
                    : Icon(Icons.download, color: MyColors.primaryColor),
                onPressed: isDownloading ? null : _downloadImage,
              ),
              IconButton(
                icon: Icon(Icons.share, color: MyColors.primaryColor),
                onPressed: () => Share.item(widget.item),
              ),
            ],
          ),
          Row(
            children: [
              if (Supabase.instance.client.auth.currentUser != null) ...[
                IconButton(
                  icon: Icon(Icons.arrow_upward, color: MyColors.primaryColor),
                  onPressed: () => widget.onItemUp?.call(widget.item),
                ),
                IconButton(
                  icon:
                      Icon(Icons.arrow_downward, color: MyColors.primaryColor),
                  onPressed: () => widget.onItemDown?.call(widget.item),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: MyColors.primaryColor),
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

  Future<void> _downloadImage() async {
    setState(() => isDownloading = true);
    try {
      await widget.onDownloadPressed(widget.item.imageUrl ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image downloaded successfully')),
      );
    } finally {
      setState(() => isDownloading = false);
    }
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
            'Are you sure you want to delete this image?\n\n"${widget.item.title}"'),
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
            const SnackBar(content: Text('Image deleted successfully')),
          );
          widget.onDeleted?.call(widget.item);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error deleting image: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
