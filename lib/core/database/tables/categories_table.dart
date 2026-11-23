import 'package:drift/drift.dart';

@DataClassName('CategoryEntry')
class CategoriesTable extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()(); // UUID PK
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()(); // 'income' atau 'expense'
  TextColumn get iconKey => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
