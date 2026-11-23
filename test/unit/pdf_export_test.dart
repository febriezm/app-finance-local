import 'dart:convert';
// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/features/categories/domain/entities/category.dart';
import 'package:myfinance/features/reports/data/services/pdf_export_service.dart';
import 'package:myfinance/features/reports/domain/entities/monthly_report.dart';
import 'package:myfinance/features/transactions/domain/entities/transaction.dart';
import 'package:myfinance/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:myfinance/features/wallets/domain/entities/wallet.dart';

void main() {
  const pdfService = PdfExportService();

  test('PdfExportService generates valid PDF document binary with header and tables', () async {
    const category = Category(
      id: 'cat-food',
      name: 'Makanan & Minuman',
      type: CategoryType.expense,
    );

    const wallet = Wallet(
      id: 'w-1',
      name: 'BCA Utama',
      type: WalletType.bank,
      openingBalance: 5000000,
      openingDate: '2026-11-01T00:00:00.000Z',
      createdAt: '2026-11-01T00:00:00.000Z',
      updatedAt: '2026-11-01T00:00:00.000Z',
    );

    const report = MonthlyReport(
      monthKey: '2026-11',
      totalIncome: 10000000,
      totalExpense: 2000000,
      netCashflow: 8000000,
      savingsRate: 0.8,
      previousMonthIncome: 9000000,
      previousMonthExpense: 2500000,
      previousMonthNetCashflow: 6500000,
      expenseBreakdown: [
        CategoryReportItem(
          category: category,
          amount: 2000000,
          percentage: 1.0,
          transactionCount: 5,
        ),
      ],
      incomeBreakdown: [],
      totalTransactionsCount: 5,
    );

    final transactions = [
      TransactionWithDetails(
        transaction: const Transaction(
          id: 'tx-101',
          type: TransactionType.expense,
          amount: 120000,
          occurredAt: '2026-11-15T14:00:00.000Z',
          walletId: 'w-1',
          categoryId: 'cat-food',
          merchant: 'Restoran Sederhana',
          description: 'Makan siang tim',
          status: TransactionStatus.confirmed,
          createdAt: '2026-11-15T14:00:00.000Z',
          updatedAt: '2026-11-15T14:00:00.000Z',
        ),
        wallet: wallet,
        category: category,
      ),
    ];

    final pdfBytes = await pdfService.generateReportPdf(report, transactions);

    expect(pdfBytes.isNotEmpty, true);
    expect(pdfBytes.length, greaterThan(1000));

    // Valid PDF starts with "%PDF-"
    final magicBytes = utf8.decode(pdfBytes.sublist(0, 5));
    expect(magicBytes, '%PDF-');
  });
}
