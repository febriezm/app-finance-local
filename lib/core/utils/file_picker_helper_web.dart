// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

Future<String?> pickJsonFileContent() async {
  final completer = Completer<String?>();
  final uploadInput = html.FileUploadInputElement()
    ..accept = '.json,application/json'
    ..multiple = false;

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final reader = html.FileReader();
      reader.readAsText(files[0]);
      reader.onLoadEnd.listen((_) {
        completer.complete(reader.result as String?);
      });
      reader.onError.listen((_) {
        completer.complete(null);
      });
    } else {
      completer.complete(null);
    }
  });

  // Tambahkan ke DOM sebentar lalu klik
  html.document.body?.children.add(uploadInput);
  uploadInput.click();
  html.document.body?.children.remove(uploadInput);

  return completer.future;
}
