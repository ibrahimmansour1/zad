import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/helpers/share.dart';
import 'package:zad_aldaia/core/helpers/storage.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/core/theming/my_text_style.dart';
import 'package:zad_aldaia/core/widgets/admin_mode_toggle.dart';
import 'package:zad_aldaia/core/widgets/clipboard_floating_button.dart';
import 'package:zad_aldaia/core/widgets/global_home_button.dart';
import 'package:zad_aldaia/features/items/data/models/item.dart';
import 'package:zad_aldaia/features/items/logic/items_cubit.dart';
import 'package:zad_aldaia/features/items/ui/widgets/image_item.dart';
import 'package:zad_aldaia/features/items/ui/widgets/text_item.dart';
import 'package:zad_aldaia/features/items/ui/widgets/video_item.dart';
import 'package:zad_aldaia/services/admin_mode_service.dart';

class ItemsScreen extends StatefulWidget {
  final String? articleId;
  final String? title;
  final String? scrollToItemId; // NEW: Item to scroll to after navigation
  final String? highlightQuery; // NEW: Search query to highlight

  const ItemsScreen({
    super.key,
    required this.articleId,
    this.title,
    this.scrollToItemId,
    this.highlightQuery,
  });

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen>
    with SingleTickerProviderStateMixin {
  late final ItemsCubit cubit = getIt<ItemsCubit>();
  late TabController _tabController;
  List<Item> selectedItems = [];
  bool _shouldAnimate = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        setState(() {
          if (_tabController.indexIsChanging) {
            _shouldAnimate = true;
          }
        });
      });
    loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _shouldAnimate = true;
      });
      // Handle scroll-to-item after data loads
      if (widget.scrollToItemId != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _scrollToItem(widget.scrollToItemId!);
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void loadData() {
    cubit.loadItems(
        eqMap: {'article_id': widget.articleId}
          ..removeWhere((key, value) => value == null));
  }

  /// Scrolls to a specific item after it's loaded
  void _scrollToItem(String itemId) {
    try {
      // Find the item in the loaded items
      final item = cubit.items.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw Exception('Item not found'),
      );

      // Determine which tab the item belongs to
      int tabIndex = 0;
      if (item.type == ItemType.image) {
        tabIndex = 1;
      } else if (item.type == ItemType.video) {
        tabIndex = 2;
      }

      // Switch to the correct tab
      if (_tabController.index != tabIndex) {
        _tabController.animateTo(tabIndex);
      }

      // TODO: Scroll to item position in the list
      // This would require passing a ScrollController to the ListView
      // For now, the tab switch is sufficient to highlight the found item
      print('Navigated to item: $itemId in tab: $tabIndex');
    } catch (e) {
      print('Error handling scroll to item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      floatingActionButton: ClipboardFloatingButton(
        targetParentId: widget.articleId,
        targetTable: 'article_items',
        targetTitle: widget.title,
        onPasted: loadData,
      ),
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Items',
          style: MyTextStyle.headingMedium.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: MyColors.primaryColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.article_outlined),
              text: "Text",
            ),
            Tab(
              icon: Icon(Icons.photo_library_outlined),
              text: "Images",
            ),
            Tab(
              icon: Icon(Icons.play_circle_outline),
              text: "Videos",
            ),
          ],
        ),
        actions: [
          const AdminModeIndicator(),
          const AdminModeQuickToggle(),
          GlobalHomeButton(),
          // Search button
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.of(context).pushNamed(
              MyRoutes.searchScreen,
            ),
          ),
          if (selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => Share.multi(selectedItems),
            ),
          if (Supabase.instance.client.auth.currentUser != null &&
              getIt<AdminModeService>().isAdminMode)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: () => Navigator.of(context).pushNamed(
                  MyRoutes.addItemScreen,
                  arguments: {"article_id": widget.articleId}),
            ),
        ],
      ),
      body: BlocProvider(
        create: (context) => cubit,
        child: BlocBuilder<ItemsCubit, ItemsState>(
          builder: (context, state) {
            if (state is ErrorState) {
              return Center(child: Text(state.error));
            }
            if (state is LoadingState) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ListLoadedState) {
              final textItems =
                  state.items.where((i) => i.type == ItemType.text).toList();
              final imageItems =
                  state.items.where((i) => i.type == ItemType.image).toList();
              final videoItems =
                  state.items.where((i) => i.type == ItemType.video).toList();

              return Column(
                children: [
                  if (state.isOffline)
                    Container(
                      width: double.infinity,
                      color: Colors.orange.shade800,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Offline Mode - Using cached data',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildStaggeredTextItemsList(textItems, state.items),
                        _buildItemsList(imageItems, state.items),
                        _buildItemsList(videoItems, state.items),
                      ],
                    ),
                  ),
                ],
              );
            }
            return Container();
          },
        ),
      ),
    );
  }

  Widget _buildStaggeredTextItemsList(List<Item> items, List<Item> allItems) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No items found',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final itemIndex = allItems.indexOf(item);
        final prevItemId = itemIndex > 0 ? allItems[itemIndex - 1].id : null;
        final nextItemId =
            itemIndex < allItems.length - 1 ? allItems[itemIndex + 1].id : null;

        return StaggeredListItem(
          index: index,
          shouldAnimate: _shouldAnimate,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 12, left: 8, right: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005A32).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005A32),
                    ),
                  ),
                ),
                Expanded(
                  child:
                      _buildItemWidget(item, prevItemId, nextItemId, itemIndex),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemsList(List<Item> items, List<Item> allItems) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No items found',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final itemIndex = allItems.indexOf(item);
        final prevItemId = itemIndex > 0 ? allItems[itemIndex - 1].id : null;
        final nextItemId =
            itemIndex < allItems.length - 1 ? allItems[itemIndex + 1].id : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(top: 12, left: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      MyColors.primaryColor,
                      MyColors.primaryDark,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: MyColors.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: MyTextStyle.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child:
                    _buildItemWidget(item, prevItemId, nextItemId, itemIndex),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemWidget(
      Item item, String? prevItemId, String? nextItemId, int index) {
    switch (item.type) {
      case ItemType.text:
        return TextItem(
          item: item,
          isSelected: selectedItems.contains(item),
          onSelect: (article) => _toggleItemSelection(article),
          onItemUp: prevItemId != null ? (item) => _moveItemUp(item.id) : null,
          onItemDown:
              nextItemId != null ? (item) => _moveItemDown(item.id) : null,
          onDeleted: (_) => loadData(),
        );
      case ItemType.image:
        return ImageItem(
          item: item,
          isSelected: selectedItems.contains(item),
          onSelect: (article) => _toggleItemSelection(article),
          onItemUp: prevItemId != null ? (item) => _moveItemUp(item.id) : null,
          onItemDown:
              nextItemId != null ? (item) => _moveItemDown(item.id) : null,
          onDownloadPressed: (url) => Storage.download(url),
          onDeleted: (_) => loadData(),
        );
      case ItemType.video:
        return VideoItem(
          item: item,
          isSelected: selectedItems.contains(item),
          onSelect: (article) => _toggleItemSelection(article),
          onItemUp: prevItemId != null ? (item) => _moveItemUp(item.id) : null,
          onItemDown:
              nextItemId != null ? (item) => _moveItemDown(item.id) : null,
          onDeleted: (_) => loadData(),
        );
    }
  }

  void _toggleItemSelection(Item item) {
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
      } else {
        selectedItems.add(item);
      }
    });
  }

  /// Move item up using atomic operation
  Future<void> _moveItemUp(String itemId) async {
    if (widget.articleId == null) return;
    await cubit.moveItemUp(itemId, widget.articleId!);
  }

  /// Move item down using atomic operation
  Future<void> _moveItemDown(String itemId) async {
    if (widget.articleId == null) return;
    await cubit.moveItemDown(itemId, widget.articleId!);
  }
}

class StaggeredListItem extends StatefulWidget {
  final int index;
  final Widget child;
  final bool shouldAnimate;
  final Duration animationDuration;
  final Duration delayBetweenItems;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    required this.shouldAnimate,
    this.animationDuration = const Duration(milliseconds: 300),
    this.delayBetweenItems = const Duration(milliseconds: 100),
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    if (widget.shouldAnimate) {
      Future.delayed(
        widget.delayBetweenItems * widget.index,
        () {
          if (mounted) {
            _controller.forward();
          }
        },
      );
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(StaggeredListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldAnimate != oldWidget.shouldAnimate &&
        widget.shouldAnimate) {
      _controller.reset();
      Future.delayed(
        widget.delayBetweenItems * widget.index,
        () {
          if (mounted) {
            _controller.forward();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: _offsetAnimation.value * 50,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
