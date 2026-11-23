class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class DatabaseException extends AppException {
  const DatabaseException([super.message = 'Terjadi kesalahan pada database SQLite.']);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Data tidak ditemukan.']);
}
