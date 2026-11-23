import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/features/wallets/data/repositories/wallet_repository_impl.dart';
import 'package:myfinance/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:myfinance/features/wallets/domain/entities/wallet.dart';
import 'package:myfinance/features/transactions/domain/entities/transaction.dart';

void main() {
  late AppDatabase db;
  late WalletRepositoryImpl walletRepo;
  late TransactionRepositoryImpl transactionRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    walletRepo = WalletRepositoryImpl(db.walletsDao, db.transactionsDao);
    transactionRepo = TransactionRepositoryImpl(db.transactionsDao, db.walletsDao, db.categoriesDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 1 - Wallet & Ledger Balance Engine Tests', () {
    test('Formula: balance = opening + income + transfer_in - expense - transfer_out', () async {
      final now = DateTime.now().toUtc().toIso8601String();

      // Buat Wallet A (BCA) dengan opening balance Rp 1.000.000
      final walletA = Wallet(
        id: 'w-bca',
        name: 'BCA',
        type: WalletType.bank,
        openingBalance: 1000000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      );
      await walletRepo.createWallet(walletA);

      // Buat Wallet B (Dompet Tunai) dengan opening balance Rp 200.000
      final walletB = Wallet(
        id: 'w-cash',
        name: 'Dompet Tunai',
        type: WalletType.cash,
        openingBalance: 200000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      );
      await walletRepo.createWallet(walletB);

      // Verifikasi initial balance
      expect(await walletRepo.calculateWalletBalance('w-bca'), equals(1000000));
      expect(await walletRepo.calculateWalletBalance('w-cash'), equals(200000));
      expect(await walletRepo.calculateTotalAssetBalance(), equals(1200000));

      // 1. Income: Gaji Rp 5.000.000 masuk ke BCA
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-1',
          type: TransactionType.income,
          amount: 5000000,
          occurredAt: now,
          walletId: 'w-bca',
          categoryId: 'cat-inc-salary',
          createdAt: now,
          updatedAt: now,
        ),
      );
      // Saldo BCA = 1.000.000 + 5.000.000 = 6.000.000
      expect(await walletRepo.calculateWalletBalance('w-bca'), equals(6000000));

      // 2. Expense: Makan siang Rp 50.000 dari Dompet Tunai
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-2',
          type: TransactionType.expense,
          amount: 50000,
          occurredAt: now,
          walletId: 'w-cash',
          categoryId: 'cat-exp-food',
          createdAt: now,
          updatedAt: now,
        ),
      );
      // Saldo Cash = 200.000 - 50.000 = 150.000
      expect(await walletRepo.calculateWalletBalance('w-cash'), equals(150000));

      // 3. Transfer: Tarik tunai dari BCA ke Cash Rp 500.000
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-3',
          type: TransactionType.transfer,
          amount: 500000,
          occurredAt: now,
          walletId: 'w-bca',
          destinationWalletId: 'w-cash',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Saldo BCA = 6.000.000 - 500.000 = 5.500.000
      expect(await walletRepo.calculateWalletBalance('w-bca'), equals(5500000));
      // Saldo Cash = 150.000 + 500.000 = 650.000
      expect(await walletRepo.calculateWalletBalance('w-cash'), equals(650000));

      // Total Aset = 5.500.000 + 650.000 = 6.150.000
      // Pembuktian: Opening total (1.200.000) + Income (5.000.000) - Expense (50.000) = 6.150.000
      expect(await walletRepo.calculateTotalAssetBalance(), equals(6150000));
    });

    test('Internal transfer invariance: transfer does not change total assets or income/expense', () async {
      final now = DateTime.now().toUtc().toIso8601String();

      final w1 = Wallet(
        id: 'w1',
        name: 'Bank Jago',
        type: WalletType.bank,
        openingBalance: 2000000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final w2 = Wallet(
        id: 'w2',
        name: 'GoPay',
        type: WalletType.eWallet,
        openingBalance: 300000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      );
      await walletRepo.createWallet(w1);
      await walletRepo.createWallet(w2);

      final initialTotal = await walletRepo.calculateTotalAssetBalance();
      expect(initialTotal, equals(2300000));

      // Transfer Rp 100.000 from Bank Jago to GoPay
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-tr-1',
          type: TransactionType.transfer,
          amount: 100000,
          occurredAt: now,
          walletId: 'w1',
          destinationWalletId: 'w2',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Verify each wallet balance
      expect(await walletRepo.calculateWalletBalance('w1'), equals(1900000));
      expect(await walletRepo.calculateWalletBalance('w2'), equals(400000));

      // Total assets MUST stay identical (invariance)
      final afterTotal = await walletRepo.calculateTotalAssetBalance();
      expect(afterTotal, equals(2300000));

      // Monthly income and expense must NOT count transfer
      final date = DateTime.parse(now);
      expect(await transactionRepo.getMonthlyIncome(date.year, date.month), equals(0));
      expect(await transactionRepo.getMonthlyExpense(date.year, date.month), equals(0));
    });

    test('Voided transactions are ignored in wallet balance', () async {
      final now = DateTime.now().toUtc().toIso8601String();

      final w = Wallet(
        id: 'w-void-test',
        name: 'Test Wallet',
        type: WalletType.bank,
        openingBalance: 1000000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      );
      await walletRepo.createWallet(w);

      // Buat transaksi expense Rp 300.000
      await transactionRepo.createTransaction(
        Transaction(
          id: 'tx-to-void',
          type: TransactionType.expense,
          amount: 300000,
          occurredAt: now,
          walletId: 'w-void-test',
          categoryId: 'cat-exp-food',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Sebelum void: saldo = 700.000
      expect(await walletRepo.calculateWalletBalance('w-void-test'), equals(700000));

      // Void transaksi
      await transactionRepo.voidTransaction('tx-to-void');

      // Setelah void: saldo kembali ke 1.000.000
      expect(await walletRepo.calculateWalletBalance('w-void-test'), equals(1000000));
    });

    test('Archive wallet hides wallet from active list without deleting ledger', () async {
      final now = DateTime.now().toUtc().toIso8601String();

      final w = Wallet(
        id: 'w-archived',
        name: 'Old Bank',
        type: WalletType.bank,
        openingBalance: 500000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      );
      await walletRepo.createWallet(w);

      expect((await walletRepo.getActiveWallets()).length, equals(1));

      await walletRepo.archiveWallet('w-archived');

      // Sekarang tidak muncul di active wallets
      expect((await walletRepo.getActiveWallets()).length, equals(0));

      // Tapi data wallet masih ada
      final fetched = await walletRepo.getWalletById('w-archived');
      expect(fetched, isNotNull);
      expect(fetched!.isArchived, isTrue);
    });

    test('Unarchive wallet restores wallet to active list and preserves ledger balance', () async {
      final now = DateTime.now().toUtc().toIso8601String();

      final w = Wallet(
        id: 'w-restore-test',
        name: 'Savings Reserve',
        type: WalletType.bank,
        openingBalance: 750000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      );
      await walletRepo.createWallet(w);
      await walletRepo.archiveWallet('w-restore-test');

      final archivedList = await walletRepo.getArchivedWalletsWithBalance();
      expect(archivedList.any((item) => item.wallet.id == 'w-restore-test'), isTrue);
      expect((await walletRepo.getActiveWallets()).any((w) => w.id == 'w-restore-test'), isFalse);

      // Unarchive
      await walletRepo.unarchiveWallet('w-restore-test');
      expect((await walletRepo.getActiveWallets()).any((w) => w.id == 'w-restore-test'), isTrue);
      expect((await walletRepo.getArchivedWalletsWithBalance()).any((item) => item.wallet.id == 'w-restore-test'), isFalse);
      expect(await walletRepo.calculateWalletBalance('w-restore-test'), equals(750000));
    });
  });
}
