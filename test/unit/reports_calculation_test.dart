// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/core/database/daos/wallets_dao.dart';
import 'package:myfinance/core/database/daos/categories_dao.dart';
import 'package:myfinance/core/database/daos/transactions_dao.dart';
import 'package:myfinance/features/wallets/data/repositories/wallet_repository_impl.dart';
import 'package:myfinance/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:myfinance/features/transactions/domain/entities/transaction.dart';
import 'package:myfinance/features/reports/data/repositories/report_repository_impl.dart';

void main() {
  late AppDatabase db;
  late WalletsDao walletsDao;
  late CategoriesDao categoriesDao;
  late TransactionsDao transactionsDao;
  late WalletRepositoryImpl walletRepo;
  late TransactionRepositoryImpl transactionRepo;
  late ReportRepositoryImpl reportRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    walletsDao = WalletsDao(db);
    categoriesDao = CategoriesDao(db);
    transactionsDao = TransactionsDao(db);
    walletRepo = WalletRepositoryImpl(walletsDao, transactionsDao);
    transactionRepo = TransactionRepositoryImpl(transactionsDao, walletsDao, categoriesDao);
    reportRepo = ReportRepositoryImpl(
      transactionRepository: transactionRepo,
      walletRepository: walletRepo,
    );

    // Seed default categories
    await db.customStatement('PRAGMA foreign_keys = ON;');
  });

  tearDown(() async {
    await db.close();
  });

  test('Reports calculation calculates income, expense, net cashflow, and ignores voided transactions', () async {
    // 1. Create a wallet
    await db.into(db.walletsTable).insert(
      WalletsTableCompanion.insert(
        id: 'w-1',
        name: 'Bank Mandiri',
        type: 'bank',
        openingBalance: 1000000,
        openingDate: '2026-11-01T00:00:00.000Z',
        createdAt: '2026-11-01T00:00:00.000Z',
        updatedAt: '2026-11-01T00:00:00.000Z',
      ),
    );

    // 2. Insert Confirmed Income
    await transactionRepo.createTransaction(
      Transaction(
        id: 't-inc',
        type: TransactionType.income,
        amount: 5000000,
        occurredAt: '2026-11-05T10:00:00.000Z',
        walletId: 'w-1',
        categoryId: 'cat-inc-salary',
        status: TransactionStatus.confirmed,
        createdAt: '2026-11-05T10:00:00.000Z',
        updatedAt: '2026-11-05T10:00:00.000Z',
      ),
    );

    // 3. Insert Confirmed Expense
    await transactionRepo.createTransaction(
      Transaction(
        id: 't-exp',
        type: TransactionType.expense,
        amount: 1500000,
        occurredAt: '2026-11-10T12:00:00.000Z',
        walletId: 'w-1',
        categoryId: 'cat-exp-food',
        status: TransactionStatus.confirmed,
        createdAt: '2026-11-10T12:00:00.000Z',
        updatedAt: '2026-11-10T12:00:00.000Z',
      ),
    );

    // 4. Insert Voided Expense (Must be ignored in report!)
    await transactionRepo.createTransaction(
      Transaction(
        id: 't-void',
        type: TransactionType.expense,
        amount: 800000,
        occurredAt: '2026-11-12T15:00:00.000Z',
        walletId: 'w-1',
        categoryId: 'cat-exp-food',
        status: TransactionStatus.voided,
        createdAt: '2026-11-12T15:00:00.000Z',
        updatedAt: '2026-11-12T15:00:00.000Z',
      ),
    );

    // Calculate report for 2026-11
    final report = await reportRepo.getMonthlyReport('2026-11');

    expect(report.totalIncome, 5000000);
    expect(report.totalExpense, 1500000); // 800.000 voided is strictly excluded!
    expect(report.netCashflow, 3500000);
    expect(report.isSurplus, true);
    expect(report.savingsRate, closeTo(3500000 / 5000000, 0.0001));
    expect(report.totalTransactionsCount, 2); // 2 confirmed transactions
    expect(report.expenseBreakdown.length, 1);
    expect(report.expenseBreakdown.first.amount, 1500000);
  });

  test('Reports calculation tracks month-over-month comparison accurately', () async {
    // Wallet
    await db.into(db.walletsTable).insert(
      WalletsTableCompanion.insert(
        id: 'w-1',
        name: 'BCA',
        type: 'bank',
        openingBalance: 10000000,
        openingDate: '2026-10-01T00:00:00.000Z',
        createdAt: '2026-10-01T00:00:00.000Z',
        updatedAt: '2026-10-01T00:00:00.000Z',
      ),
    );

    // Previous month (October 2026) transactions
    await transactionRepo.createTransaction(
      Transaction(
        id: 't-oct-inc',
        type: TransactionType.income,
        amount: 8000000,
        occurredAt: '2026-10-05T10:00:00.000Z',
        walletId: 'w-1',
        categoryId: 'cat-inc-salary',
        status: TransactionStatus.confirmed,
        createdAt: '2026-10-05T10:00:00.000Z',
        updatedAt: '2026-10-05T10:00:00.000Z',
      ),
    );
    await transactionRepo.createTransaction(
      Transaction(
        id: 't-oct-exp',
        type: TransactionType.expense,
        amount: 4000000,
        occurredAt: '2026-10-15T10:00:00.000Z',
        walletId: 'w-1',
        categoryId: 'cat-exp-food',
        status: TransactionStatus.confirmed,
        createdAt: '2026-10-15T10:00:00.000Z',
        updatedAt: '2026-10-15T10:00:00.000Z',
      ),
    );

    // Current month (November 2026) transactions
    await transactionRepo.createTransaction(
      Transaction(
        id: 't-nov-inc',
        type: TransactionType.income,
        amount: 10000000, // +25% vs October (8.000.000)
        occurredAt: '2026-11-05T10:00:00.000Z',
        walletId: 'w-1',
        categoryId: 'cat-inc-salary',
        status: TransactionStatus.confirmed,
        createdAt: '2026-11-05T10:00:00.000Z',
        updatedAt: '2026-11-05T10:00:00.000Z',
      ),
    );
    await transactionRepo.createTransaction(
      Transaction(
        id: 't-nov-exp',
        type: TransactionType.expense,
        amount: 3000000, // -25% vs October (4.000.000)
        occurredAt: '2026-11-15T10:00:00.000Z',
        walletId: 'w-1',
        categoryId: 'cat-exp-food',
        status: TransactionStatus.confirmed,
        createdAt: '2026-11-15T10:00:00.000Z',
        updatedAt: '2026-11-15T10:00:00.000Z',
      ),
    );

    final report = await reportRepo.getMonthlyReport('2026-11');

    expect(report.previousMonthIncome, 8000000);
    expect(report.previousMonthExpense, 4000000);
    expect(report.previousMonthNetCashflow, 4000000);

    // +25% income
    expect(report.incomeChangePercentage, closeTo(25.0, 0.01));
    // -25% expense
    expect(report.expenseChangePercentage, closeTo(-25.0, 0.01));
  });

  test('Wallet breakdown tracks income, expense, and transfer mutasi per wallet', () async {
    // 2 wallets: BCA and GoPay
    await db.into(db.walletsTable).insert(
      WalletsTableCompanion.insert(
        id: 'w-bca',
        name: 'BCA',
        type: 'bank',
        openingBalance: 5000000,
        openingDate: '2026-11-01T00:00:00.000Z',
        createdAt: '2026-11-01T00:00:00.000Z',
        updatedAt: '2026-11-01T00:00:00.000Z',
      ),
    );
    await db.into(db.walletsTable).insert(
      WalletsTableCompanion.insert(
        id: 'w-gopay',
        name: 'GoPay',
        type: 'e_wallet',
        openingBalance: 200000,
        openingDate: '2026-11-01T00:00:00.000Z',
        createdAt: '2026-11-01T00:00:00.000Z',
        updatedAt: '2026-11-01T00:00:00.000Z',
      ),
    );

    // 1. Transfer 500.000 from BCA to GoPay
    await transactionRepo.createTransaction(
      Transaction(
        id: 't-trf',
        type: TransactionType.transfer,
        amount: 500000,
        occurredAt: '2026-11-03T09:00:00.000Z',
        walletId: 'w-bca',
        destinationWalletId: 'w-gopay',
        status: TransactionStatus.confirmed,
        createdAt: '2026-11-03T09:00:00.000Z',
        updatedAt: '2026-11-03T09:00:00.000Z',
      ),
    );

    // 2. Expense 150.000 on GoPay
    await transactionRepo.createTransaction(
      Transaction(
        id: 't-gopay-exp',
        type: TransactionType.expense,
        amount: 150000,
        occurredAt: '2026-11-04T12:00:00.000Z',
        walletId: 'w-gopay',
        categoryId: 'cat-exp-food',
        status: TransactionStatus.confirmed,
        createdAt: '2026-11-04T12:00:00.000Z',
        updatedAt: '2026-11-04T12:00:00.000Z',
      ),
    );

    final report = await reportRepo.getMonthlyReport('2026-11');

    // Transfer is NOT included in total income or total expense
    expect(report.totalIncome, 0);
    expect(report.totalExpense, 150000);
    expect(report.netCashflow, -150000);

    // But walletBreakdown captures the mutasi!
    final bcaBreakdown = report.walletBreakdown.firstWhere((w) => w.wallet.id == 'w-bca');
    expect(bcaBreakdown.transferOutAmount, 500000);
    expect(bcaBreakdown.netFlow, -500000);

    final gopayBreakdown = report.walletBreakdown.firstWhere((w) => w.wallet.id == 'w-gopay');
    expect(gopayBreakdown.transferInAmount, 500000);
    expect(gopayBreakdown.expenseAmount, 150000);
    expect(gopayBreakdown.netFlow, 350000); // +500.000 in, -150.000 out
  });
}
