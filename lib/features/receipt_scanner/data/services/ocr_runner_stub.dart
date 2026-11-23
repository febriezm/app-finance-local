import 'dart:typed_data';

/// Fallback OCR runner saat tidak ada platform library spesifik.
Future<String> runPlatformOcr(String imagePath, Uint8List? imageBytes) async {
  return '';
}
