import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/helpers/admin_password.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/core/theming/my_text_style.dart';
import 'package:zad_aldaia/features/articles/data/models/article.dart';
import 'package:zad_aldaia/services/admin_mode_service.dart';

class ArticleItem extends StatelessWidget {
  final Article article;
  final Function(Article) onPressed;
  final Function(Article)? onDeleted;
  final Function(Article)? onMoveUp;
  final Function(Article)? onMoveDown;
  final bool isFirst;
  final bool isLast;

  const ArticleItem({
    super.key,
    required this.article,
    required this.onPressed,
    this.onDeleted,
    this.onMoveUp,
    this.onMoveDown,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onPressed(article),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon Section
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      MyColors.primaryColor,
                      MyColors.primaryLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Content Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title ?? 'Untitled Article',
                      style: MyTextStyle.headingSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Content counts row
                    Row(
                      children: [
                        _buildCountBadge(
                          Icons.description,
                          article.textCount,
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildCountBadge(
                          Icons.image,
                          article.imageCount,
                          Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _buildCountBadge(
                          Icons.video_library,
                          article.videoCount,
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              if (Supabase.instance.client.auth.currentUser != null &&
                  getIt<AdminModeService>().isAdminMode)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.more_vert,
                    color: MyColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    if (!isFirst)
                      PopupMenuItem(
                        value: 'move_up',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_upward,
                                size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text('Move Up', style: MyTextStyle.bodySmall),
                          ],
                        ),
                      ),
                    if (!isLast)
                      PopupMenuItem(
                        value: 'move_down',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_downward,
                                size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text('Move Down', style: MyTextStyle.bodySmall),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit,
                              size: 18, color: MyColors.primaryColor),
                          const SizedBox(width: 8),
                          Text('Edit', style: MyTextStyle.bodySmall),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete,
                              size: 18, color: MyColors.errorColor),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: MyTextStyle.bodySmall.copyWith(
                              color: MyColors.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.of(context).pushNamed(
                        MyRoutes.addArticleScreen,
                        arguments: {"id": article.id},
                      );
                    } else if (value == 'delete') {
                      await _deleteArticle(context);
                    } else if (value == 'move_up') {
                      onMoveUp?.call(article);
                    } else if (value == 'move_down') {
                      onMoveDown?.call(article);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteArticle(BuildContext context) async {
    final verified =
        await AdminPasswordDialog.verifyDeleteArticle(context, article.title);
    if (!verified) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Article'),
        content: Text(
            'Are you sure you want to delete "${article.title}"?\n\nThis will also delete all items under this article.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('articles')
            .delete()
            .eq('id', article.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${article.title}" deleted successfully!')),
        );

        onDeleted?.call(article);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting article: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Helper widget to display content count badges
  Widget _buildCountBadge(
    IconData icon,
    int count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
