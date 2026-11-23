import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/categories_dao.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoriesDao _categoriesDao;

  CategoryRepositoryImpl(this._categoriesDao);

  @override
  Future<List<Category>> getActiveCategoriesByType(CategoryType type) async {
    final entries = await _categoriesDao.getActiveCategoriesByType(type.toDbString());
    return entries.map(CategoryModel.fromEntry).toList();
  }

  @override
  Stream<List<Category>> watchActiveCategoriesByType(CategoryType type) {
    return _categoriesDao.watchActiveCategoriesByType(type.toDbString()).map(
          (entries) => entries.map(CategoryModel.fromEntry).toList(),
        );
  }

  @override
  Future<List<Category>> getAllActiveCategories() async {
    final entries = await _categoriesDao.getAllActiveCategories();
    return entries.map(CategoryModel.fromEntry).toList();
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final entry = await _categoriesDao.getCategoryById(id);
    return entry != null ? CategoryModel.fromEntry(entry) : null;
  }

  @override
  Future<void> createCategory(Category category) async {
    await _categoriesDao.insertCategory(
      CategoriesTableCompanion.insert(
        id: category.id,
        name: category.name,
        type: category.type.toDbString(),
        iconKey: Value(category.iconKey),
        colorHex: Value(category.colorHex),
        isSystem: Value(category.isSystem),
        isArchived: Value(category.isArchived),
        sortOrder: Value(category.sortOrder),
      ),
    );
  }

  @override
  Future<void> updateCategory(Category category) async {
    await _categoriesDao.updateCategory(
      CategoriesTableCompanion(
        id: Value(category.id),
        name: Value(category.name),
        type: Value(category.type.toDbString()),
        iconKey: Value(category.iconKey),
        colorHex: Value(category.colorHex),
        sortOrder: Value(category.sortOrder),
      ),
    );
  }

  @override
  Future<void> archiveCategory(String id) async {
    final existing = await _categoriesDao.getCategoryById(id);
    if (existing == null) {
      throw const NotFoundFailure('Kategori tidak ditemukan.');
    }
    if (existing.isSystem) {
      throw const ValidationFailure('Kategori sistem bawaan tidak dapat diarsipkan atau dihapus.');
    }
    await _categoriesDao.archiveCategory(id);
  }
}
