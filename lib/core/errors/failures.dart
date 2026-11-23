abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Terjadi kesalahan pada database lokal.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Data tidak ditemukan.']);
}

class InsufficientBalanceFailure extends Failure {
  const InsufficientBalanceFailure([super.message = 'Saldo wallet tidak mencukupi.']);
}

class DuplicateDataFailure extends Failure {
  const DuplicateDataFailure([super.message = 'Data sudah ada sebelumnya.']);
}
