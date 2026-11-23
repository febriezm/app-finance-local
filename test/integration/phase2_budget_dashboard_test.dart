import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/core/formatting/date_formatter.dart';
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

    // 1. Setup initial wallets
    await walletRepo.createWallet(
      Wallet(
        id: 'w-bank',
        name: 'Bank BCA',
        type: WalletType.bank,
        openingBalance: 10000000, // 10 Jt
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await walletRepo.createWallet(
      Wallet(
        id: 'w-cash',
        name: 'Dompet Tunai',
        type: WalletType.cash,
        openingBalance: 1000000, // 1 Jt
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 2 Integration Test - Budget, Dashboard & Report Lifecycle', () {
    test('End-to-end: Set budget -> record expenses -> category limits -> income/transfer isolation -> void update', () async {
      final currentMonthKey = AppDateFormatter.toMonthKey(DateTime.now());
      final nowUtc = DateTime.now().toUtc().toIso8601String();

      // 1. Simpan Budget Bulanan: Total 5 Jt, Kategori Makanan 2 Jt, Transportasi 1 Jt
      await budgetRepo.saveBudget(
        budget: Budget(
          id: 'b-curr-month',
          monthKey: currentMonthKey,
          totalLimit: 5000000,
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
        categoryLimits: [
          const BudgetCategoryLimit(
            id: 'bcl-food',
            budgetId: 'b-curr-month',
            categoryId: 'cat-exp-food',
            limitAmount: 2000000,
          ),
          const BudgetCategoryLimit(
            id: 'bcl-trans',
            budgetId: 'b-curr-month',
            categoryId: 'cat-exp-transport',
            limitAmount: 1000000,
          ),
        ],
      );

      // Verifikasi initial progress
      var progress = await budgetRepo.getBudgetProgress(currentMonthKey);
      expect(progress.hasBudget, isTrue);
      expect(progress.totalLimit, equals(5000000));
      expect(progress.totalSpent, equals(0));
      expect(progress.remaining, equals(5000000));
      expect(progress.status, equals(BudgetStatus.normal));
      expect(progress.hasConfigurationWarning, isFalse);

      // 2. Catat Expense Makanan Rp 500.000
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-food-1',
          type: TransactionType.expense,
          amount: 500000,
          occurredAt: nowUtc,
          walletId: 'w-bank',
          categoryId: 'cat-exp-food',
          description: 'Makan siang resto',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      );

      progress = await budgetRepo.getBudgetProgress(currentMonthKey);
      expect(progress.totalSpent, equals(500000));
      expect(progress.remaining, equals(4500000));
      final foodProgress = progress.categoryProgresses.firstWhere((c) => c.category.id == 'cat-exp-food');
      expect(foodProgress.spentAmount, equals(500000));
      expect(foodProgress.remainingAmount, equals(1500000));
      expect(foodProgress.percentage, closeTo(0.25, 0.001));
      expect(foodProgress.status, equals(BudgetStatus.normal));

      // 3. Catat Expense Transportasi Rp 1.200.000 (Melebihi limit transport 1 Jt)
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-trans-1',
          type: TransactionType.expense,
          amount: 1200000,
          occurredAt: nowUtc,
          walletId: 'w-bank',
          categoryId: 'cat-exp-transport',
          description: 'Servis mobil berkala',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      );

      progress = await budgetRepo.getBudgetProgress(currentMonthKey);
      expect(progress.totalSpent, equals(1700000));
      expect(progress.remaining, equals(3300000));
      final transProgress = progress.categoryProgresses.firstWhere((c) => c.category.id == 'cat-exp-transport');
      expect(transProgress.spentAmount, equals(1200000));
      expect(transProgress.remainingAmount, equals(-200000));
      expect(transProgress.percentage, closeTo(1.2, 0.001));
      expect(transProgress.status, equals(BudgetStatus.exceeded));

      // 4. Catat Pemasukan Rp 4.000.000 -> Budget TIDAK boleh berkurang atau bertambah
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-income-1',
          type: TransactionType.income,
          amount: 4000000,
          occurredAt: nowUtc,
          walletId: 'w-bank',
          categoryId: 'cat-inc-salary',
          description: 'Gaji bulanan',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      );

      progress = await budgetRepo.getBudgetProgress(currentMonthKey);
      expect(progress.totalSpent, equals(1700000));
      expect(progress.remaining, equals(3300000));

      // 5. Transfer Rp 1.000.000 antar wallet -> Budget TIDAK boleh terpengaruh
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-transfer-1',
          type: TransactionType.transfer,
          amount: 1000000,
          occurredAt: nowUtc,
          walletId: 'w-bank',
          destinationWalletId: 'w-cash',
          description: 'Tarik tunai ATM',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      );

      progress = await budgetRepo.getBudgetProgress(currentMonthKey);
      expect(progress.totalSpent, equals(1700000));
      expect(progress.remaining, equals(3300000));

      // 6. Verifikasi Saldo & Mutasi Wallet
      final bankBalance = await walletRepo.calculateWalletBalance('w-bank');
      // Opening 10 Jt - 500k (expense) - 1.2 Jt (expense) + 4 Jt (income) - 1 Jt (transfer out) = 11.3 Jt
      expect(bankBalance, equals(11300000));

      final cashBalance = await walletRepo.calculateWalletBalance('w-cash');
      // Opening 1 Jt + 1 Jt (transfer in) = 2 Jt
      expect(cashBalance, equals(2000000));

      // Total aset bersih = 11.3 Jt + 2 Jt = 13.3 Jt
      final allWallets = await walletRepo.getActiveWalletsWithBalance();
      final totalAssets = allWallets.fold<int>(0, (sum, w) => sum + w.currentBalance);
      expect(totalAssets, equals(13300000));

      // 7. Verifikasi Monthly Income & Expense
      final now = DateTime.now();
      final monthlyIncome = await transactionRepo.getMonthlyIncome(now.year, now.month);
      final monthlyExpense = await transactionRepo.getMonthlyExpense(now.year, now.month);
      expect(monthlyIncome, equals(4000000));
      expect(monthlyExpense, equals(1700000));

      // 8. Void transaksi servis mobil (Transportasi Rp 1.200.000)
      await transactionRepo.voidTransaction('tx-trans-1');

      // Verifikasi budget pulih setelah void
      progress = await budgetRepo.getBudgetProgress(currentMonthKey);
      expect(progress.totalSpent, equals(500000));
      expect(progress.remaining, equals(4500000));
      final restoredTrans = progress.categoryProgresses.firstWhere((c) => c.category.id == 'cat-exp-transport');
      expect(restoredTrans.spentAmount, equals(0));
      expect(restoredTrans.remainingAmount, equals(1000000));
      expect(restoredTrans.status, equals(BudgetStatus.normal));

      // Verifikasi monthly expense berkurang
      final updatedMonthlyExpense = await transactionRepo.getMonthlyExpense(now.year, now.month);
      expect(updatedMonthlyExpense, equals(500000));

      // Verifikasi saldo bank bertambah kembali Rp 1.200.000
      final updatedBankBalance = await walletRepo.calculateWalletBalance('w-bank');
      expect(updatedBankBalance, equals(12500000));

      // 9. Update budget yang sudah ada (tambah kategori hiburan & naikkan limit)
      await budgetRepo.saveBudget(
        budget: Budget(
          id: 'b-curr-month-updated',
          monthKey: currentMonthKey,
          totalLimit: 6000000, // Dari 5 Jt naik ke 6 Jt
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
        categoryLimits: [
          const BudgetCategoryLimit(
            id: 'bcl-food-updated',
            budgetId: 'b-curr-month-updated',
            categoryId: 'cat-exp-food',
            limitAmount: 2500000,
          ),
          const BudgetCategoryLimit(
            id: 'bcl-trans-updated',
            budgetId: 'b-curr-month-updated',
            categoryId: 'cat-exp-transport',
            limitAmount: 1500000,
          ),
          const BudgetCategoryLimit(
            id: 'bcl-ent-new',
            budgetId: 'b-curr-month-updated',
            categoryId: 'cat-exp-entertainment',
            limitAmount: 1000000,
          ),
        ],
      );

      final updatedProgress = await budgetRepo.getBudgetProgress(currentMonthKey);
      expect(updatedProgress.totalLimit, equals(6000000));
      expect(updatedProgress.totalSpent, equals(500000)); // Expense Makanan 500k tetap
      expect(updatedProgress.remaining, equals(5500000));
      expect(updatedProgress.categoryProgresses.length, equals(3));
    });
  });
}
