import '../../../categories/domain/entities/category.dart';
import 'wallet_report_item.dart';

class CategoryReportItem {
  final Category category;
  final int amount;
  final double percentage; // 0.0 - 1.0
  final int transactionCount;

  const CategoryReportItem({
    required this.category,
    required this.amount,
    required this.percentage,
    this.transactionCount = 0,
  });
}

class MonthlyReport {
  final String monthKey;
  final int totalIncome;
  final int totalExpense;
  final int netCashflow;
  final double savingsRate;
  final List<CategoryReportItem> expenseBreakdown;
  final List<CategoryReportItem> incomeBreakdown;
  final List<WalletReportItem> walletBreakdown;
  final int totalTransactionsCount;

  // Perbandingan dengan bulan sebelumnya
  final int previousMonthIncome;
  final int previousMonthExpense;
  final int previousMonthNetCashflow;

  const MonthlyReport({
    required this.monthKey,
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashflow,
    required this.savingsRate,
    required this.expenseBreakdown,
    required this.incomeBreakdown,
    this.walletBreakdown = const [],
    this.totalTransactionsCount = 0,
    this.previousMonthIncome = 0,
    this.previousMonthExpense = 0,
    this.previousMonthNetCashflow = 0,
  });

  bool get isSurplus => netCashflow >= 0;

  /// Persentase perubahan pemasukan vs bulan lalu (misal: +15.5%)
  double? get incomeChangePercentage {
    if (previousMonthIncome <= 0) return null;
    return ((totalIncome - previousMonthIncome) / previousMonthIncome) * 100;
  }

  /// Persentase perubahan pengeluaran vs bulan lalu (misal: -8.2%)
  double? get expenseChangePercentage {
    if (previousMonthExpense <= 0) return null;
    return ((totalExpense - previousMonthExpense) / previousMonthExpense) * 100;
  }

  /// Persentase perubahan net cashflow vs bulan lalu
  double? get netCashflowChangePercentage {
    if (previousMonthNetCashflow == 0) return null;
    return ((netCashflow - previousMonthNetCashflow) / previousMonthNetCashflow.abs()) * 100;
  }
}
