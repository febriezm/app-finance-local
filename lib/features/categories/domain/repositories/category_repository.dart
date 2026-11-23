import '../entities/category.dart';

abstract class CategoryRepository {
  /// Mengambil semua kategori aktif berdasarkan jenis (income/expense)
  Future<List<Category>> getActiveCategoriesByType(CategoryType type);

  /// Watch stream kategori aktif berdasarkan jenis
  Stream<List<Category>> watchActiveCategoriesByType(CategoryType type);

  /// Mengambil semua kategori aktif (income & expense)
  Future<List<Category>> getAllActiveCategories();

  /// Mengambil satu kategori berdasarkan ID
  Future<Category?> getCategoryById(String id);

  /// Membuat kategori kustom baru
  Future<void> createCategory(Category category);

  /// Memperbarui kategori kustom
  Future<void> updateCategory(Category category);

  /// Mengarsipkan kategori kustom (kategori sistem dilarang diarsip)
  Future<void> archiveCategory(String id);
}
