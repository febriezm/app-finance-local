import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/core/errors/failures.dart';
import 'package:myfinance/features/wallets/data/repositories/wallet_repository_impl.dart';
import 'package:myfinance/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:myfinance/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:myfinance/features/wallets/domain/entities/wallet.dart';
import 'package:myfinance/features/transactions/domain/entities/transaction.dart';
import 'package:myfinance/features/budgets/domain/entities/budget.dart';

void main() {
  late AppDatabase db;
  late WalletRepositoryImpl walletRepo;
  late TransactionRepositoryImpl transactionRepo;
  late BudgetRepositoryImpl budgetRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    walletRepo = WalletRepositoryImpl(db.walletsDao, db.transactionsDao);
    transactionRepo = TransactionRepositoryImpl(db.transactionsDao, db.walletsDao, db.categoriesDao);
    budgetRepo = BudgetRepositoryImpl(db.budgetsDao, db.transactionsDao, db.categoriesDao);

    final now = DateTime.now().toUtc().toIso8601String();
    await walletRepo.createWallet(
      Wallet(
        id: 'w-main',
        name: 'Rekening Utama',
        type: WalletType.bank,
        openingBalance: 10000000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await walletRepo.createWallet(
      Wallet(
        id: 'w-second',
        name: 'Dompet Cadangan',
        type: WalletType.cash,
        openingBalance: 2000000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 2 - Budget Engine Unit Tests', () {
    test('Confirmed expenses reduce budget; Income and Transfer do not reduce budget', () async {
      const monthKey = '2026-11';
      final nowUtc = DateTime.utc(2026, 11, 15, 10, 0, 0).toIso8601String();

      // Set budget total Rp 2.000.000
      await budgetRepo.saveBudget(
        budget: Budget(
          id: 'b-nov-2026',
          monthKey: monthKey,
          totalLimit: 2000000,
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
        categoryLimits: [
          const BudgetCategoryLimit(
            id: 'bcl-food',
            budgetId: 'b-nov-2026',
            categoryId: 'cat-exp-food',
            limitAmount: 1000000,
          ),
          const BudgetCategoryLimit(
            id: 'bcl-transport',
            budgetId: 'b-nov-2026',
            categoryId: 'cat-exp-transport',
            limitAmount: 500000,
          ),
        ],
      );

      // Verifikasi initial progress
      var progress = await budgetRepo.getBudgetProgress(monthKey);
      expect(progress.totalLimit, equals(2000000));
      expect(progress.totalSpent, equals(0));
      expect(progress.remaining, equals(2000000));
      expect(progress.status, equals(BudgetStatus.normal));

      // 1. Catat Expense Makanan Rp 400.000
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-exp-1',
          type: TransactionType.expense,
          amount: 400000,
          occurredAt: nowUtc,
          walletId: 'w-main',
          categoryId: 'cat-exp-food',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      );

      // 2. Catat Income Gaji Rp 5.000.000 (tidak boleh mengurangi budget!)
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-inc-1',
          type: TransactionType.income,
          amount: 5000000,
          occurredAt: nowUtc,
          walletId: 'w-main',
          categoryId: 'cat-inc-salary',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      );

      // 3. Catat Transfer Antar-wallet Rp 1.000.000 (tidak boleh mengurangi budget!)
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-tr-1',
          type: TransactionType.transfer,
          amount: 1000000,
          occurredAt: nowUtc,
          walletId: 'w-main',
          destinationWalletId: 'w-second',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      );

      // Progress budget setelah transaksi
      progress = await budgetRepo.getBudgetProgress(monthKey);
      expect(progress.totalSpent, equals(400000)); // Hanya expense Rp 400.000 yang dihitung
      expect(progress.remaining, equals(1600000));
      expect(progress.percentage, closeTo(0.20, 0.001));
      expect(progress.status, equals(BudgetStatus.normal));

      // Cek kategori food
      final foodProgress = progress.categoryProgresses.firstWhere((c) => c.category.id == 'cat-exp-food');
      expect(foodProgress.spentAmount, equals(400000));
      expect(foodProgress.remainingAmount, equals(600000));
      expect(foodProgress.percentage, closeTo(0.40, 0.001));
      expect(foodProgress.status, equals(BudgetStatus.normal));
    });

    test('Threshold status transitions: normal (<75%), warning (>=75%), critical (>=90%), exceeded (>=100%)', () async {
      const monthKey = '2026-11';
      final nowUtc = DateTime.utc(2026, 11, 15).toIso8601String();

      // Budget total Rp 1.000.000
      await budgetRepo.saveBudget(
        budget: Budget(
          id: 'b-threshold',
          monthKey: monthKey,
          totalLimit: 1000000,
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
        categoryLimits: [],
      );

      // 1. Expense 700.000 (70%) -> normal
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-1',
          type: TransactionType.expense,
          amount: 700000,
          occurredAt: nowUtc,
          walletId: 'w-main',
          categoryId: 'cat-exp-bills',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      );
      var p = await budgetRepo.getBudgetProgress(monthKey);
      expect(p.status, equals(BudgetStatus.normal));

      // 2. Expense tambah 50.000 (Total 750.000 = 75%) -> warning
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-2',
          type: TransactionType.expense,
          amount: 50000,
          occurredAt: nowUtc,
          walletId: 'w-main',
          categoryId: 'cat-exp-bills',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      );
      p = await budgetRepo.getBudgetProgress(monthKey);
      expect(p.status, equals(BudgetStatus.warning));

      // 3. Expense tambah 160.000 (Total 910.000 = 91%) -> critical
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-3',
          type: TransactionType.expense,
          amount: 160000,
          occurredAt: nowUtc,
          walletId: 'w-main',
          categoryId: 'cat-exp-bills',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      );
      p = await budgetRepo.getBudgetProgress(monthKey);
      expect(p.status, equals(BudgetStatus.critical));

      // 4. Expense tambah 100.000 (Total 1.010.000 = 101%) -> exceeded
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-4',
          type: TransactionType.expense,
          amount: 100000,
          occurredAt: nowUtc,
          walletId: 'w-main',
          categoryId: 'cat-exp-bills',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      );
      p = await budgetRepo.getBudgetProgress(monthKey);
      expect(p.status, equals(BudgetStatus.exceeded));
      expect(p.remaining, equals(-10000));
    });

    test('Configuration warning is flagged when category limits sum exceeds total budget', () async {
      const monthKey = '2026-11';
      final nowUtc = DateTime.utc(2026, 11, 1).toIso8601String();

      // Total budget = 1.000.000, tapi category limits = 800.000 + 400.000 = 1.200.000
      await budgetRepo.saveBudget(
        budget: Budget(
          id: 'b-config-warn',
          monthKey: monthKey,
          totalLimit: 1000000,
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
        categoryLimits: [
          const BudgetCategoryLimit(
            id: 'l-1',
            budgetId: 'b-config-warn',
            categoryId: 'cat-exp-food',
            limitAmount: 800000,
          ),
          const BudgetCategoryLimit(
            id: 'l-2',
            budgetId: 'b-config-warn',
            categoryId: 'cat-exp-transport',
            limitAmount: 400000,
          ),
        ],
      );

      final progress = await budgetRepo.getBudgetProgress(monthKey);
      expect(progress.hasConfigurationWarning, isTrue);
      // Nominal budget tidak boleh diubah diam-diam
      expect(progress.totalLimit, equals(1000000));
    });

    test('Expenses in other months do not affect current month budget', () async {
      const currentMonth = '2026-11';
      final novDate = DateTime.utc(2026, 11, 10).toIso8601String();
      final octDate = DateTime.utc(2026, 10, 25).toIso8601String();
      final decDate = DateTime.utc(2026, 12, 5).toIso8601String();

      await budgetRepo.saveBudget(
        budget: Budget(
          id: 'b-nov',
          monthKey: currentMonth,
          totalLimit: 1000000,
          createdAt: novDate,
          updatedAt: novDate,
        ),
        categoryLimits: [],
      );

      // Expense bulan Oktober
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-oct',
          type: TransactionType.expense,
          amount: 500000,
          occurredAt: octDate,
          walletId: 'w-main',
          categoryId: 'cat-exp-food',
          createdAt: octDate,
          updatedAt: octDate,
        ),
      );

      // Expense bulan Desember
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-dec',
          type: TransactionType.expense,
          amount: 300000,
          occurredAt: decDate,
          walletId: 'w-main',
          categoryId: 'cat-exp-food',
          createdAt: decDate,
          updatedAt: decDate,
        ),
      );

      // Expense bulan November
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-nov',
          type: TransactionType.expense,
          amount: 250000,
          occurredAt: novDate,
          walletId: 'w-main',
          categoryId: 'cat-exp-food',
          createdAt: novDate,
          updatedAt: novDate,
        ),
      );

      final progress = await budgetRepo.getBudgetProgress(currentMonth);
      // Hanya expense bulan November (250.000) yang terhitung!
      expect(progress.totalSpent, equals(250000));
      expect(progress.remaining, equals(750000));
    });

    test('Zero or negative budget limit throws ValidationFailure', () async {
      final nowUtc = DateTime.now().toUtc().toIso8601String();

      expect(
        () => budgetRepo.saveBudget(
          budget: Budget(
            id: 'b-invalid',
            monthKey: '2026-11',
            totalLimit: 0,
            createdAt: nowUtc,
            updatedAt: nowUtc,
          ),
          categoryLimits: [],
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('Updating existing monthly budget and category limits succeeds without error', () async {
      const monthKey = '2026-11';
      final nowUtc = DateTime.now().toUtc().toIso8601String();

      // Step 1: Save budget first time without category limits
      await budgetRepo.saveBudget(
        budget: Budget(
          id: 'b-init',
          monthKey: monthKey,
          totalLimit: 3000000,
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
        categoryLimits: [],
      );

      var p = await budgetRepo.getBudgetProgress(monthKey);
      expect(p.totalLimit, equals(3000000));
      expect(p.categoryProgresses, isEmpty);

      // Step 2: Update budget to add category limits
      await budgetRepo.saveBudget(
        budget: Budget(
          id: 'b-new-id',
          monthKey: monthKey,
          totalLimit: 3500000,
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
        categoryLimits: [
          const BudgetCategoryLimit(
            id: 'bcl-1',
            budgetId: 'b-new-id',
            categoryId: 'cat-exp-food',
            limitAmount: 1500000,
          ),
        ],
      );

      p = await budgetRepo.getBudgetProgress(monthKey);
      expect(p.totalLimit, equals(3500000));
      expect(p.categoryProgresses.length, equals(1));
    });
  });
}
