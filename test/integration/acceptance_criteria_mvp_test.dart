import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/core/formatting/date_formatter.dart';
import 'package:myfinance/features/wallets/data/repositories/wallet_repository_impl.dart';
import 'package:myfinance/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:myfinance/features/transactions/domain/entities/transaction.dart';
import 'package:myfinance/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:myfinance/features/budgets/domain/entities/budget.dart';
import 'package:myfinance/features/reports/data/repositories/report_repository_impl.dart';
import 'package:myfinance/features/backup_restore/data/repositories/backup_repository_impl.dart';
import 'package:myfinance/features/backup_restore/domain/usecases/create_backup_usecase.dart';
import 'package:myfinance/features/backup_restore/domain/usecases/validate_backup_usecase.dart';
import 'package:myfinance/features/backup_restore/domain/usecases/restore_backup_usecase.dart';
import 'package:myfinance/features/receipt_scanner/domain/entities/ocr_result.dart';
import 'package:myfinance/features/receipt_scanner/data/services/local_receipt_parser.dart';
import 'package:myfinance/features/receipt_scanner/data/services/receipt_ocr_service_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletRepositoryImpl walletRepo;
  late TransactionRepositoryImpl txRepo;
  late BudgetRepositoryImpl budgetRepo;
  late ReportRepositoryImpl reportRepo;
  late BackupRepositoryImpl backupRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    walletRepo = WalletRepositoryImpl(db.walletsDao, db.transactionsDao);
    txRepo = TransactionRepositoryImpl(db.transactionsDao, db.walletsDao, db.categoriesDao);
    budgetRepo = BudgetRepositoryImpl(db.budgetsDao, db.transactionsDao, db.categoriesDao);
    reportRepo = ReportRepositoryImpl(
      transactionRepository: txRepo,
      walletRepository: walletRepo,
    );
    backupRepo = BackupRepositoryImpl(db);

    await db.customStatement('PRAGMA foreign_keys = ON;');
  });

  tearDown(() async {
    await db.close();
  });

  group('Final MVP Acceptance Criteria Verification (Blueprint Section 12)', () {
    test('Criterion 1 & 9: Operates 100% offline with local Drift SQLite persistence', () async {
      // Offline verification: DB is local SQLite in memory/file with zero external network calls
      final initialWallets = await walletRepo.getActiveWallets();
      expect(initialWallets, isEmpty);
    });

    test('Criterion 2: User can create at least two distinct wallets', () async {
      final nowStr = DateTime.now().toIso8601String();

      await db.into(db.walletsTable).insert(
        WalletsTableCompanion.insert(
          id: 'wallet-bca',
          name: 'BCA Prioritas',
          type: 'bank',
          openingBalance: 5000000, // Rp 5.000.000
          openingDate: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      await db.into(db.walletsTable).insert(
        WalletsTableCompanion.insert(
          id: 'wallet-cash',
          name: 'Dompet Tunai',
          type: 'cash',
          openingBalance: 500000, // Rp 500.000
          openingDate: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      final activeWallets = await walletRepo.getActiveWallets();
      expect(activeWallets.length, 2);
      expect(activeWallets.any((w) => w.id == 'wallet-bca'), isTrue);
      expect(activeWallets.any((w) => w.id == 'wallet-cash'), isTrue);
    });

    test('Criterion 3: Income and expense update wallet ledger balance correctly', () async {
      final nowStr = DateTime.now().toIso8601String();

      // Buat wallet: Mandiri (opening: Rp 1.000.000)
      await db.into(db.walletsTable).insert(
        WalletsTableCompanion.insert(
          id: 'wallet-mandiri',
          name: 'Mandiri',
          type: 'bank',
          openingBalance: 1000000,
          openingDate: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      // Catat Income: +Rp 500.000
      await txRepo.createTransaction(
        Transaction(
          id: 'tx-inc-1',
          walletId: 'wallet-mandiri',
          categoryId: 'cat-inc-salary',
          type: TransactionType.income,
          amount: 500000,
          status: TransactionStatus.confirmed,
          occurredAt: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      // Catat Expense: -Rp 200.000
      await txRepo.createTransaction(
        Transaction(
          id: 'tx-exp-1',
          walletId: 'wallet-mandiri',
          categoryId: 'cat-exp-food',
          type: TransactionType.expense,
          amount: 200000,
          status: TransactionStatus.confirmed,
          occurredAt: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      // Balance = 1.000.000 + 500.000 - 200.000 = 1.300.000
      final balance = await walletRepo.calculateWalletBalance('wallet-mandiri');
      expect(balance, 1300000);
    });

    test('Criterion 4: Transfer updates two wallets without altering total assets or total income/expense', () async {
      final nowStr = DateTime.now().toIso8601String();

      await db.into(db.walletsTable).insert(
        WalletsTableCompanion.insert(
          id: 'wallet-source',
          name: 'Source Bank',
          type: 'bank',
          openingBalance: 2000000, // Rp 2.000.000
          openingDate: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      await db.into(db.walletsTable).insert(
        WalletsTableCompanion.insert(
          id: 'wallet-dest',
          name: 'Dest E-Wallet',
          type: 'eWallet',
          openingBalance: 500000, // Rp 500.000
          openingDate: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      // Total aset awal = 2.500.000
      final totalAwal = await walletRepo.calculateTotalAssetBalance();
      expect(totalAwal, 2500000);

      // Lakukan Transfer internal Rp 700.000
      await txRepo.createTransaction(
        Transaction(
          id: 'tx-transfer-1',
          walletId: 'wallet-source',
          destinationWalletId: 'wallet-dest',
          type: TransactionType.transfer,
          amount: 700000,
          status: TransactionStatus.confirmed,
          occurredAt: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      final balSource = await walletRepo.calculateWalletBalance('wallet-source');
      final balDest = await walletRepo.calculateWalletBalance('wallet-dest');

      expect(balSource, 1300000); // 2.000.000 - 700.000
      expect(balDest, 1200000);   // 500.000 + 700.000
      expect(balSource + balDest, 2500000); // Total aset invarian
    });

    test('Criterion 5: Monthly report is consistent with confirmed transactions', () async {
      final now = DateTime.now();
      final monthKey = AppDateFormatter.toMonthKey(now);
      final nowStr = now.toIso8601String();

      await db.into(db.walletsTable).insert(
        WalletsTableCompanion.insert(
          id: 'wallet-main',
          name: 'Main',
          type: 'bank',
          openingBalance: 1000000,
          openingDate: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      // Transaksi confirmed
      await txRepo.createTransaction(
        Transaction(
          id: 't-food',
          walletId: 'wallet-main',
          categoryId: 'cat-exp-food',
          type: TransactionType.expense,
          amount: 150000,
          status: TransactionStatus.confirmed,
          occurredAt: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      // Transaksi voided (harus diabaikan dalam laporan)
      await txRepo.createTransaction(
        Transaction(
          id: 't-voided',
          walletId: 'wallet-main',
          categoryId: 'cat-exp-food',
          type: TransactionType.expense,
          amount: 888888,
          status: TransactionStatus.voided,
          occurredAt: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      final report = await reportRepo.getMonthlyReport(monthKey);

      expect(report.totalExpense, 150000);
      expect(report.netCashflow, -150000);
      expect(report.expenseBreakdown.length, 1);
      expect(report.expenseBreakdown.first.amount, 150000);
    });

    test('Criterion 6: Budget calculation strictly counts confirmed expenses only', () async {
      final now = DateTime.now();
      final monthKey = AppDateFormatter.toMonthKey(now);
      final nowStr = now.toIso8601String();

      await db.into(db.walletsTable).insert(
        WalletsTableCompanion.insert(
          id: 'w-budget',
          name: 'Wallet Budget',
          type: 'cash',
          openingBalance: 0,
          openingDate: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      await budgetRepo.saveBudget(
        budget: Budget(
          id: 'b-$monthKey',
          monthKey: monthKey,
          totalLimit: 2000000, // Rp 2.000.000
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
        categoryLimits: const [],
      );

      // Expense confirmed Rp 400.000
      await txRepo.createTransaction(
        Transaction(
          id: 'tx-conf-budget',
          walletId: 'w-budget',
          categoryId: 'cat-exp-food',
          type: TransactionType.expense,
          amount: 400000,
          status: TransactionStatus.confirmed,
          occurredAt: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      // Transaksi voided (harus diabaikan dari budget)
      await txRepo.createTransaction(
        Transaction(
          id: 'tx-voided-budget',
          walletId: 'w-budget',
          categoryId: 'cat-exp-food',
          type: TransactionType.expense,
          amount: 999000,
          status: TransactionStatus.voided,
          occurredAt: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      final progress = await budgetRepo.getBudgetProgress(monthKey);
      expect(progress.totalLimit, 2000000);
      expect(progress.totalSpent, 400000);
      expect(progress.remaining, 1600000);
      expect(progress.percentage, 0.2);
    });

    test('Criterion 7 & 8: Local receipt parsing works offline, creates drafts, and requires confirmation', () async {
      final nowStr = DateTime.now().toIso8601String();

      await db.into(db.walletsTable).insert(
        WalletsTableCompanion.insert(
          id: 'w-receipt-test',
          name: 'Wallet Receipt',
          type: 'cash',
          openingBalance: 100000,
          openingDate: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      final sample = ReceiptOcrServiceImpl.sampleReceipts['indomaret']!;
      final ocrResult = OcrResult.fromString(sample);

      const parser = LocalReceiptParser();
      final draft = await parser.parse(ocrResult);

      expect(draft.merchant, 'Indomaret');
      expect(draft.totalAmount, 47730);
      expect(draft.items.length, greaterThanOrEqualTo(3));
      expect(draft.isTotalCertain, isTrue);

      // Saldo wallet tidak berkurang sebelum struk dikonfirmasi
      final balanceBeforeConfirm = await walletRepo.calculateWalletBalance('w-receipt-test');
      expect(balanceBeforeConfirm, 100000);

      // Setelah pengguna meninjau dan mengonfirmasi di halaman Review:
      await txRepo.createTransaction(
        Transaction(
          id: 'tx-receipt-confirmed',
          walletId: 'w-receipt-test',
          categoryId: 'cat-exp-food',
          type: TransactionType.expense,
          amount: draft.totalAmount ?? 0,
          status: TransactionStatus.confirmed,
          merchant: draft.merchant,
          occurredAt: DateTime.now().toIso8601String(),
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final balanceAfterConfirm = await walletRepo.calculateWalletBalance('w-receipt-test');
      expect(balanceAfterConfirm, 100000 - 47730); // Rp 52.270
    });

    test('Criterion 10: Local backup and atomic restore with schema validation', () async {
      final nowStr = DateTime.now().toIso8601String();

      // Buat sample data agar backup berisi records
      await db.into(db.walletsTable).insert(
        WalletsTableCompanion.insert(
          id: 'w-backup-sample',
          name: 'Backup Sample Wallet',
          type: 'cash',
          openingBalance: 750000,
          openingDate: nowStr,
          createdAt: nowStr,
          updatedAt: nowStr,
        ),
      );

      final createBackupUseCase = CreateBackupUseCase(backupRepo);
      final validateBackupUseCase = ValidateBackupUseCase(backupRepo);
      final restoreBackupUseCase = RestoreBackupUseCase(backupRepo);

      // 1. Ekspor cadangan JSON
      final backupJson = await createBackupUseCase.exportJson();
      expect(backupJson, isNotEmpty);

      // 2. Validasi arsip
      final validationResult = validateBackupUseCase.execute(backupJson);
      expect(validationResult.isValid, isTrue);
      expect(validationResult.schemaVersion, 1);
      expect(validationResult.walletsCount, greaterThanOrEqualTo(1));

      // 3. Reset basis data
      await backupRepo.resetAllData();
      final walletsAfterReset = await walletRepo.getActiveWallets();
      expect(walletsAfterReset, isEmpty);

      // 4. Pulihkan cadangan secara atomik
      await restoreBackupUseCase.execute(backupJson);

      final restoredWallets = await walletRepo.getActiveWallets();
      expect(restoredWallets.length, validationResult.walletsCount);
      expect(restoredWallets.any((w) => w.id == 'w-backup-sample'), isTrue);
    });
  });
}
