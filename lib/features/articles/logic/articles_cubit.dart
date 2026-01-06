import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zad_aldaia/features/articles/data/models/article.dart';
import 'package:zad_aldaia/features/articles/data/repos/articles_repo.dart';

part './articles_state.dart';

class ArticlesCubit extends Cubit<ArticlesState> {
  final ArticlesRepo _repo;
  ArticlesCubit(this._repo) : super(LoadingState());

  List<Article> articles = [];

  Future saveArticle(Article article) async {
    // print("id: ${article.id}");
    // print(article.toFormJson());
    try {
      emit(SavingState());
      if (article.id.isEmpty) {
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
}
