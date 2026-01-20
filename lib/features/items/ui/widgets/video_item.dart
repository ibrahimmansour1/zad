import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/helpers/admin_password.dart';
import 'package:zad_aldaia/core/helpers/share.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/core/theming/my_text_style.dart';
import 'package:zad_aldaia/features/items/data/models/item.dart';
import 'package:zad_aldaia/services/admin_mode_service.dart';
import 'package:zad_aldaia/services/content_clipboard_service.dart';
import 'package:zad_aldaia/services/soft_delete_service.dart';

class VideoItem extends StatefulWidget {
  final Item item;
  final bool? isSelected;
  final Function(Item)? onSelect;
  final Function(Item)? onItemUp;
  final Function(Item)? onItemDown;
  final Function(Item)? onDeleted;

  const VideoItem(
      {super.key,
      required this.item,
      this.onSelect,
      this.isSelected,
      this.onItemUp,
      this.onItemDown,
      this.onDeleted});

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId =
        YoutubePlayer.convertUrlToId(widget.item.youtubeUrl ?? '') ?? '';
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                widget.item.title ?? 'Video',
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
                    child: YoutubePlayer(
                      controller: _controller,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: MyColors.primaryColor,
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
          IconButton(
            icon: Icon(Icons.share, color: MyColors.primaryColor),
            onPressed: () => Share.item(widget.item),
          ),
          Row(
            children: [
              if (Supabase.instance.client.auth.currentUser != null &&
                  getIt<AdminModeService>().isAdminMode) ...[
                IconButton(
                  icon: Icon(Icons.content_copy_outlined,
                      color: MyColors.primaryColor),
                  onPressed: () => _copyItemToClipboard(),
                  tooltip: 'Copy Item',
                ),
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

  Future<void> _handleDelete() async {
    final verified =
        await AdminPasswordDialog.verifyDeleteItem(context, widget.item.title);
    if (!verified) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete this video?\n\n"${widget.item.title}"\n\nIt will be moved to the Recycle Bin.'),
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
        final softDeleteService = getIt<SoftDeleteService>();
        await softDeleteService.softDelete(
          tableName: 'article_items',
          id: widget.item.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video moved to Recycle Bin')),
          );
          widget.onDeleted?.call(widget.item);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error deleting video: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _copyItemToClipboard() {
    final clipboard = getIt<ContentClipboardService>();
    clipboard.copy(
      id: widget.item.id,
      type: 'item',
      data: {
        'title': widget.item.title,
        'youtube_url': widget.item.youtubeUrl,
        'type': widget.item.type.name,
        'article_id': widget.item.articleId,
        'table': 'article_items',
      },
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${widget.item.title}" copied to clipboard'),
        action: SnackBarAction(
          label: 'CLEAR',
          onPressed: () => clipboard.clear(),
        ),
      ),
    );
  }
}
