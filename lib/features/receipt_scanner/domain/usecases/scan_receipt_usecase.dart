import 'dart:typed_data';
import '../entities/receipt_draft.dart';
import '../repositories/receipt_ocr_service.dart';
import '../repositories/receipt_understanding_service.dart';

class ScanReceiptUseCase {
  final ReceiptOcrService _ocrService;
  final ReceiptUnderstandingService _understandingService;

  ScanReceiptUseCase(this._ocrService, this._understandingService);

  Future<ReceiptDraft> execute({
    required String imagePath,
    Uint8List? imageBytes,
  }) async {
    // 1. Jalankan OCR On-Device
    final ocrResult = await _ocrService.recognize(imagePath, imageBytes);

    // 2. Parser Lokal
    final draft = await _understandingService.parse(
      ocrResult,
      imagePath: imagePath,
      imageBytes: imageBytes,
    );

    return draft;
  }
}
