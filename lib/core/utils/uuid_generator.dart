import 'package:uuid/uuid.dart';

class UuidGenerator {
  UuidGenerator._();

  static const Uuid _uuid = Uuid();

  /// Menghasilkan UUID v4 acak sebagai string.
  static String generate() => _uuid.v4();
}
