import 'dart:typed_data';

/// OCR runner untuk platform native (iOS / Android / macOS).
/// Sesuai Blueprint Section 4.5, siap dihubungkan ke on-device Apple Vision Kit
/// (VNRecognizeTextRequest) atau ML Kit on-device tanpa dependensi cloud.
Future<String> runPlatformOcr(String imagePath, Uint8List? imageBytes) async {
  // Bila berjalan di desktop testing / simulator tanpa platform channel aktif,
  // kembalikan string kosong agar field diarahkan ke input manual (bukan mengarang).
  return '';
}
