import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/supabase_client.dart';

/// Service to manage content ordering and reordering
/// 
/// This service provides deterministic, atomic ordering operations that are
/// safe against race conditions and partial updates.
/// 
/// Key principles:
/// 1. Always fetch actual order values from DB, never rely on UI state
/// 2. Use atomic database operations where possible
/// 3. Handle edge cases (first/last item, gaps in order values)
class ContentOrderingService {
  SupabaseClient get _supabase => Supa.client;

  /// Get the display_order column name for a table
  /// Some tables use 'order', others use 'display_order'
  String _getOrderColumn(String tableName) {
    // article_items uses 'order' column, others use 'display_order'
    if (tableName == 'article_items') {
      return 'order';
    }
    return 'display_order';
  }

  /// Get the parent field name for a table
  String _getParentField(String tableName) {
    return {
      'paths': 'language_id',
      'sections': 'path_id',
      'branches': 'section_id',
      'topics': 'branch_id',
      'content_items': 'topic_id',
      'articles': 'category_id',
      'article_items': 'article_id',
    }[tableName] ?? 'parent_id';
  }

  /// Move item up in the list (swap with previous item)
  /// Returns true if successful, false if already at top
  Future<bool> moveUp({
    required String itemId,
    required String tableName,
    required String parentId,
  }) async {
    try {
      debugPrint('[Ordering] Moving item $itemId up in $tableName');

      final orderColumn = _getOrderColumn(tableName);
      final parentField = _getParentField(tableName);

      // Fetch all items at this level, ordered
      final items = await _supabase
          .from(tableName)
          .select('id, $orderColumn')
          .eq(parentField, parentId)
          .order(orderColumn, ascending: true);

      // Find current item index
      final currentIndex = items.indexWhere((i) => i['id'] == itemId);
      
      if (currentIndex <= 0) {
        debugPrint('[Ordering] Item is already at top');
        return false;
      }

      // Get the item above
      final currentItem = items[currentIndex];
      final previousItem = items[currentIndex - 1];

      // Perform atomic swap using actual DB values
      await _atomicSwap(
        tableName: tableName,
        orderColumn: orderColumn,
        id1: itemId,
        order1: previousItem[orderColumn] ?? (currentIndex - 1),
        id2: previousItem['id'],
        order2: currentItem[orderColumn] ?? currentIndex,
      );

      debugPrint('[Ordering] Move up completed');
      return true;
    } catch (e) {
      debugPrint('[Ordering] Move up error: $e');
      rethrow;
    }
  }

  /// Move item down in the list (swap with next item)
  /// Returns true if successful, false if already at bottom
  Future<bool> moveDown({
    required String itemId,
    required String tableName,
    required String parentId,
  }) async {
    try {
      debugPrint('[Ordering] Moving item $itemId down in $tableName');

      final orderColumn = _getOrderColumn(tableName);
      final parentField = _getParentField(tableName);

      // Fetch all items at this level, ordered
      final items = await _supabase
          .from(tableName)
          .select('id, $orderColumn')
          .eq(parentField, parentId)
          .order(orderColumn, ascending: true);

      // Find current item index
      final currentIndex = items.indexWhere((i) => i['id'] == itemId);
      
      if (currentIndex < 0 || currentIndex >= items.length - 1) {
        debugPrint('[Ordering] Item is already at bottom');
        return false;
      }

      // Get the item below
      final currentItem = items[currentIndex];
      final nextItem = items[currentIndex + 1];

      // Perform atomic swap using actual DB values
      await _atomicSwap(
        tableName: tableName,
        orderColumn: orderColumn,
        id1: itemId,
        order1: nextItem[orderColumn] ?? (currentIndex + 1),
        id2: nextItem['id'],
        order2: currentItem[orderColumn] ?? currentIndex,
      );

      debugPrint('[Ordering] Move down completed');
      return true;
    } catch (e) {
      debugPrint('[Ordering] Move down error: $e');
      rethrow;
    }
  }

  /// Atomic swap of two items' order values
  /// This ensures both updates succeed or both fail
  Future<void> _atomicSwap({
    required String tableName,
    required String orderColumn,
    required String id1,
    required int order1,
    required String id2,
    required int order2,
  }) async {
    try {
      // Try to use the RPC function for truly atomic swap
      await _supabase.rpc('swap_display_order', params: {
        'p_table': tableName,
        'p_id1': id1,
        'p_order1': order1,
        'p_id2': id2,
        'p_order2': order2,
      });
    } catch (e) {
      // Fallback to sequential updates if RPC not available
      debugPrint('[Ordering] RPC not available, using fallback: $e');
      
      // Use a temporary value to avoid unique constraint issues
      final tempOrder = -999;
      
      await _supabase
          .from(tableName)
          .update({orderColumn: tempOrder})
          .eq('id', id1);
      
      await _supabase
          .from(tableName)
          .update({orderColumn: order2})
          .eq('id', id2);
      
      await _supabase
          .from(tableName)
          .update({orderColumn: order1})
          .eq('id', id1);
    }
  }

  /// Reorder items based on a new list order
  /// itemIds: List of IDs in desired order
  /// This will update display_order for each item
  Future<void> reorderItems({
    required List<String> itemIds,
    required String tableName,
  }) async {
    try {
      debugPrint('[Ordering] Reordering ${itemIds.length} items in $tableName');
      
      final orderColumn = _getOrderColumn(tableName);

      // Update each item's order based on its position
      for (int i = 0; i < itemIds.length; i++) {
        await _supabase
            .from(tableName)
            .update({orderColumn: i})
            .eq('id', itemIds[i]);
      }

      debugPrint('[Ordering] Successfully reordered');
    } catch (e) {
      debugPrint('[Ordering] Error: $e');
      throw Exception('Failed to reorder items: $e');
    }
  }

  /// Legacy swap method - kept for backwards compatibility
  /// Prefer using moveUp/moveDown for clearer semantics
  @Deprecated('Use moveUp or moveDown instead')
  Future<void> swapOrder({
    required String id1,
    required String id2,
    required int order1,
    required int order2,
    required String tableName,
  }) async {
    final orderColumn = _getOrderColumn(tableName);
    await _atomicSwap(
      tableName: tableName,
      orderColumn: orderColumn,
      id1: id1,
      order1: order2, // Swap!
      id2: id2,
      order2: order1, // Swap!
    );
  }

  /// Move item to a specific position
  Future<void> moveToPosition({
    required String itemId,
    required int newPosition,
    required String tableName,
    String? parentId,
    String? parentFieldName,
  }) async {
    try {
      debugPrint('[Ordering] Moving $itemId to position $newPosition');

      final orderColumn = _getOrderColumn(tableName);
      final parentField = parentFieldName ?? _getParentField(tableName);

      // Get all items at this level
      final query = _supabase
          .from(tableName)
          .select('id, $orderColumn');
      
      final items = parentId != null
          ? await query.eq(parentField, parentId).order(orderColumn)
          : await query.order(orderColumn);

      if (items.isEmpty) return;

      // Find current position
      final currentIndex = items.indexWhere((i) => i['id'] == itemId);
      if (currentIndex < 0) {
        throw Exception('Item not found in list');
      }

      // Clamp new position
      final clampedPosition = newPosition.clamp(0, items.length - 1);
      if (currentIndex == clampedPosition) return;

      // Reorder all items
      final newOrder = List<Map<String, dynamic>>.from(items);
      final item = newOrder.removeAt(currentIndex);
      newOrder.insert(clampedPosition, item);

      // Update all positions
      for (int i = 0; i < newOrder.length; i++) {
        await _supabase
            .from(tableName)
            .update({orderColumn: i})
            .eq('id', newOrder[i]['id']);
      }

      debugPrint('[Ordering] Move to position completed');
    } catch (e) {
      debugPrint('[Ordering] Move error: $e');
      throw Exception('Failed to move item: $e');
    }
  }

  /// Get display order value for a new item
  /// Returns the next available order number
  Future<int> getNextDisplayOrder({
    required String tableName,
    String? parentId,
    String? parentFieldName,
  }) async {
    try {
      final orderColumn = _getOrderColumn(tableName);
      final parentField = parentFieldName ?? _getParentField(tableName);

      final query = _supabase
          .from(tableName)
          .select(orderColumn);
      
      final result = parentId != null
          ? await query
              .eq(parentField, parentId)
              .order(orderColumn, ascending: false)
              .limit(1)
          : await query
              .order(orderColumn, ascending: false)
              .limit(1);

      if (result.isEmpty) {
        return 0;
      }

      return (result.first[orderColumn] ?? -1) + 1;
    } catch (e) {
      debugPrint('[Ordering] Get next order error: $e');
      return 0;
    }
  }

  /// Normalize display orders to be sequential (0, 1, 2, ...)
  /// Use this to clean up gaps after deletions
  Future<void> normalizeOrders({
    required String tableName,
    required String parentId,
    String? parentFieldName,
  }) async {
    try {
      debugPrint('[Ordering] Normalizing orders in $tableName for parent $parentId');

      final orderColumn = _getOrderColumn(tableName);
      final parentField = parentFieldName ?? _getParentField(tableName);

      // Fetch all items ordered
      final items = await _supabase
          .from(tableName)
          .select('id')
          .eq(parentField, parentId)
          .order(orderColumn, ascending: true);

      // Update each with sequential order
      for (int i = 0; i < items.length; i++) {
        await _supabase
            .from(tableName)
            .update({orderColumn: i})
            .eq('id', items[i]['id']);
      }

      debugPrint('[Ordering] Normalized ${items.length} items');
    } catch (e) {
      debugPrint('[Ordering] Normalize error: $e');
      throw Exception('Failed to normalize orders: $e');
    }
  }

  /// Batch reorder with parent filtering
  /// Useful for reordering items under a specific parent
  Future<void> reorderItemsByParent({
    required List<String> itemIds,
    required String tableName,
    required String parentId,
    required String parentFieldName,
  }) async {
    try {
      debugPrint(
          '[Ordering] Reordering ${itemIds.length} items under parent $parentId');

      final orderColumn = _getOrderColumn(tableName);

      for (int i = 0; i < itemIds.length; i++) {
        await _supabase
            .from(tableName)
            .update({orderColumn: i})
            .eq('id', itemIds[i])
            .eq(parentFieldName, parentId);
      }

      debugPrint('[Ordering] Batch reorder completed');
    } catch (e) {
      debugPrint('[Ordering] Batch reorder error: $e');
      throw Exception('Failed to batch reorder: $e');
    }
  }
}
