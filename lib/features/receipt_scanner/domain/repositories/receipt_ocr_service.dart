import 'dart:typed_data';
import '../entities/ocr_result.dart';

/// Interface layanan OCR on-device sesuai Blueprint Section 4.5.
abstract interface class ReceiptOcrService {
  /// Melakukan pengenalan karakter visual (OCR) dari file gambar lokal.
  Future<OcrResult> recognize(String imagePath, [Uint8List? imageBytes]);
}
