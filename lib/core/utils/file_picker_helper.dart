import 'file_picker_helper_stub.dart'
    if (dart.library.html) 'file_picker_helper_web.dart' as impl;

class FilePickerHelper {
  FilePickerHelper._();

  /// Memilih berkas JSON cadangan dan mengembalikan isinya sebagai String
  static Future<String?> pickJsonFile() async {
    return impl.pickJsonFileContent();
  }
}
