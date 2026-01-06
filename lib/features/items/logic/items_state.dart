part of 'items_cubit.dart';

sealed class ItemsState {}

class LoadingState extends ItemsState {}

class LoadedState extends ItemsState {
  final Item item;

  LoadedState(this.item);
}

class ListLoadedState extends ItemsState {
  final List<Item> items;
  final bool isOffline;

  ListLoadedState(this.items, {this.isOffline = false});
}

class SavingState extends ItemsState {}

class SavedState extends ItemsState {
  // final String data;
  // SavedState(this.data);
}

class ErrorState extends ItemsState {
  final String error;

  ErrorState(this.error);
}
