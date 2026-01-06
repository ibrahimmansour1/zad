import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zad_aldaia/features/categories/data/models/category.dart';
import 'package:zad_aldaia/features/categories/data/repos/categories_repo.dart';

part './categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  final CategoriesRepo _repo;
  CategoriesCubit(this._repo) : super(LoadingState());

  List<Category> categories = [];

  Future saveCategory(Category category) async {
    // print("id: ${category.id}");
    // print(category.toFormJson());
    try {
      emit(SavingState());
      if (category.id.isEmpty) {
        await _repo.insertCategory(category.toFormJson());
      } else {
        await _repo.updateCategory(category.id, category.toFormJson());
      }
      emit(SavedState());
    } catch (e) {
      emit(ErrorState(e.toString()));
    }
  }

  loadCategories(Map<String, dynamic> eqMap) async {
    emit(LoadingState());
    try {
      categories = (await searchCategories(eqMap));
      final isOffline = categories.any((c) => c.isOffline);
      emit(ListLoadedState(categories, isOffline: isOffline));
    } catch (e) {
      emit(ErrorState(e.toString()));
    }
  }

  loadCategory(Map<String, dynamic> eqMap) async {
    try {
      emit(LoadingState());
      categories = (await searchCategories(eqMap));
      if (categories.isEmpty) {
        emit(ErrorState('Not Found'));
      } else {
        emit(LoadedState(categories.first));
      }
    } catch (e) {
      emit(ErrorState(e.toString()));
    }
  }

  Future<Category?> findCategory(Map<String, dynamic> eqMap) async {
    final items = (await searchCategories(eqMap));
    return items.isEmpty ? null : items.first;
  }

  Future<List<Category>> searchCategories(Map<String, dynamic> eqMap) async {
    return await _repo.searchCategories(eqMap);
  }

  getChildCategories(String? parentId) async {
    try {
      emit(LoadingState());
      var categories = await _repo.fetchCategories(parentId);
      this.categories = categories;
      final isOffline = categories.any((c) => c.isOffline);
      emit(ListLoadedState(categories, isOffline: isOffline));
    } catch (e) {
      emit(ErrorState(e.toString()));
    }
  }

  Future<bool> swapCategoriesOrder(
      {required String id1,
      required String id2,
      required int index1,
      required int index2}) async {
    return await _repo.swapCategoriesOrder(id1, id2, index1, index2);
  }
}
