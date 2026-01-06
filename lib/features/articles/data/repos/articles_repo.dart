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

      final response = await query.timeout(const Duration(seconds: 10));
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
}
