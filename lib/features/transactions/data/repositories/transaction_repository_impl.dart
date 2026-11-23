import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/transactions_dao.dart';
import '../../../../core/database/daos/wallets_dao.dart';
import '../../../../core/database/daos/categories_dao.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_with_details.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../../../wallets/domain/entities/wallet.dart';
import '../../../wallets/data/models/wallet_model.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/data/models/category_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionsDao _transactionsDao;
  final WalletsDao _walletsDao;
  final CategoriesDao _categoriesDao;

  TransactionRepositoryImpl(
    this._transactionsDao,
    this._walletsDao,
    this._categoriesDao,
  );

  Future<TransactionWithDetails> _enrich(TransactionEntry entry) async {
    final tx = TransactionModel.fromEntry(entry);
    Wallet? wallet;
    Wallet? destWallet;
    Category? category;

    if (entry.walletId != null) {
      final w = await _walletsDao.getWalletById(entry.walletId!);
      if (w != null) wallet = WalletModel.fromEntry(w);
    }

    if (entry.destinationWalletId != null) {
      final dw = await _walletsDao.getWalletById(entry.destinationWalletId!);
      if (dw != null) destWallet = WalletModel.fromEntry(dw);
    }

    if (entry.categoryId != null) {
      final c = await _categoriesDao.getCategoryById(entry.categoryId!);
      if (c != null) category = CategoryModel.fromEntry(c);
    }

    return TransactionWithDetails(
      transaction: tx,
      wallet: wallet,
      destinationWallet: destWallet,
      category: category,
    );
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    final entry = await _transactionsDao.getTransactionById(id);
    return entry != null ? TransactionModel.fromEntry(entry) : null;
  }

  @override
  Future<TransactionWithDetails?> getTransactionWithDetailsById(String id) async {
    final entry = await _transactionsDao.getTransactionById(id);
    if (entry == null) return null;
    return _enrich(entry);
  }

  @override
  Future<List<TransactionWithDetails>> getRecentTransactions({int limit = 20}) async {
    final entries = await _transactionsDao.watchRecentTransactions(limit: limit).first;
    return Future.wait(entries.map(_enrich));
  }

  @override
  Stream<List<TransactionWithDetails>> watchRecentTransactions({int limit = 20}) {
    return _transactionsDao.watchRecentTransactions(limit: limit).asyncMap(
          (entries) => Future.wait(entries.map(_enrich)),
        );
  }

  @override
  Future<List<TransactionWithDetails>> getTransactionsForWallet(String walletId) async {
    final entries = await _transactionsDao.getConfirmedLedgerForWallet(walletId);
    return Future.wait(entries.map(_enrich));
  }

  @override
  Stream<List<TransactionWithDetails>> watchTransactionsForWallet(String walletId) {
    return _transactionsDao.watchConfirmedLedgerForWallet(walletId).asyncMap(
          (entries) => Future.wait(entries.map(_enrich)),
        );
  }

  @override
  Future<List<TransactionWithDetails>> getTransactionsInDateRange(
    DateTime start,
    DateTime end, {
    TransactionType? filterType,
  }) async {
    final startIso = start.toUtc().toIso8601String();
    final endIso = end.toUtc().toIso8601String();

    List<TransactionEntry> entries;
    if (filterType == TransactionType.expense) {
      entries = await _transactionsDao.getConfirmedExpensesInDateRange(startIso, endIso);
    } else if (filterType == TransactionType.income) {
      entries = await _transactionsDao.getConfirmedIncomesInDateRange(startIso, endIso);
    } else {
      // Ambil transaksi confirmed lalu filter di memori
      final allRecent = await _transactionsDao.watchRecentTransactions(limit: 500).first;
      entries = allRecent.where((t) {
        return t.occurredAt.compareTo(startIso) >= 0 && t.occurredAt.compareTo(endIso) <= 0;
      }).toList();
    }

    return Future.wait(entries.map(_enrich));
  }

  @override
  Future<void> createTransaction(Transaction transaction) async {
    // 1. Validasi nominal
    if (transaction.amount <= 0) {
      throw const ValidationFailure('Nominal transaksi harus lebih dari 0.');
    }

    // 2. Validasi wallet asal
    if (transaction.walletId == null || transaction.walletId!.trim().isEmpty) {
      throw const ValidationFailure('Dompet sumber wajib dipilih.');
    }
    final sourceWallet = await _walletsDao.getWalletById(transaction.walletId!);
    if (sourceWallet == null) {
      throw const ValidationFailure('Dompet sumber tidak ditemukan.');
    }

    // 3. Validasi berdasarkan jenis
    if (transaction.type == TransactionType.income || transaction.type == TransactionType.expense) {
      if (transaction.categoryId == null || transaction.categoryId!.trim().isEmpty) {
        throw const ValidationFailure('Kategori transaksi wajib dipilih.');
      }
      final category = await _categoriesDao.getCategoryById(transaction.categoryId!);
      if (category == null) {
        throw const ValidationFailure('Kategori transaksi tidak ditemukan.');
      }
    } else if (transaction.type == TransactionType.transfer) {
      if (transaction.destinationWalletId != null &&
          transaction.destinationWalletId!.trim().isNotEmpty) {
        if (transaction.destinationWalletId == transaction.walletId) {
          throw const ValidationFailure('Dompet sumber dan dompet tujuan tidak boleh sama.');
        }
        final destWallet = await _walletsDao.getWalletById(transaction.destinationWalletId!);
        if (destWallet == null) {
          throw const ValidationFailure('Dompet tujuan transfer tidak ditemukan.');
        }
      } else {
        // Transfer eksternal (ke bank / e-wallet / orang lain)
        final target = (transaction.merchant?.trim().isNotEmpty == true)
            ? transaction.merchant!.trim()
            : transaction.description?.trim();
        if (target == null || target.isEmpty) {
          throw const ValidationFailure('Tujuan transfer (nama penerima / bank / e-wallet) wajib diisi.');
        }
      }
    }

    // 4. Simpan ke database
    await _transactionsDao.insertTransaction(
      TransactionsTableCompanion.insert(
        id: transaction.id,
        type: transaction.type.toDbString(),
        amount: transaction.amount,
        occurredAt: transaction.occurredAt,
        walletId: Value(transaction.walletId),
        destinationWalletId: Value(transaction.destinationWalletId),
        categoryId: Value(transaction.categoryId),
        merchant: Value(transaction.merchant),
        description: Value(transaction.description),
        notes: Value(transaction.notes),
        source: Value(transaction.source),
        status: Value(transaction.status.toDbString()),
        createdAt: transaction.createdAt,
        updatedAt: transaction.updatedAt,
      ),
    );
  }

  @override
  Future<void> voidTransaction(String id) async {
    final existing = await _transactionsDao.getTransactionById(id);
    if (existing == null) {
      throw const NotFoundFailure('Transaksi tidak ditemukan.');
    }
    await _transactionsDao.voidTransaction(id, DateTime.now().toUtc().toIso8601String());
  }

  @override
  Future<int> getMonthlyIncome(int year, int month) async {
    final start = DateTime(year, month, 1).toUtc().toIso8601String();
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999).toUtc().toIso8601String();

    final entries = await _transactionsDao.getConfirmedIncomesInDateRange(start, end);
    int total = 0;
    for (final e in entries) {
      total += e.amount;
    }
    return total;
  }

  @override
  Stream<int> watchMonthlyIncome(int year, int month) {
    final start = DateTime(year, month, 1).toUtc().toIso8601String();
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999).toUtc().toIso8601String();

    return _transactionsDao.watchConfirmedIncomesInDateRange(start, end).map((entries) {
      int total = 0;
      for (final e in entries) {
        total += e.amount;
      }
      return total;
    });
  }

  @override
  Future<int> getMonthlyExpense(int year, int month) async {
    final start = DateTime(year, month, 1).toUtc().toIso8601String();
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999).toUtc().toIso8601String();

    final entries = await _transactionsDao.getConfirmedExpensesInDateRange(start, end);
    int total = 0;
    for (final e in entries) {
      total += e.amount;
    }
    return total;
  }

  @override
  Stream<int> watchMonthlyExpense(int year, int month) {
    final start = DateTime(year, month, 1).toUtc().toIso8601String();
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999).toUtc().toIso8601String();

    return _transactionsDao.watchConfirmedExpensesInDateRange(start, end).map((entries) {
      int total = 0;
      for (final e in entries) {
        total += e.amount;
      }
      return total;
    });
  }
}
