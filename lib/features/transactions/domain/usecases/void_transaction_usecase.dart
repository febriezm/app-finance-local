import '../repositories/transaction_repository.dart';

class VoidTransactionUseCase {
  final TransactionRepository _repository;

  VoidTransactionUseCase(this._repository);

  Future<void> execute(String id) {
    return _repository.voidTransaction(id);
  }
}
