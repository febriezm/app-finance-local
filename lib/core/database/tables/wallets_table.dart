import 'package:drift/drift.dart';

@DataClassName('WalletEntry')
class WalletsTable extends Table {
  @override
  String get tableName => 'wallets';

  TextColumn get id => text()(); // UUID PK
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()(); // cash, bank, e_wallet, other
  IntColumn get openingBalance => integer()(); // Integer Rupiah
  TextColumn get openingDate => text()(); // Tanggal saldo awal (ISO-8601 UTC)
  TextColumn get currencyCode => text().withDefault(const Constant('IDR'))();
  TextColumn get iconKey => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
