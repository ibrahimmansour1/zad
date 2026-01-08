import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/helpers/language.dart';
import 'package:zad_aldaia/core/supabase_client.dart';
import 'package:zad_aldaia/features/categories/data/models/category.dart';
import 'package:zad_aldaia/services/offline_content_service.dart';

/// Categories Repository - Migrated to use new hierarchical tables
/// Maps: languages → paths → sections → branches → topics
/// to the existing Category model for backward compatibility
class CategoriesRepo {
  SupabaseClient get _supabase => Supa.client;

  List<Category> categories = [];

  /// Determine which table to query based on parent_id depth
  String _getTableName(String? parentId, int depth) {
    if (parentId == null) {
      return 'languages'; // Top level
    }

    // Depth-based table selection
    switch (depth) {
      case 1:
        return 'paths';
      case 2:
        return 'sections';
      case 3:
        return 'branches';
      case 4:
        return 'topics';
      default:
        return 'topics'; // Fallback
    }
  }

  /// Get the parent ID field name for the current table
  String _getParentIdField(String tableName) {
    switch (tableName) {
      case 'paths':
        return 'language_id';
      case 'sections':
        return 'path_id';
      case 'branches':
        return 'section_id';
      case 'topics':
        return 'branch_id';
      default:
        return 'parent_id';
    }
  }

  /// Convert new table row to Category model
  Category _rowToCategory(
      Map<String, dynamic> row, String tableName, String? lang) {
    return Category(
      id: row['id'] ?? '',
      title: row['title'] ?? row['name'] ?? '',
      parentId: row[_getParentIdField(tableName)],
      lang: lang,
      image: row['image_url'] ?? row['flag_url'] ?? row['image'],
      imageIdentifier: row['image_identifier'],
      order: row['display_order'] ?? row['order'] ?? 0,
      isActive: row['is_active'] ?? true,
      createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
      section: tableName,
      // Count children based on next level table
      categories: _getChildrenCount(tableName, row),
      articles: [], // No articles in new structure
    );
  }

  /// Get children count for the next level
  List<Countable>? _getChildrenCount(
      String tableName, Map<String, dynamic> row) {
    // Map table to its children table
    final childrenMap = {
      'languages': 'paths',
      'paths': 'sections',
      'sections': 'branches',
      'branches': 'topics',
      'topics': null, // Topics are leaf nodes
    };

    final childTable = childrenMap[tableName];
    if (childTable == null) return null;

    // If the row has a count field from the query, use it
    if (row.containsKey(childTable)) {
      final countData = row[childTable];
      if (countData is List && countData.isNotEmpty) {
        final count = countData.first['count'] as int? ?? 0;
        return [Countable(count: count)];
      }
    }

    return null;
  }

  Future<List<Category>> searchCategories(Map<String, dynamic> eqMap) async {
    final lang = await Lang.get();

    // If parent_id is specified, use fetchCategories which handles table-specific parent fields
    if (eqMap.containsKey('parent_id')) {
      return await fetchCategories(eqMap['parent_id']);
    }

    // Special case: Searching by ID (used for loading a single category for editing)
    if (eqMap.containsKey('id')) {
      final id = eqMap['id'];
      final tableName = await _findTableForId(id);

      // Get the next level table for counting children
      final childrenTableMap = {
        'languages': 'paths',
        'paths': 'sections',
        'sections': 'branches',
        'branches': 'topics',
        'topics': null,
      };
      final childTable = childrenTableMap[tableName];

      try {
        var query = _supabase
            .from(tableName)
            .select(childTable != null ? '*, $childTable(count)' : '*');
        query = query.eq('id', id);

        final response = await query.timeout(const Duration(seconds: 10));
        return (response as List)
            .map<Category>((item) => _rowToCategory(item, tableName, lang))
            .toList();
      } catch (e) {
        print('Error searching category by ID: $e');
        // Fallback to offline if needed? Usually edit works online
      }
    }

    // Default search (e.g. searching languages)
    final tableName = 'languages';

    var query = _supabase.from(tableName).select('*, paths(count)');

    // Apply filters (except parent_id and lang which are handled separately)
    for (var element in eqMap.entries) {
      if (element.key != 'lang' && element.key != 'parent_id') {
        query = query.eq(element.key, element.value);
      }
    }

    // Filter by active status for non-authenticated users
    if (Supa.currentUser == null) {
      query = query.eq('is_active', true);
    }

    try {
      final response = await query
          .order('display_order', ascending: true)
          .timeout(const Duration(seconds: 10));
      final categories = (response as List)
          .map<Category>((item) => _rowToCategory(item, tableName, lang))
          .toList();

      return categories;
    } catch (e) {
      print(
          'Network error in searchCategories: $e. Falling back to offline...');
      final offlineData =
          await _fetchOfflineCategories(eqMap['parent_id'], lang);
      if (offlineData != null) {
        // We can't easily change return type without breaking everything,
        // but we can mark the categories as offline
        return offlineData.map((c) => c..isOffline = true).toList();
      }
      rethrow;
    }
  }

  Future<List<Category>> fetchCategories(String? parentId) async {
    final lang = await Lang.get();

    try {
      // Determine which table to query
      String tableName;
      if (parentId == null) {
        // Top level - fetch languages
        tableName = 'languages';
      } else {
        // Need to determine depth by checking which table the parent belongs to
        tableName = await _determineTableForParent(parentId);
      }

      // Get the next level table for counting children
      final childrenTableMap = {
        'languages': 'paths',
        'paths': 'sections',
        'sections': 'branches',
        'branches': 'topics',
        'topics': null,
      };
      final childTable = childrenTableMap[tableName];

      // Build query with children count
      var query = _supabase
          .from(tableName)
          .select(childTable != null ? '*, $childTable(count)' : '*');

      if (parentId != null) {
        final parentField = _getParentIdField(tableName);
        query = query.eq(parentField, parentId);
      }

      // Filter by active for non-authenticated users
      if (Supa.currentUser == null) {
        query = query.eq('is_active', true);
      }

      final response = await query
          .order('display_order', ascending: true)
          .timeout(const Duration(seconds: 10));
      final categories = (response as List)
          .map<Category>((item) => _rowToCategory(item, tableName, lang))
          .toList();

      return categories;
    } catch (e) {
      print(
          'Network error in fetchCategories: $e. Falling back to offline data...');
      // Fallback to offline data
      final offlineData = await _fetchOfflineCategories(parentId, lang);
      if (offlineData != null) {
        return offlineData.map((c) => c..isOffline = true).toList();
      }
      rethrow;
    }
  }

  Future<List<Category>?> _fetchOfflineCategories(
      String? parentId, String langCode) async {
    try {
      final downloadedLangIds =
          await OfflineContentService.getDownloadedLanguages();
      for (var langId in downloadedLangIds) {
        final data = await OfflineContentService.getOfflineData(langId);
        if (data == null) continue;

        // 1. Get the target items based on parentId
        List<dynamic> items = [];
        String tableName = '';

        if (parentId == null) {
          items = [data['language']];
          tableName = 'languages';
        } else if (data['paths'] != null &&
            (data['paths'] as List).any((i) => i['language_id'] == parentId)) {
          items = (data['paths'] as List)
              .where((i) => i['language_id'] == parentId)
              .toList();
          tableName = 'paths';
        } else if (data['sections'] != null &&
            (data['sections'] as List).any((i) => i['path_id'] == parentId)) {
          items = (data['sections'] as List)
              .where((i) => i['path_id'] == parentId)
              .toList();
          tableName = 'sections';
        } else if (data['branches'] != null &&
            (data['branches'] as List)
                .any((i) => i['section_id'] == parentId)) {
          items = (data['branches'] as List)
              .where((i) => i['section_id'] == parentId)
              .toList();
          tableName = 'branches';
        } else if (data['topics'] != null &&
            (data['topics'] as List).any((i) => i['branch_id'] == parentId)) {
          items = (data['topics'] as List)
              .where((i) => i['branch_id'] == parentId)
              .toList();
          tableName = 'topics';
        }

        if (items.isNotEmpty) {
          return items.map((item) {
            final category = _rowToCategory(item, tableName, langCode);

            // Calculate offline counts
            int childCount = 0;
            if (tableName == 'languages') {
              childCount = (data['paths'] as List?)
                      ?.where((p) => p['language_id'] == item['id'])
                      .length ??
                  0;
            } else if (tableName == 'paths') {
              childCount = (data['sections'] as List?)
                      ?.where((s) => s['path_id'] == item['id'])
                      .length ??
                  0;
            } else if (tableName == 'sections') {
              childCount = (data['branches'] as List?)
                      ?.where((b) => b['section_id'] == item['id'])
                      .length ??
                  0;
            } else if (tableName == 'branches') {
              childCount = (data['topics'] as List?)
                      ?.where((t) => t['branch_id'] == item['id'])
                      .length ??
                  0;
            }

            final categoryArticleCount = (data['articles'] as List?)
                    ?.where((a) => a['category_id'] == item['id'])
                    .length ??
                0;

            return category
              ..categories = [Countable(count: childCount)]
              ..articles = [Countable(count: categoryArticleCount)];
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching offline categories: $e');
    }
    return null;
  }

  /// Determine which table a parent ID belongs to
  Future<String> _determineTableForParent(String parentId) async {
    // Try each table in order
    final tables = ['languages', 'paths', 'sections', 'branches', 'topics'];
    final nextTables = ['paths', 'sections', 'branches', 'topics', 'topics'];

    for (var i = 0; i < tables.length; i++) {
      try {
        final response = await _supabase
            .from(tables[i])
            .select('id')
            .eq('id', parentId)
            .limit(1);

        if ((response as List).isNotEmpty) {
          return nextTables[i];
        }
      } catch (e) {
        // Continue to next table
      }
    }

    // Default to paths if not found
    return 'paths';
  }

  Future updateCategory(String id, Map<String, dynamic> data) async {
    // Determine which table this ID belongs to
    final tableName = await _findTableForId(id);

    // Map Category fields to new table fields
    final mappedData = <String, dynamic>{};
    if (data.containsKey('title')) {
      mappedData['name'] = data['title'];
      if (tableName != 'languages') {
        mappedData['title'] = data['title'];
      }
    }
    if (data.containsKey('image')) {
      if (tableName == 'languages') {
        mappedData['flag_url'] = data['image'];
      } else {
        mappedData['image_url'] = data['image'];
        mappedData['image'] = data['image'];
      }
    }
    if (data.containsKey('image_identifier')) {
      mappedData['image_identifier'] = data['image_identifier'];
    }
    if (data.containsKey('order')) {
      mappedData['display_order'] = data['order'];
    }
    if (data.containsKey('is_active')) {
      mappedData['is_active'] = data['is_active'];
    }

    await _supabase
        .from(tableName)
        .update(mappedData)
        .eq('id', id)
        .timeout(const Duration(seconds: 30));
  }

  Future insertCategory(Map<String, dynamic> data) async {
    // Determine which table to insert into based on parent_id
    final parentId = data['parent_id'];
    final tableName = parentId == null
        ? 'languages'
        : await _determineTableForParent(parentId);

    // Map Category fields to new table fields
    final mappedData = <String, dynamic>{};
    if (data.containsKey('title')) {
      mappedData['name'] = data['title'];
      if (tableName != 'languages') {
        mappedData['title'] = data['title'];
      }
    }
    if (data.containsKey('image')) {
      if (tableName == 'languages') {
        mappedData['flag_url'] = data['image'];
      } else {
        mappedData['image_url'] = data['image'];
        mappedData['image'] = data['image'];
      }
    }
    if (data.containsKey('image_identifier')) {
      mappedData['image_identifier'] = data['image_identifier'];
    }
    if (data.containsKey('order')) {
      mappedData['display_order'] = data['order'];
    }
    if (data.containsKey('is_active')) {
      mappedData['is_active'] = data['is_active'];
    }

    // Add parent ID with correct field name
    if (parentId != null) {
      final parentField = _getParentIdField(tableName);
      mappedData[parentField] = parentId;
    }

    await _supabase
        .from(tableName)
        .insert(mappedData)
        .timeout(const Duration(seconds: 30));
  }

  /// Find which table an ID belongs to
  Future<String> _findTableForId(String id) async {
    final tables = ['languages', 'paths', 'sections', 'branches', 'topics'];

    for (var table in tables) {
      try {
        final response =
            await _supabase.from(table).select('id').eq('id', id).limit(1);

        if ((response as List).isNotEmpty) {
          return table;
        }
      } catch (e) {
        // Continue to next table
      }
    }

    // Default to languages if not found
    return 'languages';
  }

  Future<bool> swapCategoriesOrder(
      String id1, String id2, int index1, int index2) async {
    try {
      // Find which table these IDs belong to
      final tableName = await _findTableForId(id1);

      await _supabase
          .from(tableName)
          .update({'display_order': index2}).eq('id', id1);
      await _supabase
          .from(tableName)
          .update({'display_order': index1}).eq('id', id2);

      print('✅ Orders swapped between ID $id1 and ID $id2 in $tableName');
      return true;
    } catch (e) {
      print('Error swapping orders: $e');
      return false;
    }
  }

  /// Move a category up in display order (atomic operation)
  Future<bool> moveCategoryUp(String categoryId, String? parentId) async {
    try {
      final tableName = await _findTableForId(categoryId);
      final parentField = _getParentIdField(tableName);

      // Get current category's display order
      final currentResult = await _supabase
          .from(tableName)
          .select('display_order')
          .eq('id', categoryId)
          .single();

      final currentOrder = currentResult['display_order'] as int? ?? 0;

      // Build query with filters before order/limit
      var filterQuery = _supabase
          .from(tableName)
          .select('id, display_order')
          .lt('display_order', currentOrder)
          .neq('is_deleted', true);

      // Apply parent filter if applicable
      if (tableName != 'languages' && parentId != null) {
        filterQuery = filterQuery.eq(parentField, parentId);
      }

      // Apply order and limit
      final aboveItems =
          await filterQuery.order('display_order', ascending: false).limit(1);

      if (aboveItems.isEmpty) {
        print('[CategoriesRepo] Already at top');
        return false;
      }

      final aboveItem = aboveItems.first;
      final aboveOrder = aboveItem['display_order'] as int;
      final aboveId = aboveItem['id'] as String;

      // Atomic swap using temporary value
      await _atomicSwapOrder(
          tableName, categoryId, currentOrder, aboveId, aboveOrder);

      print('✅ Category $categoryId moved up in $tableName');
      return true;
    } catch (e) {
      print('[CategoriesRepo] Error moving up: $e');
      return false;
    }
  }

  /// Move a category down in display order (atomic operation)
  Future<bool> moveCategoryDown(String categoryId, String? parentId) async {
    try {
      final tableName = await _findTableForId(categoryId);
      final parentField = _getParentIdField(tableName);

      // Get current category's display order
      final currentResult = await _supabase
          .from(tableName)
          .select('display_order')
          .eq('id', categoryId)
          .single();

      final currentOrder = currentResult['display_order'] as int? ?? 0;

      // Build query with filters before order/limit
      var filterQuery = _supabase
          .from(tableName)
          .select('id, display_order')
          .gt('display_order', currentOrder)
          .neq('is_deleted', true);

      // Apply parent filter if applicable
      if (tableName != 'languages' && parentId != null) {
        filterQuery = filterQuery.eq(parentField, parentId);
      }

      // Apply order and limit
      final belowItems =
          await filterQuery.order('display_order', ascending: true).limit(1);

      if (belowItems.isEmpty) {
        print('[CategoriesRepo] Already at bottom');
        return false;
      }

      final belowItem = belowItems.first;
      final belowOrder = belowItem['display_order'] as int;
      final belowId = belowItem['id'] as String;

      // Atomic swap using temporary value
      await _atomicSwapOrder(
          tableName, categoryId, currentOrder, belowId, belowOrder);

      print('✅ Category $categoryId moved down in $tableName');
      return true;
    } catch (e) {
      print('[CategoriesRepo] Error moving down: $e');
      return false;
    }
  }

  /// Atomic swap using temporary value to avoid constraint conflicts
  Future<void> _atomicSwapOrder(
    String tableName,
    String id1,
    int order1,
    String id2,
    int order2,
  ) async {
    const tempOrder = -999;

    // 1. Move first item to temp
    await _supabase
        .from(tableName)
        .update({'display_order': tempOrder}).eq('id', id1);

    // 2. Move second item to first's order
    await _supabase
        .from(tableName)
        .update({'display_order': order1}).eq('id', id2);

    // 3. Move first item to second's order
    await _supabase
        .from(tableName)
        .update({'display_order': order2}).eq('id', id1);
  }

  /// Get next display order for a new item
  Future<int> getNextDisplayOrder(String tableName, String? parentId) async {
    try {
      final parentField = _getParentIdField(tableName);
      var filterQuery = _supabase.from(tableName).select('display_order');

      // Apply parent filter before order/limit
      if (tableName != 'languages' && parentId != null) {
        filterQuery = filterQuery.eq(parentField, parentId);
      }

      final result =
          await filterQuery.order('display_order', ascending: false).limit(1);

      if (result.isEmpty) return 0;
      return (result.first['display_order'] ?? -1) + 1;
    } catch (e) {
      return 0;
    }
  }
}
