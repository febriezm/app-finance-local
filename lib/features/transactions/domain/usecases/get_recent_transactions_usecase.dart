import '../entities/transaction_with_details.dart';
import '../repositories/transaction_repository.dart';

class GetRecentTransactionsUseCase {
  final TransactionRepository _repository;

  GetRecentTransactionsUseCase(this._repository);

  Stream<List<TransactionWithDetails>> execute({int limit = 20}) {
    return _repository.watchRecentTransactions(limit: limit);
  }
}
