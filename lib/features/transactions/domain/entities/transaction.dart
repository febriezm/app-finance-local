enum TransactionType {
  income,
  expense,
  transfer;

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Pemasukan';
      case TransactionType.expense:
        return 'Pengeluaran';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  static TransactionType fromString(String value) {
    switch (value) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      default:
        throw ArgumentError('Invalid TransactionType: $value');
    }
  }

  String toDbString() {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
      case TransactionType.transfer:
        return 'transfer';
    }
  }
}

enum TransactionStatus {
  confirmed,
  voided;

  String get displayName => this == TransactionStatus.confirmed ? 'Terkonfirmasi' : 'Dibatalkan';

  static TransactionStatus fromString(String value) {
    switch (value) {
      case 'confirmed':
        return TransactionStatus.confirmed;
      case 'voided':
        return TransactionStatus.voided;
      default:
        return TransactionStatus.confirmed;
    }
  }

  String toDbString() => this == TransactionStatus.confirmed ? 'confirmed' : 'voided';
}

class TransactionSource {
  TransactionSource._();
  static const String manual = 'manual';
  static const String receiptScan = 'receipt_scan';
  static const String recurring = 'recurring';
}

class Transaction {
  final String id;
  final TransactionType type;
  final int amount; // Integer Rupiah
  final String occurredAt; // ISO-8601 UTC
  final String? walletId; // Source wallet
  final String? destinationWalletId; // Destination wallet (Transfer)
  final String? categoryId; // Category (Income/Expense)
  final String? merchant;
  final String? description;
  final String? notes;
  final String source; // 'manual', 'receipt_scan', 'recurring'
  final TransactionStatus status;
  final String createdAt;
  final String updatedAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.occurredAt,
    this.walletId,
    this.destinationWalletId,
    this.categoryId,
    this.merchant,
    this.description,
    this.notes,
    this.source = 'manual',
    this.status = TransactionStatus.confirmed,
    required this.createdAt,
    required this.updatedAt,
  });

  Transaction copyWith({
    String? id,
    TransactionType? type,
    int? amount,
    String? occurredAt,
    String? walletId,
    String? destinationWalletId,
    String? categoryId,
    String? merchant,
    String? description,
    String? notes,
    String? source,
    TransactionStatus? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      occurredAt: occurredAt ?? this.occurredAt,
      walletId: walletId ?? this.walletId,
      destinationWalletId: destinationWalletId ?? this.destinationWalletId,
      categoryId: categoryId ?? this.categoryId,
      merchant: merchant ?? this.merchant,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
