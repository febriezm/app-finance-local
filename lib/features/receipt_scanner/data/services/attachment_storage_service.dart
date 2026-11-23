import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/daos/transactions_dao.dart';
import '../../../../core/database/app_database.dart';

/// Layanan penyimpanan lampiran struk lokal (Blueprint Section 7.4).
/// Menyimpan file di direktori sandboxed Documents/Application Support aplikasi.
class AttachmentStorageService {
  final TransactionsDao _transactionsDao;

  AttachmentStorageService(this._transactionsDao);

  /// Menyalin atau menyimpan file gambar struk ke sandbox lokal dan mencatatnya ke database
  Future<String> saveReceiptAttachment({
    required String transactionId,
    required String originalPath,
    Uint8List? imageBytes,
  }) async {
    final attachmentId = const Uuid().v4();
    final nowIso = DateTime.now().toUtc().toIso8601String();
    String relativePath = 'receipts/$attachmentId.jpg';
    int fileSize = imageBytes?.lengthInBytes ?? 1024;

    try {
      if (!kIsWeb) {
        final docsDir = await getApplicationDocumentsDirectory();
        final receiptsDir = Directory(p.join(docsDir.path, 'receipts'));
        if (!await receiptsDir.exists()) {
          await receiptsDir.create(recursive: true);
        }

        final targetFile = File(p.join(receiptsDir.path, '$attachmentId.jpg'));

        if (imageBytes != null && imageBytes.isNotEmpty) {
          await targetFile.writeAsBytes(imageBytes);
          fileSize = imageBytes.lengthInBytes;
        } else if (originalPath.isNotEmpty && !originalPath.startsWith('sample:')) {
          final src = File(originalPath);
          if (await src.exists()) {
            await src.copy(targetFile.path);
            fileSize = await targetFile.length();
          }
        }
        relativePath = p.join('receipts', '$attachmentId.jpg');
      }
    } catch (e) {
      debugPrint('Warning: Could not copy attachment file physically: $e');
    }

    // Catat ke SQLite
    await _transactionsDao.insertAttachment(
      TransactionAttachmentsTableCompanion.insert(
        id: attachmentId,
        transactionId: transactionId,
        localPath: relativePath,
        fileSize: fileSize,
        createdAt: nowIso,
      ),
    );

    return relativePath;
  }
}
