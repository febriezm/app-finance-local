import '../entities/budget.dart';

abstract class BudgetRepository {
  /// Mengambil data master budget berdasarkan bulan (YYYY-MM)
  Future<Budget?> getBudgetByMonthKey(String monthKey);

  /// Watch data master budget berdasarkan bulan (YYYY-MM)
  Stream<Budget?> watchBudgetByMonthKey(String monthKey);

  /// Mengambil limit kategori untuk suatu budget
  Future<List<BudgetCategoryLimit>> getCategoryLimits(String budgetId);

  /// Watch limit kategori untuk suatu budget
  Stream<List<BudgetCategoryLimit>> watchCategoryLimits(String budgetId);

  /// Menghitung progress pemakaian budget bulanan (total & per kategori)
  Future<BudgetProgress> getBudgetProgress(String monthKey);

  /// Stream reaktif progress pemakaian budget bulanan
  Stream<BudgetProgress> watchBudgetProgress(String monthKey);

  /// Menyimpan atau memperbarui budget bulanan beserta limit kategorinya
  Future<void> saveBudget({
    required Budget budget,
    required List<BudgetCategoryLimit> categoryLimits,
  });
}
