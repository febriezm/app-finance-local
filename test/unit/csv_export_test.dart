// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/features/categories/domain/entities/category.dart';
import 'package:myfinance/features/reports/data/services/csv_export_service.dart';
import 'package:myfinance/features/reports/domain/entities/monthly_report.dart';
import 'package:myfinance/features/transactions/domain/entities/transaction.dart';
import 'package:myfinance/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:myfinance/features/wallets/domain/entities/wallet.dart';

void main() {
  const csvService = CsvExportService();

  test('CsvExportService generates valid RFC 4180 CSV with UTF-8 BOM', () {
    const category = Category(
      id: 'cat-food',
      name: 'Makanan & Minuman',
      type: CategoryType.expense,
    );

    const wallet = Wallet(
      id: 'w-1',
      name: 'BCA Utama',
      type: WalletType.bank,
      openingBalance: 1000000,
      openingDate: '2026-11-01T00:00:00.000Z',
      createdAt: '2026-11-01T00:00:00.000Z',
      updatedAt: '2026-11-01T00:00:00.000Z',
    );

    const report = MonthlyReport(
      monthKey: '2026-11',
      totalIncome: 10000000,
      totalExpense: 2500000,
      netCashflow: 7500000,
      savingsRate: 0.75,
      expenseBreakdown: [
        CategoryReportItem(
          category: category,
          amount: 2500000,
          percentage: 1.0,
          transactionCount: 2,
        ),
      ],
      incomeBreakdown: [],
      totalTransactionsCount: 2,
    );

    final transactions = [
      TransactionWithDetails(
        transaction: const Transaction(
          id: 'tx-1',
          type: TransactionType.expense,
          amount: 150000,
          occurredAt: '2026-11-10T12:30:00.000Z',
          walletId: 'w-1',
          categoryId: 'cat-food',
          merchant: 'Kopi Kenangan',
          description: 'Latte',
          status: TransactionStatus.confirmed,
          createdAt: '2026-11-10T12:30:00.000Z',
          updatedAt: '2026-11-10T12:30:00.000Z',
        ),
        wallet: wallet,
        category: category,
      ),
    ];

    final csvString = csvService.generateReportCsv(report, transactions);

    // 1. Must start with UTF-8 BOM
    expect(csvString.startsWith('\uFEFF'), true);

    // 2. Contains metadata headers
    expect(csvString.contains('Laporan Keuangan MyFinance'), true);
    expect(csvString.contains('Periode,2026-11'), true);
    expect(csvString.contains('Total Pemasukan,10000000'), true);
    expect(csvString.contains('Total Pengeluaran,2500000'), true);
    expect(csvString.contains('Arus Kas Bersih (Net Cashflow),7500000'), true);
    expect(csvString.contains('75.0%'), true);

    // 3. Contains Category Breakdown
    expect(csvString.contains('Distribusi Pengeluaran per Kategori'), true);
    expect(csvString.contains('Makanan & Minuman,2500000,100.0,2'), true);

    // 4. Contains Transaction Headers & Row
    expect(csvString.contains('Tanggal,ID Transaksi,Tipe,Nominal (Rp)'), true);
    expect(csvString.contains('tx-1'), true);
    expect(csvString.contains('Pengeluaran'), true);
    expect(csvString.contains('150000'), true);
    expect(csvString.contains('BCA Utama'), true);
    expect(csvString.contains('Kopi Kenangan'), true);
    expect(csvString.contains('Latte'), true);
    expect(csvString.contains('Confirmed'), true);
  });
}
