import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../constants/app_constants.dart';

/// Membuka koneksi database SQLite lokal di direktori aman Documents aplikasi.
LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseName));

    return NativeDatabase.createInBackground(
      file,
      setup: (database) {
        // Wajib mengaktifkan foreign keys di SQLite
        database.execute('PRAGMA foreign_keys = ON;');
      },
    );
  });
}
