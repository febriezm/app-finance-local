import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/receipt_draft.dart';
import '../../domain/usecases/scan_receipt_usecase.dart';
import '../../domain/usecases/confirm_receipt_transaction_usecase.dart';

class ReceiptScannerController extends StateNotifier<AsyncValue<ReceiptDraft?>> {
  final ScanReceiptUseCase _scanReceiptUseCase;
  final ConfirmReceiptTransactionUseCase _confirmReceiptTransactionUseCase;

  ReceiptScannerController(
    this._scanReceiptUseCase,
    this._confirmReceiptTransactionUseCase,
  ) : super(const AsyncValue.data(null));

  Future<ReceiptDraft?> scanImage({
    required String imagePath,
    Uint8List? imageBytes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final draft = await _scanReceiptUseCase.execute(
        imagePath: imagePath,
        imageBytes: imageBytes,
      );
      state = AsyncValue.data(draft);
      return draft;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<String?> confirmTransaction({
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
    try {
      final txId = await _confirmReceiptTransactionUseCase.execute(
        draft: draft,
        walletId: walletId,
        categoryId: categoryId,
        amount: amount,
        occurredAt: occurredAt,
        merchant: merchant,
        description: description,
        notes: notes,
        imageBytes: imageBytes,
      );
      state = const AsyncValue.data(null);
      return txId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void clearDraft() {
    state = const AsyncValue.data(null);
  }
}
