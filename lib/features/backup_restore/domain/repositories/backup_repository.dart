import '../entities/backup_archive.dart';
import '../entities/restore_validation_result.dart';

abstract interface class BackupRepository {
  /// Membuat arsip cadangan data seluruh database lokal
  Future<BackupArchive> createBackup();

  /// Mengenerate berkas string JSON cadangan
  Future<String> exportBackupJson();

  /// Memvalidasi berkas cadangan JSON sebelum dipulihkan (syntax, schema, integritas FK)
  RestoreValidationResult validateBackupJson(String jsonString);

  /// Memulihkan database secara atomik dari data string JSON (transaksional SQLite)
  Future<void> restoreFromJson(String jsonString);

  /// Mengosongkan data transaksi, dompet, anggaran, dan reset kategori bawaan (Danger Zone)
  Future<void> resetAllData();
}
