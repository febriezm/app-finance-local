import 'package:drift/drift.dart';

@DataClassName('BudgetEntry')
@TableIndex(name: 'idx_budgets_month_key', columns: {#monthKey})
class BudgetsTable extends Table {
  @override
  String get tableName => 'budgets';

  TextColumn get id => text()(); // UUID PK
  TextColumn get monthKey => text().unique()(); // Format YYYY-MM
  IntColumn get totalLimit => integer()(); // Batas total pengeluaran bulanan (Rupiah)
  TextColumn get alertThresholds => text().withDefault(const Constant('[75,90,100]'))(); // JSON array
  BoolColumn get carryOverEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
