import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_settings_table.dart';

part 'app_settings_dao.g.dart';

@DriftAccessor(tables: [AppSettingsTable])
class AppSettingsDao extends DatabaseAccessor<AppDatabase> with _$AppSettingsDaoMixin {
  AppSettingsDao(super.db);

  /// Mengambil nilai setting berdasarkan key secara aman
  Future<String?> getSetting(String key) async {
    try {
      final entry = await (select(appSettingsTable)..where((t) => t.key.equals(key))).getSingleOrNull();
      return entry?.value;
    } catch (e) {
      debugPrint('AppSettingsDao getSetting($key) notice: $e');
      return null;
    }
  }

  /// Watch stream setting berdasarkan key
  Stream<String?> watchSetting(String key) {
    try {
      return (select(appSettingsTable)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((entry) => entry?.value)
          .handleError((e) {
            debugPrint('AppSettingsDao watchSetting($key) notice: $e');
            return null;
          });
    } catch (e) {
      return Stream.value(null);
    }
  }

  /// Simpan atau perbarui nilai setting secara aman
  Future<int> setSetting(String key, String value) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      return await into(appSettingsTable).insertOnConflictUpdate(
        AppSettingsTableCompanion.insert(
          key: key,
          value: value,
          updatedAt: now,
        ),
      );
    } catch (e) {
      debugPrint('AppSettingsDao setSetting($key) notice: $e');
      return -1;
    }
  }

  /// Mengambil seluruh settings secara aman
  Future<List<AppSettingEntry>> getAllSettings() async {
    try {
      return await select(appSettingsTable).get();
    } catch (e) {
      debugPrint('AppSettingsDao getAllSettings notice: $e');
      return [];
    }
  }
}
