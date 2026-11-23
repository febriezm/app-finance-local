import '../../../../core/database/app_database.dart';
import '../../domain/entities/budget.dart';

class BudgetModel {
  static Budget fromEntry(BudgetEntry entry) {
    return Budget(
      id: entry.id,
      monthKey: entry.monthKey,
      totalLimit: entry.totalLimit,
      alertThresholds: Budget.parseThresholds(entry.alertThresholds),
      carryOverEnabled: entry.carryOverEnabled,
      notes: entry.notes,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  static BudgetCategoryLimit categoryLimitFromEntry(BudgetCategoryLimitEntry entry) {
    return BudgetCategoryLimit(
      id: entry.id,
      budgetId: entry.budgetId,
      categoryId: entry.categoryId,
      limitAmount: entry.limitAmount,
    );
  }
}
