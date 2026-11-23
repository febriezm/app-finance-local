import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:myfinance/features/budgets/domain/entities/budget.dart';
import 'package:myfinance/features/budgets/presentation/controllers/budgets_controller.dart';

void main() {
  late AppDatabase db;
  late BudgetRepositoryImpl budgetRepo;
  late BudgetsController controller;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    budgetRepo = BudgetRepositoryImpl(db.budgetsDao, db.transactionsDao, db.categoriesDao);
    controller = BudgetsController(budgetRepo);
  });

  tearDown(() async {
    await db.close();
  });

  test('Save budget with 4 categories using BudgetsController and verify all 4 persist', () async {
    const monthKey = '2026-11';
    final categoryLimitsMap = {
      'cat-exp-food': 1000000,
      'cat-exp-transport': 500000,
      'cat-exp-bills': 300000,
      'cat-exp-shopping': 200000,
    };

    final success = await controller.saveBudget(
      monthKey: monthKey,
      totalLimit: 3000000,
      categoryLimitsMap: categoryLimitsMap,
    );

    expect(success, isTrue);

    final progress = await budgetRepo.getBudgetProgress(monthKey);
    expect(progress.categoryProgresses.length, equals(4));
    expect(progress.totalLimit, equals(3000000));
  });

  test('Stream emits all 4 categories when budget is updated via BudgetsController', () async {
    const monthKey = '2026-11';
    final stream = budgetRepo.watchBudgetProgress(monthKey);

    final recordedEvents = <BudgetProgress>[];
    final sub = stream.listen((event) {
      recordedEvents.add(event);
    });

    // Initial wait for first emit
    await Future.delayed(const Duration(milliseconds: 50));

    final categoryLimitsMap = {
      'cat-exp-food': 1000000,
      'cat-exp-transport': 500000,
      'cat-exp-bills': 300000,
      'cat-exp-shopping': 200000,
    };

    final success = await controller.saveBudget(
      monthKey: monthKey,
      totalLimit: 3000000,
      categoryLimitsMap: categoryLimitsMap,
    );
    expect(success, isTrue);

    await Future.delayed(const Duration(milliseconds: 100));

    expect(recordedEvents.last.categoryProgresses.length, equals(4));

    // Test updating again with 6 categories
    final updateCategoryLimitsMap = {
      'cat-exp-food': 1200000,
      'cat-exp-transport': 600000,
      'cat-exp-bills': 400000,
      'cat-exp-shopping': 300000,
      'cat-exp-entertainment': 200000,
      'cat-exp-health': 150000,
    };

    final successUpdate = await controller.saveBudget(
      monthKey: monthKey,
      totalLimit: 4000000,
      categoryLimitsMap: updateCategoryLimitsMap,
    );
    expect(successUpdate, isTrue);

    await Future.delayed(const Duration(milliseconds: 100));

    expect(recordedEvents.last.categoryProgresses.length, equals(6));
    expect(recordedEvents.last.totalLimit, equals(4000000));

    await sub.cancel();
  });
}
