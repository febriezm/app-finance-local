import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetCategoriesUseCase {
  final CategoryRepository _repository;

  GetCategoriesUseCase(this._repository);

  Future<List<Category>> execute(CategoryType type) {
    return _repository.getActiveCategoriesByType(type);
  }

  Stream<List<Category>> watch(CategoryType type) {
    return _repository.watchActiveCategoriesByType(type);
  }

  Future<List<Category>> getAll() {
    return _repository.getAllActiveCategories();
  }
}
