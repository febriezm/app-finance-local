import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/features/backup_restore/data/repositories/backup_repository_impl.dart';
import 'package:myfinance/features/backup_restore/data/services/backup_validator_service.dart';

void main() {
  const validator = BackupValidatorService();

  group('BackupValidatorService', () {
    test('Validates a complete, structurally sound backup JSON archive', () {
      final validJson = jsonEncode({
        'metadata': {
          'schemaVersion': 1,
          'appName': 'MyFinance',
          'appVersion': '1.0.0',
          'exportedAt': '2026-11-17T20:00:00.000Z',
          'totalRecords': 3,
        },
        'data': {
          'wallets': [
            {
              'id': 'w-1',
              'name': 'BCA',
              'type': 'bank',
              'openingBalance': 1000000,
              'openingDate': '2026-11-01T00:00:00.000Z',
            },
          ],
          'categories': [
            {
              'id': 'cat-1',
              'name': 'Gaji',
              'type': 'income',
            },
          ],
          'transactions': [
            {
              'id': 'tx-1',
              'type': 'income',
              'amount': 5000000,
              'occurredAt': '2026-11-05T00:00:00.000Z',
              'wallet_id': 'w-1',
              'category_id': 'cat-1',
              'status': 'confirmed',
            },
          ],
          'budgets': [],
          'budgetCategoryLimits': [],
          'transactionAttachments': [],
        },
      });

      final result = validator.validate(validJson);
      expect(result.isValid, true);
      expect(result.walletsCount, 1);
      expect(result.categoriesCount, 1);
      expect(result.transactionsCount, 1);
      expect(result.totalRecordsCount, 3);
    });

    test('Rejects invalid JSON syntax', () {
      const brokenJson = '{ "metadata": { "schemaVersion": 1, ';
      final result = validator.validate(brokenJson);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('Format JSON tidak valid'));
    });

    test('Rejects URL string with clear informative message', () {
      const urlText = 'http://localhost:8085';
      final result = validator.validate(urlText);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('alamat tautan (URL)'));
    });

    test('Rejects incompatible schema version', () {
      final invalidVersionJson = jsonEncode({
        'metadata': {
          'schemaVersion': 99,
          'appName': 'MyFinance',
        },
        'data': {},
      });

      final result = validator.validate(invalidVersionJson);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('tidak kompatibel'));
    });

    test('Rejects broken foreign key: transaction references non-existent wallet', () {
      final brokenFkJson = jsonEncode({
        'metadata': {'schemaVersion': 1, 'appName': 'MyFinance'},
        'data': {
          'wallets': [
            {'id': 'w-valid', 'name': 'Tunai', 'type': 'cash', 'openingBalance': 0},
          ],
          'categories': [
            {'id': 'cat-food', 'name': 'Makan', 'type': 'expense'},
          ],
          'transactions': [
            {
              'id': 'tx-orphan',
              'type': 'expense',
              'amount': 50000,
              'wallet_id': 'w-NON-EXISTENT', // Broken FK!
              'category_id': 'cat-food',
            },
          ],
        },
      });

      final result = validator.validate(brokenFkJson);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('Pelanggaran relasi integritas'));
      expect(result.errorMessage, contains('w-NON-EXISTENT'));
    });

    test('Rejects transfer where origin and destination wallet are identical', () {
      final invalidTransferJson = jsonEncode({
        'metadata': {'schemaVersion': 1, 'appName': 'MyFinance'},
        'data': {
          'wallets': [
            {'id': 'w-1', 'name': 'BCA', 'type': 'bank', 'openingBalance': 1000},
          ],
          'categories': [],
          'transactions': [
            {
              'id': 'tx-loop',
              'type': 'transfer',
              'amount': 50000,
              'wallet_id': 'w-1',
              'destination_wallet_id': 'w-1', // Same wallet!
            },
          ],
        },
      });

      final result = validator.validate(invalidTransferJson);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('dompet asal dan tujuan yang sama'));
    });
  });

  group('BackupRepositoryImpl', () {
    late AppDatabase db;
    late BackupRepositoryImpl repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = BackupRepositoryImpl(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Creates backup archive and exports formatted JSON string', () async {
      // Add a wallet
      await db.into(db.walletsTable).insert(
        WalletsTableCompanion.insert(
          id: 'w-test',
          name: 'Dompet Uji',
          type: 'cash',
          openingBalance: 250000,
          openingDate: '2026-11-01T00:00:00.000Z',
          createdAt: '2026-11-01T00:00:00.000Z',
          updatedAt: '2026-11-01T00:00:00.000Z',
        ),
      );

      final archive = await repository.createBackup();
      expect(archive.schemaVersion, 1);
      expect(archive.wallets.length, 1);
      expect(archive.wallets.first['name'], 'Dompet Uji');

      final jsonStr = await repository.exportBackupJson();
      expect(jsonStr.contains('MyFinance'), true);
      expect(jsonStr.contains('Dompet Uji'), true);
    });
  });
}
