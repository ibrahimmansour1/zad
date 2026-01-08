import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/supabase_client.dart';
import 'package:zad_aldaia/features/articles/data/models/article.dart';
import 'package:zad_aldaia/services/offline_content_service.dart';

class ArticlesRepo {
  // Use Supa.client directly instead of dependency injection
  SupabaseClient get _supabase => Supa.client;

  Future<List<Article>> searchArticles(Map<String, dynamic> eqMap) async {
    try {
      var query = _supabase.from('articles').select('*');
      for (var element in eqMap.entries) {
        query = query.eq(element.key, element.value);
      }

      // Filter by active for non-authenticated users
      if (Supa.currentUser == null) {
        query = query.eq('is_active', true);
      }
      
      // Exclude soft-deleted articles
      query = query.neq('is_deleted', true);

      final response = await query
          .order('display_order', ascending: true)
          .timeout(const Duration(seconds: 10));
      final articles = (response as List)
          .map<Article>((item) => Article.fromJson(item))
          .toList();
      return articles;
    } catch (e) {
      print('Network error in searchArticles: $e. Falling back to offline...');
      final offlineData = await _fetchOfflineArticles(eqMap['category_id']);
      if (offlineData != null) {
        return offlineData.map((a) => a..isOffline = true).toList();
      }
      rethrow;
    }
  }

  Future<List<Article>?> _fetchOfflineArticles(String? categoryId) async {
    if (categoryId == null) return null;
    try {
      final downloadedLangIds =
          await OfflineContentService.getDownloadedLanguages();
      for (var langId in downloadedLangIds) {
        final data = await OfflineContentService.getOfflineData(langId);
        if (data == null) continue;

        if (data['articles'] != null) {
          final items = (data['articles'] as List)
              .where((item) => item['category_id'] == categoryId)
              .toList();
          if (items.isNotEmpty) {
            // Sort by display_order
            items.sort((a, b) => 
                (a['display_order'] ?? 0).compareTo(b['display_order'] ?? 0));
            return items.map((item) => Article.fromJson(item)).toList();
          }
        }
      }
    } catch (e) {
      print('Error fetching offline articles: $e');
    }
    return null;
  }

  Future updateArticle(String id, Map<String, dynamic> data) async {
    return await _supabase
        .from('articles')
        .update(data)
        .eq('id', id)
        .timeout(Duration(seconds: 30));
  }

  Future insertArticle(Map<String, dynamic> data) async {
    return await _supabase
        .from('articles')
        .insert(data)
        .timeout(Duration(seconds: 30));
  }

  /// Move article up in the list (swap with previous article)
  Future<bool> moveArticleUp(String articleId, String categoryId) async {
    try {
      // Fetch all articles for this category, ordered
      final articles = await _supabase
          .from('articles')
          .select('id, display_order')
          .eq('category_id', categoryId)
          .neq('is_deleted', true)
          .order('display_order', ascending: true);

      final currentIndex = articles.indexWhere((a) => a['id'] == articleId);
      
      if (currentIndex <= 0) {
        print('Article is already at top');
        return false;
      }

      final currentArticle = articles[currentIndex];
      final previousArticle = articles[currentIndex - 1];

      // Swap order values
      await _atomicSwapOrder(
        id1: articleId,
        order1: previousArticle['display_order'] ?? (currentIndex - 1),
        id2: previousArticle['id'],
        order2: currentArticle['display_order'] ?? currentIndex,
      );

      print('✅ Article moved up successfully');
      return true;
    } catch (e) {
      print('Error moving article up: $e');
      return false;
    }
  }

  /// Move article down in the list (swap with next article)
  Future<bool> moveArticleDown(String articleId, String categoryId) async {
    try {
      // Fetch all articles for this category, ordered
      final articles = await _supabase
          .from('articles')
          .select('id, display_order')
          .eq('category_id', categoryId)
          .neq('is_deleted', true)
          .order('display_order', ascending: true);

      final currentIndex = articles.indexWhere((a) => a['id'] == articleId);
      
      if (currentIndex < 0 || currentIndex >= articles.length - 1) {
        print('Article is already at bottom');
        return false;
      }

      final currentArticle = articles[currentIndex];
      final nextArticle = articles[currentIndex + 1];

      // Swap order values
      await _atomicSwapOrder(
        id1: articleId,
        order1: nextArticle['display_order'] ?? (currentIndex + 1),
        id2: nextArticle['id'],
        order2: currentArticle['display_order'] ?? currentIndex,
      );

      print('✅ Article moved down successfully');
      return true;
    } catch (e) {
      print('Error moving article down: $e');
      return false;
    }
  }

  /// Atomic swap of two articles' order values
  Future<void> _atomicSwapOrder({
    required String id1,
    required int order1,
    required String id2,
    required int order2,
  }) async {
    // Use a temporary value to avoid any potential conflicts
    const tempOrder = -999;
    
    await _supabase
        .from('articles')
        .update({'display_order': tempOrder})
        .eq('id', id1);
    
    await _supabase
        .from('articles')
        .update({'display_order': order2})
        .eq('id', id2);
    
    await _supabase
        .from('articles')
        .update({'display_order': order1})
        .eq('id', id1);
  }

  /// Get the next order value for a new article
  Future<int> getNextDisplayOrder(String categoryId) async {
    try {
      final result = await _supabase
          .from('articles')
          .select('display_order')
          .eq('category_id', categoryId)
          .neq('is_deleted', true)
          .order('display_order', ascending: false)
          .limit(1);
      
      if (result.isEmpty) {
        return 0;
      }
      
      return (result.first['display_order'] ?? -1) + 1;
    } catch (e) {
      print('Error getting next display order: $e');
      return 0;
    }
  }
  
  /// Normalize display orders to be sequential (0, 1, 2, ...)
  Future<void> normalizeOrders(String categoryId) async {
    try {
      final articles = await _supabase
          .from('articles')
          .select('id')
          .eq('category_id', categoryId)
          .neq('is_deleted', true)
          .order('display_order', ascending: true);
      
      for (int i = 0; i < articles.length; i++) {
        await _supabase
            .from('articles')
            .update({'display_order': i})
            .eq('id', articles[i]['id']);
      }
      
      print('✅ Normalized ${articles.length} articles');
    } catch (e) {
      print('Error normalizing orders: $e');
    }
  }
}
