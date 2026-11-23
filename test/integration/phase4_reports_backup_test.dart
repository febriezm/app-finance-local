import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/core/database/daos/wallets_dao.dart';
import 'package:myfinance/core/database/daos/categories_dao.dart';
import 'package:myfinance/core/database/daos/transactions_dao.dart';
import 'package:myfinance/core/database/daos/budgets_dao.dart';
import 'package:myfinance/features/wallets/data/repositories/wallet_repository_impl.dart';
import 'package:myfinance/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:myfinance/features/transactions/domain/entities/transaction.dart';
import 'package:myfinance/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:myfinance/features/budgets/domain/entities/budget.dart';
import 'package:myfinance/features/reports/data/repositories/report_repository_impl.dart';
import 'package:myfinance/features/backup_restore/data/repositories/backup_repository_impl.dart';

void main() {
  late AppDatabase db;
  late WalletsDao walletsDao;
  late CategoriesDao categoriesDao;
  late TransactionsDao transactionsDao;
  late BudgetsDao budgetsDao;

  late WalletRepositoryImpl walletRepo;
  late TransactionRepositoryImpl transactionRepo;
  late BudgetRepositoryImpl budgetRepo;
  late ReportRepositoryImpl reportRepo;
  late BackupRepositoryImpl backupRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    walletsDao = WalletsDao(db);
    categoriesDao = CategoriesDao(db);
    transactionsDao = TransactionsDao(db);
    budgetsDao = BudgetsDao(db);

    walletRepo = WalletRepositoryImpl(walletsDao, transactionsDao);
    transactionRepo = TransactionRepositoryImpl(transactionsDao, walletsDao, categoriesDao);
    budgetRepo = BudgetRepositoryImpl(budgetsDao, transactionsDao, categoriesDao);
    reportRepo = ReportRepositoryImpl(
      transactionRepository: transactionRepo,
      walletRepository: walletRepo,
    );
    backupRepo = BackupRepositoryImpl(db);

    await db.customStatement('PRAGMA foreign_keys = ON;');
  });

  tearDown(() async {
    await db.close();
  });

  test('Phase 4 Integration: Reports, Export (PDF & CSV), Backup -> Wipe -> Restore -> Verified Ledger', () async {
    // -------------------------------------------------------------
    // 1. Setup Wallets
    // -------------------------------------------------------------
    await db.into(db.walletsTable).insert(
      WalletsTableCompanion.insert(
        id: 'w-bca',
        name: 'BCA Utama',
        type: 'bank',
        openingBalance: 10000000,
        openingDate: '2026-11-01T00:00:00.000Z',
        createdAt: '2026-11-01T00:00:00.000Z',
        updatedAt: '2026-11-01T00:00:00.000Z',
      ),
    );

    await db.into(db.walletsTable).insert(
      WalletsTableCompanion.insert(
        id: 'w-cash',
        name: 'Dompet Tunai',
        type: 'cash',
        openingBalance: 500000,
        openingDate: '2026-11-01T00:00:00.000Z',
        createdAt: '2026-11-01T00:00:00.000Z',
        updatedAt: '2026-11-01T00:00:00.000Z',
      ),
    );

    // -------------------------------------------------------------
    // 2. Setup Transactions in November 2026
    // -------------------------------------------------------------
    // Income: Gaji 15.000.000 to BCA
    await transactionRepo.createTransaction(
      const Transaction(
        id: 'tx-salary',
        type: TransactionType.income,
        amount: 15000000,
        occurredAt: '2026-11-01T08:00:00.000Z',
        walletId: 'w-bca',
        categoryId: 'cat-inc-salary',
        status: TransactionStatus.confirmed,
        createdAt: '2026-11-01T08:00:00.000Z',
        updatedAt: '2026-11-01T08:00:00.000Z',
      ),
    );

    // Expense: Belanja 500.000 from Tunai
    await transactionRepo.createTransaction(
      const Transaction(
        id: 'tx-grocery',
        type: TransactionType.expense,
        amount: 500000,
        occurredAt: '2026-11-05T10:00:00.000Z',
        walletId: 'w-cash',
        categoryId: 'cat-exp-food',
        merchant: 'Pasar Tradisional',
        status: TransactionStatus.confirmed,
        createdAt: '2026-11-05T10:00:00.000Z',
        updatedAt: '2026-11-05T10:00:00.000Z',
      ),
    );

    // Transfer: 2.000.000 from BCA to Tunai
    await transactionRepo.createTransaction(
      const Transaction(
        id: 'tx-atm-withdraw',
        type: TransactionType.transfer,
        amount: 2000000,
        occurredAt: '2026-11-06T11:00:00.000Z',
        walletId: 'w-bca',
        destinationWalletId: 'w-cash',
        status: TransactionStatus.confirmed,
        createdAt: '2026-11-06T11:00:00.000Z',
        updatedAt: '2026-11-06T11:00:00.000Z',
      ),
    );

    // -------------------------------------------------------------
    // 3. Setup Budget
    // -------------------------------------------------------------
    await budgetRepo.saveBudget(
      budget: const Budget(
        id: 'b-2026-11',
        monthKey: '2026-11',
        totalLimit: 5000000,
        createdAt: '2026-11-01T00:00:00.000Z',
        updatedAt: '2026-11-01T00:00:00.000Z',
      ),
      categoryLimits: [
        const BudgetCategoryLimit(
          id: 'lim-food',
          budgetId: 'b-2026-11',
          categoryId: 'cat-exp-food',
          limitAmount: 2000000,
        ),
      ],
    );

    // -------------------------------------------------------------
    // 4. Verify Initial Ledger Balances
    // -------------------------------------------------------------
    final bcaBalanceInitial = await walletRepo.calculateWalletBalance('w-bca');
    // 10.000.000 + 15.000.000 (inc) - 2.000.000 (transfer out) = 23.000.000
    expect(bcaBalanceInitial, 23000000);

    final cashBalanceInitial = await walletRepo.calculateWalletBalance('w-cash');
    // 500.000 - 500.000 (exp) + 2.000.000 (transfer in) = 2.000.000
    expect(cashBalanceInitial, 2000000);

    final totalAssetInitial = await walletRepo.calculateTotalAssetBalance();
    expect(totalAssetInitial, 25000000);

    // -------------------------------------------------------------
    // 5. Verify Monthly Report Generation & Aggregation
    // -------------------------------------------------------------
    final report = await reportRepo.getMonthlyReport('2026-11');
    expect(report.totalIncome, 15000000);
    expect(report.totalExpense, 500000);
    expect(report.netCashflow, 14500000);
    expect(report.isSurplus, true);
    expect(report.totalTransactionsCount, 3);

    // Transfer is not counted in total income or total expense
    expect(report.expenseBreakdown.length, 1);
    expect(report.expenseBreakdown.first.amount, 500000);

    // Wallet breakdown accurately reflects transfer and flow
    final bcaItem = report.walletBreakdown.firstWhere((w) => w.wallet.id == 'w-bca');
    expect(bcaItem.incomeAmount, 15000000);
    expect(bcaItem.transferOutAmount, 2000000);
    expect(bcaItem.netFlow, 13000000);

    final cashItem = report.walletBreakdown.firstWhere((w) => w.wallet.id == 'w-cash');
    expect(cashItem.expenseAmount, 500000);
    expect(cashItem.transferInAmount, 2000000);
    expect(cashItem.netFlow, 1500000);

    // -------------------------------------------------------------
    // 6. Verify Export (PDF & CSV)
    // -------------------------------------------------------------
    final reportTxs = await reportRepo.getTransactionsForReport(monthKey: '2026-11');
    expect(reportTxs.length, 3);

    // CSV
    final csvResult = await reportRepo.exportReportToCsv(report, reportTxs);
    expect(csvResult.startsWith('\uFEFF'), true);
    expect(csvResult.contains('15000000'), true);
    expect(csvResult.contains('Pasar Tradisional'), true);
    expect(csvResult.contains('BCA Utama'), true);

    // PDF
    final pdfBytes = await reportRepo.exportReportToPdf(report, reportTxs);
    expect(pdfBytes.isNotEmpty, true);
    expect(utf8.decode(pdfBytes.sublist(0, 5)), '%PDF-');

    // -------------------------------------------------------------
    // 7. Create & Validate Backup
    // -------------------------------------------------------------
    final backupJson = await backupRepo.exportBackupJson();
    expect(backupJson.contains('BCA Utama'), true);
    expect(backupJson.contains('tx-salary'), true);
    expect(backupJson.contains('b-2026-11'), true);

    final validation = backupRepo.validateBackupJson(backupJson);
    expect(validation.isValid, true);
    expect(validation.walletsCount, 2);
    expect(validation.transactionsCount, 3);
    expect(validation.budgetsCount, 1);
    expect(validation.budgetLimitsCount, 1);

    // -------------------------------------------------------------
    // 8. Wipe Database (Simulate Data Loss / Fresh Device)
    // -------------------------------------------------------------
    await backupRepo.resetAllData();

    final walletsAfterWipe = await walletRepo.getActiveWallets();
    expect(walletsAfterWipe.isEmpty, true);

    final txsAfterWipe = await transactionsDao.getConfirmedLedgerForWallet('w-bca');
    expect(txsAfterWipe.isEmpty, true);

    final budgetAfterWipe = await budgetRepo.getBudgetByMonthKey('2026-11');
    expect(budgetAfterWipe, isNull);

    // -------------------------------------------------------------
    // 9. Restore Database from Backup JSON
    // -------------------------------------------------------------
    await backupRepo.restoreFromJson(backupJson);

    // Verify all entities are restored
    final walletsRestored = await walletRepo.getActiveWallets();
    expect(walletsRestored.length, 2);

    final budgetRestored = await budgetRepo.getBudgetByMonthKey('2026-11');
    expect(budgetRestored, isNotNull);
    expect(budgetRestored!.totalLimit, 5000000);

    final limitsRestored = await budgetRepo.getCategoryLimits(budgetRestored.id);
    expect(limitsRestored.length, 1);
    expect(limitsRestored.first.limitAmount, 2000000);

    // -------------------------------------------------------------
    // 10. Verify Full Ledger & Balance Consistency After Restore
    // -------------------------------------------------------------
    final bcaBalanceRestored = await walletRepo.calculateWalletBalance('w-bca');
    expect(bcaBalanceRestored, bcaBalanceInitial);
    expect(bcaBalanceRestored, 23000000);

    final cashBalanceRestored = await walletRepo.calculateWalletBalance('w-cash');
    expect(cashBalanceRestored, cashBalanceInitial);
    expect(cashBalanceRestored, 2000000);

    final totalAssetRestored = await walletRepo.calculateTotalAssetBalance();
    expect(totalAssetRestored, totalAssetInitial);
    expect(totalAssetRestored, 25000000);
  });
}
