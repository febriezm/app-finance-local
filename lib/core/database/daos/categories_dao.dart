import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoriesDao extends DatabaseAccessor<AppDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// Mengambil semua kategori aktif berdasarkan jenis ('income' atau 'expense')
  Future<List<CategoryEntry>> getActiveCategoriesByType(String type) {
    return (select(categoriesTable)
          ..where((t) => t.type.equals(type) & t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Watch stream kategori aktif berdasarkan jenis
  Stream<List<CategoryEntry>> watchActiveCategoriesByType(String type) {
    return (select(categoriesTable)
          ..where((t) => t.type.equals(type) & t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Ambil semua kategori aktif
  Future<List<CategoryEntry>> getAllActiveCategories() {
    return (select(categoriesTable)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Ambil kategori berdasarkan ID
  Future<CategoryEntry?> getCategoryById(String id) {
    return (select(categoriesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert kategori
  Future<int> insertCategory(CategoriesTableCompanion category) {
    return into(categoriesTable).insert(category);
  }

  /// Update kategori
  Future<bool> updateCategory(CategoriesTableCompanion category) {
    return update(categoriesTable).replace(category);
  }

  /// Arsipkan kategori kustom
  Future<int> archiveCategory(String id) {
    return (update(categoriesTable)..where((t) => t.id.equals(id))).write(
      const CategoriesTableCompanion(isArchived: Value(true)),
    );
  }
}
