import 'package:drift/drift.dart';
import 'transactions_table.dart';

@DataClassName('TransactionAttachmentEntry')
@TableIndex(name: 'idx_attachments_transaction_id', columns: {#transactionId})
class TransactionAttachmentsTable extends Table {
  @override
  String get tableName => 'transaction_attachments';

  TextColumn get id => text()(); // UUID PK
  TextColumn get transactionId => text().references(
        TransactionsTable,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get localPath => text()(); // Path relatif dalam app documents sandbox
  TextColumn get mimeType => text().withDefault(const Constant('image/jpeg'))();
  IntColumn get fileSize => integer()(); // Ukuran dalam bytes
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
