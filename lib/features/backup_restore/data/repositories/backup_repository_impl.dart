import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/backup_archive.dart';
import '../../domain/entities/restore_validation_result.dart';
import '../../domain/repositories/backup_repository.dart';
import '../services/backup_validator_service.dart';

class BackupRepositoryImpl implements BackupRepository {
  final AppDatabase _db;
  final BackupValidatorService _validatorService;

  BackupRepositoryImpl(
    this._db, {
    BackupValidatorService validatorService = const BackupValidatorService(),
  }) : _validatorService = validatorService;

  @override
  Future<BackupArchive> createBackup() async {
    final wallets = await _db.select(_db.walletsTable).get();
    final categories = await _db.select(_db.categoriesTable).get();
    final transactions = await _db.select(_db.transactionsTable).get();
    final budgets = await _db.select(_db.budgetsTable).get();
    final budgetLimits = await _db.select(_db.budgetCategoryLimitsTable).get();
    final attachments = await _db.select(_db.transactionAttachmentsTable).get();

    return BackupArchive(
      schemaVersion: 1,
      appName: 'MyFinance',
      appVersion: '1.0.0',
      exportedAt: DateTime.now().toUtc().toIso8601String(),
      wallets: wallets.map((w) => w.toJson()).toList(),
      categories: categories.map((c) => c.toJson()).toList(),
      transactions: transactions.map((t) => t.toJson()).toList(),
      budgets: budgets.map((b) => b.toJson()).toList(),
      budgetCategoryLimits: budgetLimits.map((l) => l.toJson()).toList(),
      transactionAttachments: attachments.map((a) => a.toJson()).toList(),
    );
  }

  @override
  Future<String> exportBackupJson() async {
    final archive = await createBackup();
    return const JsonEncoder.withIndent('  ').convert(archive.toJson());
  }

  @override
  RestoreValidationResult validateBackupJson(String jsonString) {
    return _validatorService.validate(jsonString);
  }

  @override
  Future<void> restoreFromJson(String jsonString) async {
    final validation = validateBackupJson(jsonString);
    if (!validation.isValid || validation.archive == null) {
      throw FormatException(validation.errorMessage ?? 'Berkas cadangan tidak valid.');
    }

    final archive = validation.archive!;

    // Transaksional: Rollback otomatis jika ada query yang gagal
    await _db.transaction(() async {
      // 1. Kosongkan tabel dari child ke parent
      await _db.delete(_db.transactionAttachmentsTable).go();
      await _db.delete(_db.budgetCategoryLimitsTable).go();
      await _db.delete(_db.budgetsTable).go();
      await _db.delete(_db.transactionsTable).go();
      await _db.delete(_db.categoriesTable).go();
      await _db.delete(_db.walletsTable).go();

      // 2. Insert tabel dari parent ke child
      for (final w in archive.wallets) {
        await _db.into(_db.walletsTable).insert(
              WalletsTableCompanion(
                id: Value(w['id'] as String),
                name: Value(w['name'] as String),
                type: Value(w['type'] as String),
                openingBalance: Value((w['openingBalance'] ?? w['opening_balance'] ?? 0) as int),
                openingDate: Value((w['openingDate'] ?? w['opening_date'] ?? DateTime.now().toUtc().toIso8601String()) as String),
                currencyCode: Value((w['currencyCode'] ?? w['currency_code'] ?? 'IDR') as String),
                iconKey: Value(w['iconKey'] as String? ?? w['icon_key'] as String?),
                colorHex: Value(w['colorHex'] as String? ?? w['color_hex'] as String?),
                isArchived: Value((w['isArchived'] ?? w['is_archived'] ?? false) as bool),
                createdAt: Value((w['createdAt'] ?? w['created_at'] ?? DateTime.now().toUtc().toIso8601String()) as String),
                updatedAt: Value((w['updatedAt'] ?? w['updated_at'] ?? DateTime.now().toUtc().toIso8601String()) as String),
              ),
            );
      }

      for (final c in archive.categories) {
        await _db.into(_db.categoriesTable).insert(
              CategoriesTableCompanion(
                id: Value(c['id'] as String),
                name: Value(c['name'] as String),
                type: Value(c['type'] as String),
                iconKey: Value(c['iconKey'] as String? ?? c['icon_key'] as String?),
                colorHex: Value(c['colorHex'] as String? ?? c['color_hex'] as String?),
                isSystem: Value((c['isSystem'] ?? c['is_system'] ?? false) as bool),
                isArchived: Value((c['isArchived'] ?? c['is_archived'] ?? false) as bool),
                sortOrder: Value((c['sortOrder'] ?? c['sort_order'] ?? 0) as int),
              ),
            );
      }

      for (final t in archive.transactions) {
        await _db.into(_db.transactionsTable).insert(
              TransactionsTableCompanion(
                id: Value(t['id'] as String),
                type: Value(t['type'] as String),
                amount: Value(t['amount'] as int),
                occurredAt: Value((t['occurredAt'] ?? t['occurred_at'] ?? DateTime.now().toUtc().toIso8601String()) as String),
                walletId: Value(t['walletId'] as String? ?? t['wallet_id'] as String?),
                destinationWalletId: Value(t['destinationWalletId'] as String? ?? t['destination_wallet_id'] as String?),
                categoryId: Value(t['categoryId'] as String? ?? t['category_id'] as String?),
                merchant: Value(t['merchant'] as String?),
                description: Value(t['description'] as String?),
                notes: Value(t['notes'] as String?),
                source: Value((t['source'] ?? 'manual') as String),
                status: Value((t['status'] ?? 'confirmed') as String),
                createdAt: Value((t['createdAt'] ?? t['created_at'] ?? DateTime.now().toUtc().toIso8601String()) as String),
                updatedAt: Value((t['updatedAt'] ?? t['updated_at'] ?? DateTime.now().toUtc().toIso8601String()) as String),
              ),
            );
      }

      for (final b in archive.budgets) {
        await _db.into(_db.budgetsTable).insert(
              BudgetsTableCompanion(
                id: Value(b['id'] as String),
                monthKey: Value((b['monthKey'] ?? b['month_key']) as String),
                totalLimit: Value((b['totalLimit'] ?? b['total_limit']) as int),
                createdAt: Value((b['createdAt'] ?? b['created_at'] ?? DateTime.now().toUtc().toIso8601String()) as String),
                updatedAt: Value((b['updatedAt'] ?? b['updated_at'] ?? DateTime.now().toUtc().toIso8601String()) as String),
              ),
            );
      }

      for (final l in archive.budgetCategoryLimits) {
        await _db.into(_db.budgetCategoryLimitsTable).insert(
              BudgetCategoryLimitsTableCompanion(
                id: Value(l['id'] as String),
                budgetId: Value((l['budgetId'] ?? l['budget_id']) as String),
                categoryId: Value((l['categoryId'] ?? l['category_id']) as String),
                limitAmount: Value((l['limitAmount'] ?? l['limit_amount']) as int),
              ),
            );
      }

      for (final a in archive.transactionAttachments) {
        await _db.into(_db.transactionAttachmentsTable).insert(
              TransactionAttachmentsTableCompanion(
                id: Value(a['id'] as String),
                transactionId: Value((a['transactionId'] ?? a['transaction_id']) as String),
                localPath: Value((a['localPath'] ?? a['local_path']) as String),
                mimeType: Value((a['mimeType'] ?? a['mime_type'] ?? 'image/jpeg') as String),
                fileSize: Value((a['fileSize'] ?? a['file_size'] ?? 0) as int),
                createdAt: Value((a['createdAt'] ?? a['created_at'] ?? DateTime.now().toUtc().toIso8601String()) as String),
              ),
            );
      }
    });
  }

  @override
  Future<void> resetAllData() async {
    await _db.transaction(() async {
      await _db.delete(_db.transactionAttachmentsTable).go();
      await _db.delete(_db.budgetCategoryLimitsTable).go();
      await _db.delete(_db.budgetsTable).go();
      await _db.delete(_db.transactionsTable).go();
      await _db.delete(_db.walletsTable).go();

      // Reset custom categories, preserve or re-seed system categories
      await (_db.delete(_db.categoriesTable)..where((c) => c.isSystem.equals(false))).go();
    });
  }
}
