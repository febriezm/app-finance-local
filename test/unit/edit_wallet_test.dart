import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/features/wallets/data/repositories/wallet_repository_impl.dart';
import 'package:myfinance/features/wallets/domain/entities/wallet.dart';
import 'package:myfinance/features/wallets/presentation/controllers/wallets_controller.dart';

void main() {
  group('Edit Wallet Regression & Lifecycle Tests', () {
    late AppDatabase db;
    late WalletRepositoryImpl repo;
    late WalletsController controller;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = WalletRepositoryImpl(db.walletsDao, db.transactionsDao);
      controller = WalletsController(repo);
    });

    tearDown(() async {
      await db.close();
    });

    test('updateWallet successfully updates wallet in database without throwing Drift exception', () async {
      const originalCreatedAt = '2026-01-01T10:00:00.000Z';
      const originalOpeningDate = '2026-01-01T10:00:00.000Z';

      const wallet1 = Wallet(
        id: 'wallet-bca',
        name: 'BCA Tabungan',
        type: WalletType.bank,
        openingBalance: 2500000,
        openingDate: originalOpeningDate,
        currencyCode: 'IDR',
        iconKey: 'bank',
        colorHex: '0xFF2ED573',
        isArchived: false,
        createdAt: originalCreatedAt,
        updatedAt: originalCreatedAt,
      );

      const wallet2 = Wallet(
        id: 'wallet-cash',
        name: 'Dompet Tunai',
        type: WalletType.cash,
        openingBalance: 150000,
        openingDate: originalOpeningDate,
        currencyCode: 'IDR',
        iconKey: 'cash',
        colorHex: '0xFF0E7A4A',
        isArchived: false,
        createdAt: originalCreatedAt,
        updatedAt: originalCreatedAt,
      );

      await repo.createWallet(wallet1);
      await repo.createWallet(wallet2);

      // Perform update on wallet 1 via controller
      final success = await controller.updateWallet(
        id: 'wallet-bca',
        name: 'BCA Utama Prioritas',
        type: WalletType.other,
        openingBalance: wallet1.openingBalance,
        iconKey: 'wallet',
        colorHex: '0xFF9B59B6',
        isArchived: false,
        openingDate: wallet1.openingDate,
        currencyCode: wallet1.currencyCode,
        createdAt: wallet1.createdAt,
      );

      expect(success, isTrue);

      // Verify wallet 1 was correctly updated in database
      final updatedDbWallet1 = await db.walletsDao.getWalletById('wallet-bca');
      expect(updatedDbWallet1, isNotNull);
      expect(updatedDbWallet1!.name, 'BCA Utama Prioritas');
      expect(updatedDbWallet1.type, 'other');
      expect(updatedDbWallet1.colorHex, '0xFF9B59B6');
      expect(updatedDbWallet1.iconKey, 'wallet');
      expect(updatedDbWallet1.openingBalance, 2500000);
      expect(updatedDbWallet1.createdAt, originalCreatedAt);

      // Verify wallet 2 was not modified (isolation check)
      final untouchedDbWallet2 = await db.walletsDao.getWalletById('wallet-cash');
      expect(untouchedDbWallet2, isNotNull);
      expect(untouchedDbWallet2!.name, 'Dompet Tunai');
      expect(untouchedDbWallet2.type, 'cash');
      expect(untouchedDbWallet2.colorHex, '0xFF0E7A4A');
      expect(untouchedDbWallet2.openingBalance, 150000);
    });
  });
}
