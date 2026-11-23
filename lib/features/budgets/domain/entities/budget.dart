import 'dart:convert';
import '../../../categories/domain/entities/category.dart';

enum BudgetStatus {
  normal,
  warning,
  critical,
  exceeded;

  String get displayName {
    switch (this) {
      case BudgetStatus.normal:
        return 'Aman';
      case BudgetStatus.warning:
        return 'Mendekati Batas (75%)';
      case BudgetStatus.critical:
        return 'Waspada (90%)';
      case BudgetStatus.exceeded:
        return 'Melebihi Batas (100%+)';
    }
  }

  static BudgetStatus fromPercentage(double percentage) {
    if (percentage >= 1.0) return BudgetStatus.exceeded;
    if (percentage >= 0.90) return BudgetStatus.critical;
    if (percentage >= 0.75) return BudgetStatus.warning;
    return BudgetStatus.normal;
  }
}

class Budget {
  final String id;
  final String monthKey; // Format YYYY-MM
  final int totalLimit; // Nominal Rupiah integer
  final List<int> alertThresholds; // e.g. [75, 90, 100]
  final bool carryOverEnabled;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const Budget({
    required this.id,
    required this.monthKey,
    required this.totalLimit,
    this.alertThresholds = const [75, 90, 100],
    this.carryOverEnabled = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String get alertThresholdsJson => jsonEncode(alertThresholds);

  static List<int> parseThresholds(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => (e as num).toInt()).toList();
    } catch (_) {
      return [75, 90, 100];
    }
  }

  Budget copyWith({
    String? id,
    String? monthKey,
    int? totalLimit,
    List<int>? alertThresholds,
    bool? carryOverEnabled,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      monthKey: monthKey ?? this.monthKey,
      totalLimit: totalLimit ?? this.totalLimit,
      alertThresholds: alertThresholds ?? this.alertThresholds,
      carryOverEnabled: carryOverEnabled ?? this.carryOverEnabled,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BudgetCategoryLimit {
  final String id;
  final String budgetId;
  final String categoryId;
  final int limitAmount;

  const BudgetCategoryLimit({
    required this.id,
    required this.budgetId,
    required this.categoryId,
    required this.limitAmount,
  });
}

class BudgetCategoryProgress {
  final Category category;
  final int limitAmount;
  final int spentAmount;
  final int remainingAmount;
  final double percentage; // e.g. 0.75 for 75%
  final BudgetStatus status;

  const BudgetCategoryProgress({
    required this.category,
    required this.limitAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentage,
    required this.status,
  });
}

class BudgetProgress {
  final Budget? budget;
  final String monthKey;
  final int totalLimit;
  final int totalSpent;
  final int remaining;
  final double percentage;
  final BudgetStatus status;
  final bool hasConfigurationWarning; // Warning jika total limit kategori > total budget
  final List<BudgetCategoryProgress> categoryProgresses;

  const BudgetProgress({
    this.budget,
    required this.monthKey,
    required this.totalLimit,
    required this.totalSpent,
    required this.remaining,
    required this.percentage,
    required this.status,
    this.hasConfigurationWarning = false,
    this.categoryProgresses = const [],
  });

  bool get hasBudget => budget != null && totalLimit > 0;
}
