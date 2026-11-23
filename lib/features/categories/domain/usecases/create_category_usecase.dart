import '../../../../core/errors/failures.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

class CreateCategoryUseCase {
  final CategoryRepository _repository;

  CreateCategoryUseCase(this._repository);

  Future<Category> execute({
    required String name,
    required CategoryType type,
    String? iconKey,
    String? colorHex,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const ValidationFailure('Nama kategori tidak boleh kosong.');
    }

    final category = Category(
      id: UuidGenerator.generate(),
      name: trimmedName,
      type: type,
      iconKey: iconKey,
      colorHex: colorHex,
      isSystem: false,
      isArchived: false,
      sortOrder: 100,
    );

    await _repository.createCategory(category);
    return category;
  }
}
