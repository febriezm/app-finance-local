import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../data/services/attachment_storage_service.dart';
import '../entities/receipt_draft.dart';

class ConfirmReceiptTransactionUseCase {
  final TransactionRepository _transactionRepository;
  final AttachmentStorageService _attachmentStorageService;

  ConfirmReceiptTransactionUseCase(
    this._transactionRepository,
    this._attachmentStorageService,
  );

  Future<String> execute({
    required ReceiptDraft draft,
    required String walletId,
    required String categoryId,
    required int amount,
    required DateTime occurredAt,
    String? merchant,
    String? description,
    String? notes,
    Uint8List? imageBytes,
  }) async {
    // 1. Validasi
    if (amount <= 0) {
      throw const ValidationFailure('Nominal pengeluaran harus lebih besar dari 0.');
    }
    if (walletId.trim().isEmpty) {
      throw const ValidationFailure('Dompet sumber wajib dipilih.');
    }
    if (categoryId.trim().isEmpty) {
      throw const ValidationFailure('Kategori pengeluaran wajib dipilih.');
    }

    final transactionId = const Uuid().v4();
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final occurredAtIso = occurredAt.toUtc().toIso8601String();

    // 2. Buat Transaksi Expense dengan source receipt_scan
    // Masukkan rincian item ke description & notes jika belum ditentukan
    String? finalNotes = notes;
    if ((finalNotes == null || finalNotes.trim().isEmpty) && draft.items.isNotEmpty) {
      finalNotes = draft.items.map((i) {
        final qtyStr = i.quantity > 1 ? '${i.quantity}x ' : '';
        return '$qtyStr${i.name} (Rp ${i.totalPrice})';
      }).join(', ');
    }

    final effectiveMerchant = merchant ?? draft.merchant;
    String finalDescription = description ?? '';
    if (finalDescription.trim().isEmpty) {
      if (draft.items.isNotEmpty) {
        final itemNames = draft.items.map((i) => i.name).join(', ');
        finalDescription = (effectiveMerchant != null && effectiveMerchant.isNotEmpty)
            ? '$effectiveMerchant: $itemNames'
            : itemNames;
      } else if (effectiveMerchant != null && effectiveMerchant.isNotEmpty) {
        finalDescription = 'Belanja di $effectiveMerchant';
      } else {
        finalDescription = 'Scan Struk';
      }
    }

    final transaction = Transaction(
      id: transactionId,
      type: TransactionType.expense,
      amount: amount,
      occurredAt: occurredAtIso,
      walletId: walletId,
      categoryId: categoryId,
      merchant: effectiveMerchant,
      description: finalDescription,
      notes: finalNotes,
      source: TransactionSource.receiptScan,
      status: TransactionStatus.confirmed,
      createdAt: nowIso,
      updatedAt: nowIso,
    );

    await _transactionRepository.createTransaction(transaction);

    // 3. Simpan lampiran struk jika path tersedia
    if (draft.imagePath != null && draft.imagePath!.isNotEmpty) {
      await _attachmentStorageService.saveReceiptAttachment(
        transactionId: transactionId,
        originalPath: draft.imagePath!,
        imageBytes: imageBytes,
      );
    }

    return transactionId;
  }
}
