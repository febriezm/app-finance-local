import 'dart:typed_data';
import 'ocr_runner_stub.dart'
    if (dart.library.js_interop) 'ocr_runner_web.dart'
    if (dart.library.io) 'ocr_runner_io.dart';

Future<String> runOcr(String imagePath, Uint8List? imageBytes) =>
    runPlatformOcr(imagePath, imageBytes);
