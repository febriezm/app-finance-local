class BackupArchive {
  final int schemaVersion;
  final String appName;
  final String appVersion;
  final String exportedAt;
  final List<Map<String, dynamic>> wallets;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> budgetCategoryLimits;
  final List<Map<String, dynamic>> transactionAttachments;

  const BackupArchive({
    this.schemaVersion = 1,
    this.appName = 'MyFinance',
    this.appVersion = '1.0.0',
    required this.exportedAt,
    required this.wallets,
    required this.categories,
    required this.transactions,
    required this.budgets,
    required this.budgetCategoryLimits,
    this.transactionAttachments = const [],
  });

  int get totalRecordsCount =>
      wallets.length +
      categories.length +
      transactions.length +
      budgets.length +
      budgetCategoryLimits.length +
      transactionAttachments.length;

  Map<String, dynamic> toJson() {
    return {
      'metadata': {
        'schemaVersion': schemaVersion,
        'appName': appName,
        'appVersion': appVersion,
        'exportedAt': exportedAt,
        'totalRecords': totalRecordsCount,
      },
      'data': {
        'wallets': wallets,
        'categories': categories,
        'transactions': transactions,
        'budgets': budgets,
        'budgetCategoryLimits': budgetCategoryLimits,
        'transactionAttachments': transactionAttachments,
      },
    };
  }

  factory BackupArchive.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return BackupArchive(
      schemaVersion: metadata['schemaVersion'] as int? ?? 1,
      appName: metadata['appName'] as String? ?? 'MyFinance',
      appVersion: metadata['appVersion'] as String? ?? '1.0.0',
      exportedAt: metadata['exportedAt'] as String? ?? DateTime.now().toUtc().toIso8601String(),
      wallets: (data['wallets'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      categories: (data['categories'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      transactions: (data['transactions'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      budgets: (data['budgets'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      budgetCategoryLimits: (data['budgetCategoryLimits'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      transactionAttachments: (data['transactionAttachments'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}
