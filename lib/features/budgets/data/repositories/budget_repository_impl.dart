import 'dart:async';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/budgets_dao.dart';
import '../../../../core/database/daos/transactions_dao.dart';
import '../../../../core/database/daos/categories_dao.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../models/budget_model.dart';
import '../../../categories/data/models/category_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetsDao _budgetsDao;
  final TransactionsDao _transactionsDao;
  final CategoriesDao _categoriesDao;

  BudgetRepositoryImpl(
    this._budgetsDao,
    this._transactionsDao,
    this._categoriesDao,
  );

  @override
  Future<Budget?> getBudgetByMonthKey(String monthKey) async {
    final entry = await _budgetsDao.getBudgetByMonthKey(monthKey);
    return entry != null ? BudgetModel.fromEntry(entry) : null;
  }

  @override
  Stream<Budget?> watchBudgetByMonthKey(String monthKey) {
    return _budgetsDao.watchBudgetByMonthKey(monthKey).map(
          (entry) => entry != null ? BudgetModel.fromEntry(entry) : null,
        );
  }

  @override
  Future<List<BudgetCategoryLimit>> getCategoryLimits(String budgetId) async {
    final entries = await _budgetsDao.getCategoryLimitsForBudget(budgetId);
    return entries.map(BudgetModel.categoryLimitFromEntry).toList();
  }

  @override
  Stream<List<BudgetCategoryLimit>> watchCategoryLimits(String budgetId) {
    return _budgetsDao.watchCategoryLimitsForBudget(budgetId).map(
          (entries) => entries.map(BudgetModel.categoryLimitFromEntry).toList(),
        );
  }

  @override
  Future<BudgetProgress> getBudgetProgress(String monthKey) async {
    // 1. Parse month key (YYYY-MM)
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    // Batas waktu awal dan akhir bulan lokal dikonversi ke ISO UTC
    final startIso = DateTime(year, month, 1).toUtc().toIso8601String();
    final endIso = DateTime(year, month + 1, 0, 23, 59, 59, 999).toUtc().toIso8601String();

    // 2. Ambil transaksi pengeluaran (confirmed expense) saja
    final expenses = await _transactionsDao.getConfirmedExpensesInDateRange(startIso, endIso);

    int totalSpent = 0;
    final categorySpentMap = <String, int>{};

    for (final exp in expenses) {
      totalSpent += exp.amount;
      if (exp.categoryId != null) {
        categorySpentMap[exp.categoryId!] = (categorySpentMap[exp.categoryId!] ?? 0) + exp.amount;
      }
    }

    // 3. Ambil budget master bulan ini
    final budgetEntry = await _budgetsDao.getBudgetByMonthKey(monthKey);
    Budget? budget;
    int totalLimit = 0;
    int remaining = 0;
    double percentage = 0.0;
    BudgetStatus status = BudgetStatus.normal;
    bool hasConfigurationWarning = false;
    final categoryProgresses = <BudgetCategoryProgress>[];

    if (budgetEntry != null) {
      budget = BudgetModel.fromEntry(budgetEntry);
      totalLimit = budget.totalLimit;
      remaining = totalLimit - totalSpent;
      percentage = totalLimit > 0 ? (totalSpent / totalLimit) : 0.0;
      status = BudgetStatus.fromPercentage(percentage);

      // 4. Ambil limits per kategori
      final limitEntries = await _budgetsDao.getCategoryLimitsForBudget(budget.id);
      int sumCategoryLimits = 0;

      for (final limitEntry in limitEntries) {
        sumCategoryLimits += limitEntry.limitAmount;
        final catEntry = await _categoriesDao.getCategoryById(limitEntry.categoryId);
        if (catEntry != null) {
          final cat = CategoryModel.fromEntry(catEntry);
          final spent = categorySpentMap[limitEntry.categoryId] ?? 0;
          final rem = limitEntry.limitAmount - spent;
          final pct = limitEntry.limitAmount > 0 ? (spent / limitEntry.limitAmount) : 0.0;
          categoryProgresses.add(
            BudgetCategoryProgress(
              category: cat,
              limitAmount: limitEntry.limitAmount,
              spentAmount: spent,
              remainingAmount: rem,
              percentage: pct,
              status: BudgetStatus.fromPercentage(pct),
            ),
          );
        }
      }

      // Deteksi peringatan jika total limit kategori melebihi total budget
      if (sumCategoryLimits > totalLimit) {
        hasConfigurationWarning = true;
      }
    }

    return BudgetProgress(
      budget: budget,
      monthKey: monthKey,
      totalLimit: totalLimit,
      totalSpent: totalSpent,
      remaining: remaining,
      percentage: percentage,
      status: status,
      hasConfigurationWarning: hasConfigurationWarning,
      categoryProgresses: categoryProgresses,
    );
  }

  @override
  Stream<BudgetProgress> watchBudgetProgress(String monthKey) {
    late StreamController<BudgetProgress> controller;
    StreamSubscription? subBudget;
    StreamSubscription? subCategoryLimits;
    StreamSubscription? subTransactions;

    bool isRefreshing = false;
    bool pendingRefresh = false;

    void refresh() async {
      if (isRefreshing) {
        pendingRefresh = true;
        return;
      }
      isRefreshing = true;
      try {
        do {
          pendingRefresh = false;
          final progress = await getBudgetProgress(monthKey);
          if (!controller.isClosed) {
            controller.add(progress);
          }
        } while (pendingRefresh);
      } catch (e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
        }
      } finally {
        isRefreshing = false;
      }
    }

    controller = StreamController<BudgetProgress>(
      onListen: () {
        refresh();
        subBudget = _budgetsDao.watchBudgetByMonthKey(monthKey).listen((_) => refresh());
        subCategoryLimits = _budgetsDao.watchAllCategoryLimits().listen((_) => refresh());
        subTransactions = _transactionsDao.watchRecentTransactions(limit: 1).listen((_) => refresh());
      },
      onCancel: () {
        subBudget?.cancel();
        subCategoryLimits?.cancel();
        subTransactions?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> saveBudget({
    required Budget budget,
    required List<BudgetCategoryLimit> categoryLimits,
  }) async {
    // 1. Validasi
    if (budget.totalLimit <= 0) {
      throw const ValidationFailure('Total limit budget bulanan harus lebih dari 0.');
    }

    final validCategoryLimits = categoryLimits.where((l) => l.limitAmount > 0).toList();

    // 2. Simpan master budget dan limit kategori dalam satu transaksi atomik
    final existing = await _budgetsDao.getBudgetByMonthKey(budget.monthKey);
    final now = DateTime.now().toUtc().toIso8601String();
    final effectiveBudgetId = existing?.id ?? budget.id;
    final isUpdate = existing != null;

    final budgetCompanion = isUpdate
        ? BudgetsTableCompanion(
            id: Value(existing.id),
            monthKey: Value(budget.monthKey),
            totalLimit: Value(budget.totalLimit),
            alertThresholds: Value(budget.alertThresholdsJson),
            carryOverEnabled: Value(budget.carryOverEnabled),
            notes: Value(budget.notes),
            createdAt: Value(existing.createdAt),
            updatedAt: Value(now),
          )
        : BudgetsTableCompanion.insert(
            id: budget.id,
            monthKey: budget.monthKey,
            totalLimit: budget.totalLimit,
            alertThresholds: Value(budget.alertThresholdsJson),
            carryOverEnabled: Value(budget.carryOverEnabled),
            notes: Value(budget.notes),
            createdAt: now,
            updatedAt: now,
          );

    final limitCompanions = validCategoryLimits.map((limit) {
      return BudgetCategoryLimitsTableCompanion.insert(
        id: limit.id,
        budgetId: effectiveBudgetId,
        categoryId: limit.categoryId,
        limitAmount: limit.limitAmount,
      );
    }).toList();

    await _budgetsDao.saveBudgetWithLimits(
      budget: budgetCompanion,
      isUpdate: isUpdate,
      effectiveBudgetId: effectiveBudgetId,
      limits: limitCompanions,
    );
  }
}
