import '../../../../core/database/app_database.dart';
import '../../domain/entities/transaction.dart';

class TransactionModel {
  static Transaction fromEntry(TransactionEntry entry) {
    return Transaction(
      id: entry.id,
      type: TransactionType.fromString(entry.type),
      amount: entry.amount,
      occurredAt: entry.occurredAt,
      walletId: entry.walletId,
      destinationWalletId: entry.destinationWalletId,
      categoryId: entry.categoryId,
      merchant: entry.merchant,
      description: entry.description,
      notes: entry.notes,
      source: entry.source,
      status: TransactionStatus.fromString(entry.status),
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }
}
