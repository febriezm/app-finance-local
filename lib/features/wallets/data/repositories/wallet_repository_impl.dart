import 'dart:async';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/wallets_dao.dart';
import '../../../../core/database/daos/transactions_dao.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../models/wallet_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletsDao _walletsDao;
  final TransactionsDao _transactionsDao;

  WalletRepositoryImpl(this._walletsDao, this._transactionsDao);

  @override
  Future<List<Wallet>> getActiveWallets() async {
    final entries = await _walletsDao.getActiveWallets();
    return entries.map(WalletModel.fromEntry).toList();
  }

  @override
  Stream<List<Wallet>> watchActiveWallets() {
    return _walletsDao.watchActiveWallets().map(
          (entries) => entries.map(WalletModel.fromEntry).toList(),
        );
  }

  @override
  Future<int> calculateWalletBalance(String walletId) async {
    final walletEntry = await _walletsDao.getWalletById(walletId);
    if (walletEntry == null) return 0;

    int balance = walletEntry.openingBalance;
    final ledger = await _transactionsDao.getConfirmedLedgerForWallet(walletId);

    for (final tx in ledger) {
      if (tx.status != 'confirmed') continue;

      if (tx.type == 'income' && tx.walletId == walletId) {
        balance += tx.amount;
      } else if (tx.type == 'expense' && tx.walletId == walletId) {
        balance -= tx.amount;
      } else if (tx.type == 'transfer') {
        if (tx.destinationWalletId == walletId) {
          balance += tx.amount;
        }
        if (tx.walletId == walletId) {
          balance -= tx.amount;
        }
      }
    }

    return balance;
  }

  @override
  Future<List<WalletWithBalance>> getActiveWalletsWithBalance() async {
    final wallets = await getActiveWallets();
    final result = <WalletWithBalance>[];

    for (final wallet in wallets) {
      final balance = await calculateWalletBalance(wallet.id);
      result.add(WalletWithBalance(wallet: wallet, currentBalance: balance));
    }

    return result;
  }

  @override
  Stream<List<WalletWithBalance>> watchActiveWalletsWithBalance() {
    late StreamController<List<WalletWithBalance>> controller;
    StreamSubscription? subWallets;
    StreamSubscription? subTransactions;

    void refresh() async {
      try {
        final data = await getActiveWalletsWithBalance();
        if (!controller.isClosed) {
          controller.add(data);
        }
      } catch (e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
        }
      }
    }

    controller = StreamController<List<WalletWithBalance>>(
      onListen: () {
        refresh();
        subWallets = _walletsDao.watchActiveWallets().listen((_) => refresh());
        subTransactions = _transactionsDao.watchRecentTransactions(limit: 1).listen((_) => refresh());
      },
      onCancel: () {
        subWallets?.cancel();
        subTransactions?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  @override
  Future<int> calculateTotalAssetBalance() async {
    final walletsWithBalance = await getActiveWalletsWithBalance();
    int total = 0;
    for (final item in walletsWithBalance) {
      total += item.currentBalance;
    }
    return total;
  }

  @override
  Future<Wallet?> getWalletById(String id) async {
    final entry = await _walletsDao.getWalletById(id);
    return entry != null ? WalletModel.fromEntry(entry) : null;
  }

  @override
  Future<void> createWallet(Wallet wallet) async {
    await _walletsDao.insertWallet(
      WalletsTableCompanion.insert(
        id: wallet.id,
        name: wallet.name,
        type: wallet.type.toDbString(),
        openingBalance: wallet.openingBalance,
        openingDate: wallet.openingDate,
        currencyCode: Value(wallet.currencyCode),
        iconKey: Value(wallet.iconKey),
        colorHex: Value(wallet.colorHex),
        isArchived: Value(wallet.isArchived),
        createdAt: wallet.createdAt,
        updatedAt: wallet.updatedAt,
      ),
    );
  }

  @override
  Future<void> updateWallet(Wallet wallet) async {
    await _walletsDao.updateWallet(
      WalletsTableCompanion(
        id: Value(wallet.id),
        name: Value(wallet.name),
        type: Value(wallet.type.toDbString()),
        openingBalance: Value(wallet.openingBalance),
        openingDate: Value(wallet.openingDate),
        currencyCode: Value(wallet.currencyCode),
        iconKey: Value(wallet.iconKey),
        colorHex: Value(wallet.colorHex),
        isArchived: Value(wallet.isArchived),
        createdAt: Value(wallet.createdAt),
        updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
      ),
    );
  }

  @override
  Future<void> archiveWallet(String id) async {
    await _walletsDao.archiveWallet(id);
  }

  @override
  Future<void> unarchiveWallet(String id) async {
    await _walletsDao.unarchiveWallet(id);
  }

  @override
  Future<List<WalletWithBalance>> getArchivedWalletsWithBalance() async {
    final entries = await _walletsDao.getArchivedWallets();
    final wallets = entries.map(WalletModel.fromEntry).toList();
    final result = <WalletWithBalance>[];

    for (final wallet in wallets) {
      final balance = await calculateWalletBalance(wallet.id);
      result.add(WalletWithBalance(wallet: wallet, currentBalance: balance));
    }

    return result;
  }

  @override
  Stream<List<WalletWithBalance>> watchArchivedWalletsWithBalance() {
    late StreamController<List<WalletWithBalance>> controller;
    StreamSubscription? subWallets;
    StreamSubscription? subTransactions;

    void refresh() async {
      try {
        final data = await getArchivedWalletsWithBalance();
        if (!controller.isClosed) {
          controller.add(data);
        }
      } catch (e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
        }
      }
    }

    controller = StreamController<List<WalletWithBalance>>(
      onListen: () {
        refresh();
        subWallets = _walletsDao.watchArchivedWallets().listen((_) => refresh());
        subTransactions = _transactionsDao.watchRecentTransactions(limit: 1).listen((_) => refresh());
      },
      onCancel: () {
        subWallets?.cancel();
        subTransactions?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }
}
