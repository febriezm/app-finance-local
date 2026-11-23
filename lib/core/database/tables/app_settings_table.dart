import 'package:drift/drift.dart';

@DataClassName('AppSettingEntry')
class AppSettingsTable extends Table {
  @override
  String get tableName => 'app_settings';

  TextColumn get key => text()(); // Kunci setting PK
  TextColumn get value => text()(); // Nilai setting
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {key};
}
