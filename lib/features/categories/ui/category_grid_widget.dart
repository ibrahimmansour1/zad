import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/helpers/admin_password.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/features/categories/data/models/category.dart';

class CategoryGridWidget extends StatefulWidget {
  final Category category;
  final int itemCount;
  final VoidCallback? onTap;
  final Function(Category)? onMoveUp;
  final Function(Category)? onMoveDown;
  final VoidCallback? onDeleted;

  const CategoryGridWidget({
    super.key,
    required this.category,
    required this.itemCount,
    this.onTap,
    this.onMoveUp,
    this.onMoveDown,
    this.onDeleted,
  });

  @override
  State<CategoryGridWidget> createState() => _CategoryGridWidgetState();
}

class _CategoryGridWidgetState extends State<CategoryGridWidget>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  double _scale = 1.0;
  double _elevation = 6.0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        _isHovered = true;
        _scale = 1.05;
        _elevation = 16.0;
      }),
      onExit: (_) => setState(() {
        _isHovered = false;
        _scale = 1.0;
        _elevation = 6.0;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 200),
          child: AnimatedOpacity(
            opacity: widget.category.isActive ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 300),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(_isHovered ? -0.08 : 0.0)
                    ..rotateY(_isHovered ? 0.05 : 0.0)
                    ..translate(0.0, _animation.value * 20, 0.0),
                  alignment: FractionalOffset.center,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade300.withOpacity(0.8),
                          blurRadius: _elevation * 1.5,
                          spreadRadius: _elevation / 3,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: widget.onTap,
                        splashColor: Colors.green.withOpacity(0.3),
                        highlightColor: Colors.green.withOpacity(0.1),
                        child: Stack(
                          children: [
                            // 1. Background Image with Blur
                            if (widget.category.image != null &&
                                widget.category.image!.isNotEmpty)
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: widget.category.image!
                                                .startsWith('http')
                                            ? Image.network(
                                                widget.category.image!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Container(
                                                        color: Colors
                                                            .green.shade50),
                                              )
                                            : Image.asset(
                                                widget.category.image!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Container(
                                                        color: Colors
                                                            .green.shade50),
                                              ),
                                      ),
                                      // Dark overlay and blur
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                          ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 4, sigmaY: 4),
                                          child: Container(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              // Animated gradient background (fallback)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _isHovered
                                        ? [
                                            Colors.green.shade100,
                                            Colors.white,
                                            Colors.green.shade50,
                                          ]
                                        : [
                                            Colors.green.shade50,
                                            Colors.white,
                                            Colors.green.shade100,
                                          ],
                                  ),
                                ),
                              ),

                            // Glossy overlay effect
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Border with animation
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: _isHovered
                                      ? Colors.green.shade800
                                      : Colors.green.shade700,
                                  width: _isHovered ? 3 : 2,
                                ),
                              ),
                            ),

                            // Content (Centrally visible title)
                            Positioned.fill(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: Text(
                                      widget.category.title ?? '-',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                        color: Colors.white,
                                        fontFamily: 'Exo',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        shadows: [
                                          Shadow(
                                            color:
                                                Colors.black.withOpacity(0.8),
                                            blurRadius: 10,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${widget.itemCount} items',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.green.shade900,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (Supabase.instance.client.auth.currentUser !=
                                null)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                left: 0,
                                child: AnimatedOpacity(
                                  opacity: _isHovered ? 1.0 : 0.8,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(24),
                                        bottomRight: Radius.circular(24),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit,
                                              color: Colors.amber.shade800,
                                              size: 20),
                                          onPressed: () {
                                            Navigator.of(context).pushNamed(
                                              MyRoutes.addCategoryScreen,
                                              arguments: {
                                                "id": widget.category.id
                                              },
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red, size: 20),
                                          onPressed: () =>
                                              _handleDelete(context),
                                        ),
                                        IconButton(
                                          onPressed: () => widget.onMoveUp
                                              ?.call(widget.category),
                                          icon: Icon(Icons.arrow_circle_up,
                                              color: Colors.green.shade800,
                                              size: 20),
                                        ),
                                        IconButton(
                                          onPressed: () => widget.onMoveDown
                                              ?.call(widget.category),
                                          icon: Icon(Icons.arrow_circle_down,
                                              color: Colors.green.shade800,
                                              size: 20),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final section = widget.category.section ?? '';
    bool verified = false;

    if (section == 'paths') {
      verified = await AdminPasswordDialog.verifyDeletePath(
          context, widget.category.title);
    } else if (section == 'sections') {
      verified = await AdminPasswordDialog.verifyDeleteCategory(
          context, widget.category.title);
    } else if (section == 'branches' || section == 'topics') {
      verified = await AdminPasswordDialog.verifyDeleteSubcategory(
          context, widget.category.title);
    } else {
      verified = await AdminPasswordDialog.verifyDeleteCategory(
          context, widget.category.title);
    }

    if (!verified) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete "${widget.category.title}"?\n\nThis action cannot be undone.'),
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
        final tableName = section.isNotEmpty ? section : 'categories';
        await Supabase.instance.client
            .from(tableName)
            .delete()
            .eq('id', widget.category.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('"${widget.category.title}" deleted successfully!')),
          );
          widget.onDeleted?.call();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
