import 'dart:typed_data';
import 'file_export_helper_stub.dart'
    if (dart.library.html) 'file_export_helper_web.dart' as impl;

class FileExportHelper {
  FileExportHelper._();

  /// Menyimpan berkas (Download di Web atau Native Share Sheet di iOS/Android)
  static Future<void> saveOrShare({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String? subject,
  }) async {
    await impl.saveOrShareFile(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
      subject: subject,
    );
  }
}
