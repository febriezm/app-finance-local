import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

Future<void> saveOrShareFile({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
  String? subject,
}) async {
  final xfile = XFile.fromData(
    bytes,
    mimeType: mimeType,
    name: filename,
  );
  await Share.shareXFiles(
    [xfile],
    subject: subject,
  );
}
