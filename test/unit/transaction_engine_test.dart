import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/core/errors/failures.dart';
import 'package:myfinance/features/wallets/data/repositories/wallet_repository_impl.dart';
import 'package:myfinance/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:myfinance/features/wallets/domain/entities/wallet.dart';
import 'package:myfinance/features/transactions/domain/entities/transaction.dart';

void main() {
  late AppDatabase db;
  late WalletRepositoryImpl walletRepo;
  late TransactionRepositoryImpl transactionRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    walletRepo = WalletRepositoryImpl(db.walletsDao, db.transactionsDao);
    transactionRepo = TransactionRepositoryImpl(db.transactionsDao, db.walletsDao, db.categoriesDao);

    final now = DateTime.now().toUtc().toIso8601String();
    await walletRepo.createWallet(
      Wallet(
        id: 'w-1',
        name: 'Dompet 1',
        type: WalletType.cash,
        openingBalance: 1000000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await walletRepo.createWallet(
      Wallet(
        id: 'w-2',
        name: 'Dompet 2',
        type: WalletType.bank,
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

  group('Phase 1 - Transaction Validation & Rules Tests', () {
    test('Zero or negative amount throws ValidationFailure', () async {
      final now = DateTime.now().toUtc().toIso8601String();

      // Zero amount
      expect(
        () => transactionRepo.createTransaction(
          Transaction(
            id: 'tx-err-1',
            type: TransactionType.expense,
            amount: 0,
            occurredAt: now,
            walletId: 'w-1',
            categoryId: 'cat-exp-food',
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );

      // Negative amount
      expect(
        () => transactionRepo.createTransaction(
          Transaction(
            id: 'tx-err-2',
            type: TransactionType.income,
            amount: -50000,
            occurredAt: now,
            walletId: 'w-1',
            categoryId: 'cat-inc-salary',
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('Transfer requires destinationWalletId and cannot be the same as source wallet', () async {
      final now = DateTime.now().toUtc().toIso8601String();

      // Destination is null
      expect(
        () => transactionRepo.createTransaction(
          Transaction(
            id: 'tx-tr-err-1',
            type: TransactionType.transfer,
            amount: 100000,
            occurredAt: now,
            walletId: 'w-1',
            destinationWalletId: null,
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );

      // Destination is same as source
      expect(
        () => transactionRepo.createTransaction(
          Transaction(
            id: 'tx-tr-err-2',
            type: TransactionType.transfer,
            amount: 100000,
            occurredAt: now,
            walletId: 'w-1',
            destinationWalletId: 'w-1',
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('Expense and Income require valid categoryId', () async {
      final now = DateTime.now().toUtc().toIso8601String();

      // Null category
      expect(
        () => transactionRepo.createTransaction(
          Transaction(
            id: 'tx-exp-err-1',
            type: TransactionType.expense,
            amount: 50000,
            occurredAt: now,
            walletId: 'w-1',
            categoryId: null,
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );

      // Non-existent category
      expect(
        () => transactionRepo.createTransaction(
          Transaction(
            id: 'tx-exp-err-2',
            type: TransactionType.income,
            amount: 50000,
            occurredAt: now,
            walletId: 'w-1',
            categoryId: 'non-existent-cat',
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('Non-existent source wallet throws ValidationFailure', () async {
      final now = DateTime.now().toUtc().toIso8601String();

      expect(
        () => transactionRepo.createTransaction(
          Transaction(
            id: 'tx-err-no-wallet',
            type: TransactionType.expense,
            amount: 50000,
            occurredAt: now,
            walletId: 'fake-wallet-id',
            categoryId: 'cat-exp-food',
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
