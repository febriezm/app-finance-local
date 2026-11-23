import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class CreateTransactionUseCase {
  final TransactionRepository _repository;

  CreateTransactionUseCase(this._repository);

  Future<void> execute(Transaction transaction) {
    return _repository.createTransaction(transaction);
  }
}
