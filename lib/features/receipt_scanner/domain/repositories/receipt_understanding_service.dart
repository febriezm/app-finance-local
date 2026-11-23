import 'dart:typed_data';
import '../entities/ocr_result.dart';
import '../entities/receipt_draft.dart';

/// Interface parser cerdas lokal struk belanja sesuai Blueprint Section 4.5.
abstract interface class ReceiptUnderstandingService {
  /// Mengekstrak teks OCR menjadi data terstruktur (merchant, tanggal, total, item).
  Future<ReceiptDraft> parse(
    OcrResult result, {
    String? imagePath,
    Uint8List? imageBytes,
  });
}
