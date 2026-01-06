part of 'articles_cubit.dart';

sealed class ArticlesState {}

class LoadingState extends ArticlesState {}

class LoadedState extends ArticlesState {
  final Article item;

  LoadedState(this.item);
}

class ListLoadedState extends ArticlesState {
  final List<Article> items;
  final bool isOffline;

  ListLoadedState(this.items, {this.isOffline = false});
}

class SavingState extends ArticlesState {}

class SavedState extends ArticlesState {
  // final String data;
  // SavedState(this.data);
}

class ErrorState extends ArticlesState {
  final String error;

  ErrorState(this.error);
}
