import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('performReceiptOcr')
external JSPromise<JSString?>? _performReceiptOcr(JSString base64Image);

/// Runner OCR on-device di browser (Safari iOS / Chrome) menggunakan WebAssembly/Tesseract.js.
/// Berjalan 100% lokal pada perangkat pengguna tanpa mengirim foto ke cloud.
Future<String> runPlatformOcr(String imagePath, Uint8List? imageBytes) async {
  if (imageBytes == null || imageBytes.isEmpty) {
    return '';
  }
  try {
    final b64 = base64Encode(imageBytes);
    final promise = _performReceiptOcr(b64.toJS);
    if (promise == null) return '';
    final jsString = await promise.toDart;
    if (jsString == null) return '';
    return jsString.toDart;
  } catch (_) {
    return '';
  }
}
