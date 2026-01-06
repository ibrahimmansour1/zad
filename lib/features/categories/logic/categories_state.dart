part of 'categories_cubit.dart';

sealed class CategoriesState {}

class LoadingState extends CategoriesState {}

class LoadedState extends CategoriesState {
  final Category item;

  LoadedState(this.item);
}

class ListLoadedState extends CategoriesState {
  final List<Category> items;
  final bool isOffline;

  ListLoadedState(this.items, {this.isOffline = false});
}

class SavingState extends CategoriesState {}

class SavedState extends CategoriesState {
  // final String data;
  // SavedState(this.data);
}

class ErrorState extends CategoriesState {
  final String error;

  ErrorState(this.error);
}
