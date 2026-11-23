import 'package:drift/drift.dart';
import 'wallets_table.dart';
import 'categories_table.dart';

@DataClassName('TransactionEntry')
@TableIndex(name: 'idx_transactions_occurred_at', columns: {#occurredAt})
@TableIndex(name: 'idx_transactions_type_status_occurred_at', columns: {#type, #status, #occurredAt})
@TableIndex(name: 'idx_transactions_wallet_occurred_at', columns: {#walletId, #occurredAt})
@TableIndex(name: 'idx_transactions_category_occurred_at', columns: {#categoryId, #occurredAt})
class TransactionsTable extends Table {
  @override
  String get tableName => 'transactions';

  TextColumn get id => text()(); // UUID PK
  TextColumn get type => text()(); // 'income', 'expense', 'transfer'
  IntColumn get amount => integer()(); // Nominal Rupiah (harus > 0)
  TextColumn get occurredAt => text()(); // Waktu transaksi (ISO-8601 UTC)
  
  @ReferenceName('outgoingTransactions')
  TextColumn get walletId => text().nullable().references(WalletsTable, #id)();

  @ReferenceName('incomingTransactions')
  TextColumn get destinationWalletId => text().nullable().references(WalletsTable, #id)();

  @ReferenceName('categoryTransactions')
  TextColumn get categoryId => text().nullable().references(CategoriesTable, #id)();

  TextColumn get merchant => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))(); // 'manual', 'receipt_scan', 'recurring'
  TextColumn get status => text().withDefault(const Constant('confirmed'))(); // 'confirmed', 'voided'
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
