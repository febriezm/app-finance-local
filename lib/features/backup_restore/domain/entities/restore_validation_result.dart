import 'backup_archive.dart';

class RestoreValidationResult {
  final bool isValid;
  final String? errorMessage;
  final BackupArchive? archive;
  final int schemaVersion;
  final String? exportedAt;
  final int walletsCount;
  final int categoriesCount;
  final int transactionsCount;
  final int budgetsCount;
  final int budgetLimitsCount;
  final int attachmentsCount;

  const RestoreValidationResult({
    required this.isValid,
    this.errorMessage,
    this.archive,
    this.schemaVersion = 1,
    this.exportedAt,
    this.walletsCount = 0,
    this.categoriesCount = 0,
    this.transactionsCount = 0,
    this.budgetsCount = 0,
    this.budgetLimitsCount = 0,
    this.attachmentsCount = 0,
  });

  factory RestoreValidationResult.success(BackupArchive archive) {
    return RestoreValidationResult(
      isValid: true,
      archive: archive,
      schemaVersion: archive.schemaVersion,
      exportedAt: archive.exportedAt,
      walletsCount: archive.wallets.length,
      categoriesCount: archive.categories.length,
      transactionsCount: archive.transactions.length,
      budgetsCount: archive.budgets.length,
      budgetLimitsCount: archive.budgetCategoryLimits.length,
      attachmentsCount: archive.transactionAttachments.length,
    );
  }

  factory RestoreValidationResult.failure(String errorMessage) {
    return RestoreValidationResult(
      isValid: false,
      errorMessage: errorMessage,
    );
  }

  int get totalRecordsCount =>
      walletsCount +
      categoriesCount +
      transactionsCount +
      budgetsCount +
      budgetLimitsCount +
      attachmentsCount;
}
