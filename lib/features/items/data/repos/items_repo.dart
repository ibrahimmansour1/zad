import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/supabase_client.dart';
import 'package:zad_aldaia/features/items/data/models/item.dart';
import 'package:zad_aldaia/services/offline_content_service.dart';

class ItemsRepo {
  SupabaseClient get _supabase => Supa.client;

  List<Item> items = [];

  Future<List<Item>> searchItems(
      Map<String, dynamic> eqMap, Map<String, dynamic> likeMap) async {
    try {
      var query = _supabase.from('article_items').select('*');

      // Apply equality filters
      for (var element in eqMap.entries) {
        query = query.eq(element.key, element.value);
      }

      // Exclude soft-deleted items
      query = query.neq('is_deleted', true);

      // Apply like filters with OR logic for searching across multiple fields
      if (likeMap.isNotEmpty) {
        final searchQuery = likeMap.values.first; // Get the search term
        // Search in title, content, and note fields
        query = query.or(
            'title.ilike.%$searchQuery%,content.ilike.%$searchQuery%,note.ilike.%$searchQuery%');
      }

      final response = await query
          .order('display_order', ascending: true)
          .timeout(const Duration(seconds: 10));
      final items =
          (response as List).map<Item>((item) => Item.fromJson(item)).toList();
      return items;
    } catch (e) {
      print('Network error in searchItems: $e. Falling back to offline...');
      final offlineData = await _fetchOfflineItems(eqMap, likeMap);
      if (offlineData != null) {
        return offlineData.map((i) => i..isOffline = true).toList();
      }
      rethrow;
    }
  }

  Future<List<Item>?> _fetchOfflineItems(
      Map<String, dynamic> eqMap, Map<String, dynamic> likeMap) async {
    try {
      final articleId = eqMap['article_id'];
      final searchQuery = likeMap.isNotEmpty
          ? likeMap.values.first.toString().toLowerCase()
          : null;

      final downloadedLangIds =
          await OfflineContentService.getDownloadedLanguages();
      List<Item> allMatchingItems = [];

      for (var langId in downloadedLangIds) {
        final data = await OfflineContentService.getOfflineData(langId);
        if (data == null || data['article_items'] == null) continue;

        final offlineItems = data['article_items'] as List;

        var filtered = offlineItems;

        // Filter by article_id if provided
        if (articleId != null) {
          filtered =
              filtered.where((i) => i['article_id'] == articleId).toList();
        }

        // Filter by search query if provided
        if (searchQuery != null) {
          filtered = filtered.where((i) {
            final title = (i['title'] ?? '').toString().toLowerCase();
            final content = (i['content'] ?? '').toString().toLowerCase();
            final note = (i['note'] ?? '').toString().toLowerCase();
            return title.contains(searchQuery) ||
                content.contains(searchQuery) ||
                note.contains(searchQuery);
          }).toList();
        }

        allMatchingItems.addAll(filtered.map((item) => Item.fromJson(item)));
      }

      if (allMatchingItems.isNotEmpty) {
        allMatchingItems.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
        return allMatchingItems;
      }
    } catch (e) {
      print('Error fetching offline items: $e');
    }
    return null;
  }

  Future updateItem(String id, Map<String, dynamic> data) async {
    await _supabase
        .from('article_items')
        .update(data)
        .eq('id', id)
        .timeout(Duration(seconds: 30));
  }

  Future insertItem(Map<String, dynamic> data) async {
    await _supabase
        .from('article_items')
        .insert(data)
        .timeout(Duration(seconds: 30));
  }

  /// Move item up in the list (swap with previous item)
  /// Returns true if successful, false if already at top
  Future<bool> moveItemUp(String itemId, String articleId) async {
    try {
      // Fetch all items for this article, ordered
      final items = await _supabase
          .from('article_items')
          .select('id, display_order')
          .eq('article_id', articleId)
          .neq('is_deleted', true)
          .order('display_order', ascending: true);

      final currentIndex = items.indexWhere((i) => i['id'] == itemId);

      if (currentIndex <= 0) {
        print('Item is already at top');
        return false;
      }

      final currentItem = items[currentIndex];
      final previousItem = items[currentIndex - 1];

      // Swap order values
      await _atomicSwapOrder(
        id1: itemId,
        order1: previousItem['display_order'] ?? (currentIndex - 1),
        id2: previousItem['id'],
        order2: currentItem['display_order'] ?? currentIndex,
      );

      print('✅ Item moved up successfully');
      return true;
    } catch (e) {
      print('Error moving item up: $e');
      return false;
    }
  }

  /// Move item down in the list (swap with next item)
  /// Returns true if successful, false if already at bottom
  Future<bool> moveItemDown(String itemId, String articleId) async {
    try {
      // Fetch all items for this article, ordered
      final items = await _supabase
          .from('article_items')
          .select('id, display_order')
          .eq('article_id', articleId)
          .neq('is_deleted', true)
          .order('display_order', ascending: true);

      final currentIndex = items.indexWhere((i) => i['id'] == itemId);

      if (currentIndex < 0 || currentIndex >= items.length - 1) {
        print('Item is already at bottom');
        return false;
      }

      final currentItem = items[currentIndex];
      final nextItem = items[currentIndex + 1];

      // Swap order values
      await _atomicSwapOrder(
        id1: itemId,
        order1: nextItem['display_order'] ?? (currentIndex + 1),
        id2: nextItem['id'],
        order2: currentItem['display_order'] ?? currentIndex,
      );

      print('✅ Item moved down successfully');
      return true;
    } catch (e) {
      print('Error moving item down: $e');
      return false;
    }
  }

  /// Atomic swap of two items' order values
  Future<void> _atomicSwapOrder({
    required String id1,
    required int order1,
    required String id2,
    required int order2,
  }) async {
    // Use a temporary value to avoid any potential conflicts
    const tempOrder = -999;

    // Step 1: Move first item to temp
    await _supabase
        .from('article_items')
        .update({'display_order': tempOrder}).eq('id', id1);

    // Step 2: Move second item to first's position
    await _supabase
        .from('article_items')
        .update({'display_order': order2}).eq('id', id2);

    // Step 3: Move first item to second's position
    await _supabase
        .from('article_items')
        .update({'display_order': order1}).eq('id', id1);
  }

  /// Legacy swap method - kept for backwards compatibility
  /// @deprecated Use moveItemUp or moveItemDown instead
  Future<bool> swapItemsOrder(
      String id1, String id2, int index1, int index2) async {
    try {
      // Fetch actual order values from database
      final item1 = await _supabase
          .from('article_items')
          .select('display_order')
          .eq('id', id1)
          .single();

      final item2 = await _supabase
          .from('article_items')
          .select('display_order')
          .eq('id', id2)
          .single();

      final order1 = item1['display_order'] ?? index1;
      final order2 = item2['display_order'] ?? index2;

      await _atomicSwapOrder(
        id1: id1,
        order1: order2, // Swap!
        id2: id2,
        order2: order1, // Swap!
      );

      print('✅ Orders swapped between ID $id1 and ID $id2');
      return true;
    } catch (e) {
      print('Error swapping article item orders: $e');
      return false;
    }
  }

  /// Get the next order value for a new item
  Future<int> getNextOrder(String articleId) async {
    try {
      final result = await _supabase
          .from('article_items')
          .select('display_order')
          .eq('article_id', articleId)
          .neq('is_deleted', true)
          .order('display_order', ascending: false)
          .limit(1);

      if (result.isEmpty) {
        return 0;
      }

      return (result.first['display_order'] ?? -1) + 1;
    } catch (e) {
      print('Error getting next order: $e');
      return 0;
    }
  }
}
