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

      // Apply like filters with OR logic for searching across multiple fields
      if (likeMap.isNotEmpty) {
        final searchQuery = likeMap.values.first; // Get the search term
        // Search in title, content, and note fields
        query = query.or(
            'title.ilike.%$searchQuery%,content.ilike.%$searchQuery%,note.ilike.%$searchQuery%');
      }

      final response = await query
          .order('order', ascending: true)
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

  Future<bool> swapItemsOrder(
      String id1, String id2, int index1, int index2) async {
    try {
      await _supabase
          .from('article_items')
          .update({'order': index2}).eq('id', id1);
      await _supabase
          .from('article_items')
          .update({'order': index1}).eq('id', id2);

      print('✅ Orders swapped between ID $id1 and ID $id2');
      return true;
    } catch (e) {
      print('Error swapping article item orders: $e');
      return false;
    }
  }
}
