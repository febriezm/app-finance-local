import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';

class BudgetsController extends StateNotifier<AsyncValue<void>> {
  final BudgetRepository _repository;

  BudgetsController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> saveBudget({
    required String monthKey,
    required int totalLimit,
    List<int> alertThresholds = const [75, 90, 100],
    bool carryOverEnabled = false,
    String? notes,
    required Map<String, int> categoryLimitsMap,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final budgetId = const Uuid().v4();
      final budget = Budget(
        id: budgetId,
        monthKey: monthKey,
        totalLimit: totalLimit,
        alertThresholds: alertThresholds,
        carryOverEnabled: carryOverEnabled,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      final categoryLimits = categoryLimitsMap.entries
          .where((e) => e.value > 0)
          .map((e) {
        return BudgetCategoryLimit(
          id: const Uuid().v4(),
          budgetId: budgetId,
          categoryId: e.key,
          limitAmount: e.value,
        );
      }).toList();

      await _repository.saveBudget(
        budget: budget,
        categoryLimits: categoryLimits,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('Error saving budget: $e\n$st');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
