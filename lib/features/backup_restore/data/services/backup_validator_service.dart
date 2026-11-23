import 'dart:convert';
import '../../domain/entities/backup_archive.dart';
import '../../domain/entities/restore_validation_result.dart';

class BackupValidatorService {
  const BackupValidatorService();

  RestoreValidationResult validate(String jsonString) {
    if (jsonString.trim().isEmpty) {
      return RestoreValidationResult.failure('Berkas cadangan kosong.');
    }

    Map<String, dynamic> rootMap;
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return RestoreValidationResult.failure(
          'Format tidak sesuai: Konten arsip harus berupa objek JSON valid.',
        );
      }
      rootMap = decoded;
    } catch (_) {
      final trimmed = jsonString.trim();
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return RestoreValidationResult.failure(
          'Teks yang ditempel merupakan alamat tautan (URL), bukan berkas cadangan JSON MyFinance.',
        );
      }
      return RestoreValidationResult.failure(
        'Format JSON tidak valid: Teks atau berkas yang dipilih bukan berkas cadangan JSON yang sesuai.',
      );
    }

    // 1. Metadata check
    final metadata = rootMap['metadata'];
    if (metadata is! Map<String, dynamic>) {
      return RestoreValidationResult.failure('Metadata arsip cadangan hilang atau tidak valid.');
    }

    final schemaVersion = metadata['schemaVersion'] as int?;
    if (schemaVersion == null) {
      return RestoreValidationResult.failure('Versi skema cadangan tidak ditemukan.');
    }
    if (schemaVersion != 1) {
      return RestoreValidationResult.failure(
        'Versi skema cadangan (v$schemaVersion) tidak kompatibel dengan aplikasi (hanya mendukung v1).',
      );
    }

    // 2. Data containers check
    final data = rootMap['data'];
    if (data is! Map<String, dynamic>) {
      return RestoreValidationResult.failure('Bagian data pada arsip cadangan tidak ditemukan.');
    }

    final walletsList = data['wallets'] as List<dynamic>? ?? [];
    final categoriesList = data['categories'] as List<dynamic>? ?? [];
    final transactionsList = data['transactions'] as List<dynamic>? ?? [];
    final budgetsList = data['budgets'] as List<dynamic>? ?? [];
    final limitsList = data['budgetCategoryLimits'] as List<dynamic>? ?? [];
    final attachmentsList = data['transactionAttachments'] as List<dynamic>? ?? [];

    // 3. Collect primary keys for relation integrity
    final walletIds = <String>{};
    for (final item in walletsList) {
      if (item is! Map) return RestoreValidationResult.failure('Data dompet tidak valid.');
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) return RestoreValidationResult.failure('Terdapat dompet tanpa ID.');
      walletIds.add(id);
    }

    final categoryIds = <String>{};
    for (final item in categoriesList) {
      if (item is! Map) return RestoreValidationResult.failure('Data kategori tidak valid.');
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) return RestoreValidationResult.failure('Terdapat kategori tanpa ID.');
      categoryIds.add(id);
    }

    final budgetIds = <String>{};
    for (final item in budgetsList) {
      if (item is! Map) return RestoreValidationResult.failure('Data anggaran tidak valid.');
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) return RestoreValidationResult.failure('Terdapat anggaran tanpa ID.');
      budgetIds.add(id);
    }

    final transactionIds = <String>{};
    for (final item in transactionsList) {
      if (item is! Map) return RestoreValidationResult.failure('Data transaksi tidak valid.');
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) return RestoreValidationResult.failure('Terdapat transaksi tanpa ID.');
      transactionIds.add(id);

      final type = item['type']?.toString();
      if (type == null) return RestoreValidationResult.failure('Tipe transaksi pada $id kosong.');

      final wId = (item['wallet_id'] ?? item['walletId'])?.toString();
      if (wId != null && !walletIds.contains(wId)) {
        return RestoreValidationResult.failure(
          'Pelanggaran relasi integritas: Dompet asal ID $wId pada transaksi $id tidak terdaftar di cadangan dompet.',
        );
      }

      if (type == 'transfer') {
        final destId = (item['destination_wallet_id'] ?? item['destinationWalletId'])?.toString();
        if (destId != null && destId.isNotEmpty) {
          if (!walletIds.contains(destId)) {
            return RestoreValidationResult.failure(
              'Pelanggaran relasi integritas: Dompet tujuan ID $destId pada transfer $id tidak terdaftar.',
            );
          }
          if (destId == wId) {
            return RestoreValidationResult.failure(
              'Pelanggaran relasi integritas: Transfer $id memiliki dompet asal dan tujuan yang sama.',
            );
          }
        }
      }

      final cId = (item['category_id'] ?? item['categoryId'])?.toString();
      if (cId != null && !categoryIds.contains(cId)) {
        return RestoreValidationResult.failure(
          'Pelanggaran relasi integritas: Kategori ID $cId pada transaksi $id tidak terdaftar di cadangan kategori.',
        );
      }
    }

    // 4. Budget limits foreign key checks
    for (final item in limitsList) {
      if (item is! Map) return RestoreValidationResult.failure('Data batas anggaran tidak valid.');
      final bId = (item['budget_id'] ?? item['budgetId'])?.toString();
      if (bId == null || !budgetIds.contains(bId)) {
        return RestoreValidationResult.failure(
          'Pelanggaran relasi integritas: Anggaran ID $bId pada batas kategori tidak terdaftar.',
        );
      }
      final cId = (item['category_id'] ?? item['categoryId'])?.toString();
      if (cId == null || !categoryIds.contains(cId)) {
        return RestoreValidationResult.failure(
          'Pelanggaran relasi integritas: Kategori ID $cId pada batas anggaran tidak terdaftar.',
        );
      }
    }

    // 5. Attachments foreign key checks
    for (final item in attachmentsList) {
      if (item is! Map) return RestoreValidationResult.failure('Data lampiran struk tidak valid.');
      final tId = (item['transaction_id'] ?? item['transactionId'])?.toString();
      if (tId == null || !transactionIds.contains(tId)) {
        return RestoreValidationResult.failure(
          'Pelanggaran relasi integritas: Transaksi ID $tId pada lampiran struk tidak terdaftar.',
        );
      }
    }

    final archive = BackupArchive.fromJson(rootMap);
    return RestoreValidationResult.success(archive);
  }
}
