import 'dart:typed_data';
import '../../../categories/domain/entities/category.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../../wallets/domain/repositories/wallet_repository.dart';
import '../../domain/entities/monthly_report.dart';
import '../../domain/entities/wallet_report_item.dart';
import '../../domain/repositories/report_repository.dart';
import '../services/csv_export_service.dart';
import '../services/pdf_export_service.dart';

class ReportRepositoryImpl implements ReportRepository {
  final TransactionRepository _transactionRepository;
  final WalletRepository _walletRepository;
  final CsvExportService _csvExportService;
  final PdfExportService _pdfExportService;

  ReportRepositoryImpl({
    required TransactionRepository transactionRepository,
    required WalletRepository walletRepository,
    CsvExportService csvExportService = const CsvExportService(),
    PdfExportService pdfExportService = const PdfExportService(),
  })  : _transactionRepository = transactionRepository,
        _walletRepository = walletRepository,
        _csvExportService = csvExportService,
        _pdfExportService = pdfExportService;

  @override
  Future<MonthlyReport> getMonthlyReport(String monthKey) async {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59, 999);

    // 1. Fetch transactions of selected month
    final currentTransactions = await _transactionRepository.getTransactionsInDateRange(
      startOfMonth,
      endOfMonth,
    );

    // 2. Fetch all active wallets
    final wallets = await _walletRepository.getActiveWallets();

    int totalIncome = 0;
    int totalExpense = 0;
    int confirmedTxCount = 0;

    final expenseCatAmounts = <String, int>{};
    final expenseCatCounts = <String, int>{};
    final expenseCatMap = <String, Category>{};

    final incomeCatAmounts = <String, int>{};
    final incomeCatCounts = <String, int>{};
    final incomeCatMap = <String, Category>{};

    // Tracking per wallet
    final walletIncome = <String, int>{};
    final walletExpense = <String, int>{};
    final walletTransferIn = <String, int>{};
    final walletTransferOut = <String, int>{};
    final walletTxCounts = <String, int>{};

    for (final item in currentTransactions) {
      if (item.transaction.status != TransactionStatus.confirmed) continue;
      confirmedTxCount++;

      final t = item.transaction;

      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
        if (item.category != null) {
          final catId = item.category!.id;
          incomeCatAmounts[catId] = (incomeCatAmounts[catId] ?? 0) + t.amount;
          incomeCatCounts[catId] = (incomeCatCounts[catId] ?? 0) + 1;
          incomeCatMap[catId] = item.category!;
        }
        if (t.walletId != null) {
          walletIncome[t.walletId!] = (walletIncome[t.walletId!] ?? 0) + t.amount;
          walletTxCounts[t.walletId!] = (walletTxCounts[t.walletId!] ?? 0) + 1;
        }
      } else if (t.type == TransactionType.expense) {
        totalExpense += t.amount;
        if (item.category != null) {
          final catId = item.category!.id;
          expenseCatAmounts[catId] = (expenseCatAmounts[catId] ?? 0) + t.amount;
          expenseCatCounts[catId] = (expenseCatCounts[catId] ?? 0) + 1;
          expenseCatMap[catId] = item.category!;
        }
        if (t.walletId != null) {
          walletExpense[t.walletId!] = (walletExpense[t.walletId!] ?? 0) + t.amount;
          walletTxCounts[t.walletId!] = (walletTxCounts[t.walletId!] ?? 0) + 1;
        }
      } else if (t.type == TransactionType.transfer) {
        if (t.walletId != null) {
          walletTransferOut[t.walletId!] = (walletTransferOut[t.walletId!] ?? 0) + t.amount;
          walletTxCounts[t.walletId!] = (walletTxCounts[t.walletId!] ?? 0) + 1;
        }
        if (t.destinationWalletId != null) {
          walletTransferIn[t.destinationWalletId!] =
              (walletTransferIn[t.destinationWalletId!] ?? 0) + t.amount;
          walletTxCounts[t.destinationWalletId!] =
              (walletTxCounts[t.destinationWalletId!] ?? 0) + 1;
        }
      }
    }

    final netCashflow = totalIncome - totalExpense;
    final savingsRate = (totalIncome > 0 && netCashflow > 0)
        ? (netCashflow / totalIncome)
        : 0.0;

    // Expense breakdown sorted by largest amount
    final expenseBreakdown = expenseCatAmounts.entries.map((e) {
      final cat = expenseCatMap[e.key]!;
      final pct = totalExpense > 0 ? (e.value / totalExpense) : 0.0;
      return CategoryReportItem(
        category: cat,
        amount: e.value,
        percentage: pct,
        transactionCount: expenseCatCounts[e.key] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Income breakdown sorted by largest amount
    final incomeBreakdown = incomeCatAmounts.entries.map((e) {
      final cat = incomeCatMap[e.key]!;
      final pct = totalIncome > 0 ? (e.value / totalIncome) : 0.0;
      return CategoryReportItem(
        category: cat,
        amount: e.value,
        percentage: pct,
        transactionCount: incomeCatCounts[e.key] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Wallet breakdown
    final walletBreakdown = wallets.map((w) {
      return WalletReportItem(
        wallet: w,
        incomeAmount: walletIncome[w.id] ?? 0,
        expenseAmount: walletExpense[w.id] ?? 0,
        transferInAmount: walletTransferIn[w.id] ?? 0,
        transferOutAmount: walletTransferOut[w.id] ?? 0,
        transactionCount: walletTxCounts[w.id] ?? 0,
      );
    }).toList()
      ..sort((a, b) => (b.expenseAmount + b.incomeAmount).compareTo(a.expenseAmount + a.incomeAmount));

    // 3. Fetch previous month data for comparison
    final prevDate = DateTime(year, month - 1, 1);
    final prevStart = DateTime(prevDate.year, prevDate.month, 1);
    final prevEnd = DateTime(prevDate.year, prevDate.month + 1, 0, 23, 59, 59, 999);

    final prevTransactions = await _transactionRepository.getTransactionsInDateRange(
      prevStart,
      prevEnd,
    );

    int prevIncome = 0;
    int prevExpense = 0;
    for (final item in prevTransactions) {
      if (item.transaction.status != TransactionStatus.confirmed) continue;
      if (item.transaction.type == TransactionType.income) {
        prevIncome += item.transaction.amount;
      } else if (item.transaction.type == TransactionType.expense) {
        prevExpense += item.transaction.amount;
      }
    }
    final prevNetCashflow = prevIncome - prevExpense;

    return MonthlyReport(
      monthKey: monthKey,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netCashflow: netCashflow,
      savingsRate: savingsRate,
      expenseBreakdown: expenseBreakdown,
      incomeBreakdown: incomeBreakdown,
      walletBreakdown: walletBreakdown,
      totalTransactionsCount: confirmedTxCount,
      previousMonthIncome: prevIncome,
      previousMonthExpense: prevExpense,
      previousMonthNetCashflow: prevNetCashflow,
    );
  }

  @override
  Future<List<TransactionWithDetails>> getTransactionsForReport({
    required String monthKey,
    String? categoryId,
    String? walletId,
  }) async {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59, 999);

    final all = await _transactionRepository.getTransactionsInDateRange(
      startOfMonth,
      endOfMonth,
    );

    return all.where((item) {
      if (item.transaction.status != TransactionStatus.confirmed) return false;
      if (categoryId != null && item.category?.id != categoryId) return false;
      if (walletId != null) {
        final matchWallet = item.wallet?.id == walletId ||
            item.destinationWallet?.id == walletId;
        if (!matchWallet) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<String> exportReportToCsv(
    MonthlyReport report,
    List<TransactionWithDetails> transactions,
  ) async {
    return _csvExportService.generateReportCsv(report, transactions);
  }

  @override
  Future<Uint8List> exportReportToPdf(
    MonthlyReport report,
    List<TransactionWithDetails> transactions,
  ) async {
    return _pdfExportService.generateReportPdf(report, transactions);
  }
}
