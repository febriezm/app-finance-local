import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift SQLite Schema v1 Tests', () {
    test('Database initializes with seeded system categories', () async {
      final categories = await db.categoriesDao.getAllActiveCategories();
      expect(categories.length, equals(11));

      final incomeCats = categories.where((c) => c.type == 'income').toList();
      final expenseCats = categories.where((c) => c.type == 'expense').toList();

      expect(incomeCats.length, equals(4));
      expect(expenseCats.length, equals(7));

      // Verifikasi category system
      expect(incomeCats.every((c) => c.isSystem), isTrue);
      expect(expenseCats.every((c) => c.isSystem), isTrue);
    });

    test('Wallet CRUD operations and soft-delete archive work as expected', () async {
      final now = DateTime.now().toUtc().toIso8601String();

      // Insert wallet
      await db.walletsDao.insertWallet(
        WalletsTableCompanion.insert(
          id: 'wallet-1',
          name: 'BCA Utama',
          type: 'bank',
          openingBalance: 5000000,
          openingDate: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final activeWallets = await db.walletsDao.getActiveWallets();
      expect(activeWallets.length, equals(1));
      expect(activeWallets.first.name, equals('BCA Utama'));
      expect(activeWallets.first.openingBalance, equals(5000000));

      // Archive wallet (soft delete)
      await db.walletsDao.archiveWallet('wallet-1');

      final activeAfterArchive = await db.walletsDao.getActiveWallets();
      expect(activeAfterArchive.isEmpty, isTrue);

      final archivedWallet = await db.walletsDao.getWalletById('wallet-1');
      expect(archivedWallet, isNotNull);
      expect(archivedWallet!.isArchived, isTrue);
    });

    test('Foreign key enforcement blocks invalid transaction wallet references', () async {
      final now = DateTime.now().toUtc().toIso8601String();

      // Insert transaction with non-existent wallet_id -> must fail
      expect(
        () async => await db.transactionsDao.insertTransaction(
          TransactionsTableCompanion.insert(
            id: 'tx-invalid-1',
            type: 'expense',
            amount: 50000,
            occurredAt: now,
            walletId: const drift.Value('wallet-does-not-exist'),
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('Budget unique month_key constraint blocks duplicate budgets', () async {
      final now = DateTime.now().toUtc().toIso8601String();

      await db.budgetsDao.insertBudget(
        BudgetsTableCompanion.insert(
          id: 'budget-2026-11',
          monthKey: '2026-11',
          totalLimit: 10000000,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Duplicate month_key must throw exception
      expect(
        () async => await db.budgetsDao.insertBudget(
          BudgetsTableCompanion.insert(
            id: 'budget-duplicate',
            monthKey: '2026-11',
            totalLimit: 8000000,
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('Transaction voiding updates status without deleting row', () async {
      final now = DateTime.now().toUtc().toIso8601String();

      // Create valid wallet
      await db.walletsDao.insertWallet(
        WalletsTableCompanion.insert(
          id: 'wallet-cash',
          name: 'Dompet Tunai',
          type: 'cash',
          openingBalance: 1000000,
          openingDate: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Create transaction
      await db.transactionsDao.insertTransaction(
        TransactionsTableCompanion.insert(
          id: 'tx-1',
          type: 'expense',
          amount: 25000,
          occurredAt: now,
          walletId: const drift.Value('wallet-cash'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Void the transaction
      await db.transactionsDao.voidTransaction('tx-1', now);

      final tx = await db.transactionsDao.getTransactionById('tx-1');
      expect(tx, isNotNull);
      expect(tx!.status, equals('voided'));

      // Ledger query excludes voided transactions
      final ledger = await db.transactionsDao.getConfirmedLedgerForWallet('wallet-cash');
      expect(ledger.isEmpty, isTrue);
    });
  });
}
