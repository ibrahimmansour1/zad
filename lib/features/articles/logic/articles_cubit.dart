import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zad_aldaia/core/supabase_client.dart';
import 'package:zad_aldaia/features/articles/data/models/article.dart';
import 'package:zad_aldaia/features/articles/data/repos/articles_repo.dart';

part './articles_state.dart';

class ArticlesCubit extends Cubit<ArticlesState> {
  final ArticlesRepo _repo;
  ArticlesCubit(this._repo) : super(LoadingState());

  List<Article> articles = [];

  /// Load content statistics (text, image, video counts) for an article
  Future<void> _loadArticleContentStats(Article article) async {
    try {
      final items = await Supa.client
          .from('article_items')
          .select()
          .eq('article_id', article.id)
          .neq('is_deleted', true)
          .timeout(const Duration(seconds: 10));

      article.textCount =
          (items as List).where((i) => i['type'] == 'text').length;
      article.imageCount =
          (items as List).where((i) => i['type'] == 'image').length;
      article.videoCount =
          (items as List).where((i) => i['type'] == 'video').length;
    } catch (e) {
      print('Error loading content stats for article ${article.id}: $e');
      // Continue with default values (0) if stats loading fails
    }
  }

  Future saveArticle(Article article) async {
    try {
      emit(SavingState());
      if (article.id.isEmpty) {
        // Get next display order for new article
        if (article.categoryId != null) {
          article.displayOrder = await _repo.getNextDisplayOrder(article.categoryId!);
        }
        await _repo.insertArticle(article.toFormJson());
      } else {
        await _repo.updateArticle(article.id, article.toFormJson());
      }
      emit(SavedState());
    } catch (e) {
      emit(ErrorState(e.toString()));
    }
  }

  loadArticles(Map<String, dynamic> eqMap) async {
    try {
      emit(LoadingState());
      articles = (await searchArticles(eqMap));
      
      // Load content statistics for each article
      for (var article in articles) {
        await _loadArticleContentStats(article);
      }
      
      final isOffline = articles.isNotEmpty && articles.any((a) => a.isOffline);
      emit(ListLoadedState(articles, isOffline: isOffline));
    } catch (e) {
      emit(ErrorState(e.toString()));
    }
  }

  loadArticle(Map<String, dynamic> eqMap) async {
    try {
      articles = (await searchArticles(eqMap));
      if (articles.isEmpty) {
        emit(ErrorState('Not Found'));
      } else {
        emit(LoadedState(articles.first));
      }
    } catch (e) {
      emit(ErrorState(e.toString()));
    }
  }

  Future<Article?> findArticle(Map<String, dynamic> eqMap) async {
    final items = (await searchArticles(eqMap));
    return items.isEmpty ? null : items.first;
  }

  Future<List<Article>> searchArticles(Map<String, dynamic> eqMap) async {
    return await _repo.searchArticles(eqMap);
  }

  /// Move article up in the list
  Future<bool> moveArticleUp(String articleId, String categoryId) async {
    return await _repo.moveArticleUp(articleId, categoryId);
  }

  /// Move article down in the list
  Future<bool> moveArticleDown(String articleId, String categoryId) async {
    return await _repo.moveArticleDown(articleId, categoryId);
  }
}
