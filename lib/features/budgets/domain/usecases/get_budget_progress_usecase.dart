import '../entities/budget.dart';
import '../repositories/budget_repository.dart';

class GetBudgetProgressUseCase {
  final BudgetRepository _repository;

  GetBudgetProgressUseCase(this._repository);

  Stream<BudgetProgress> execute(String monthKey) {
    return _repository.watchBudgetProgress(monthKey);
  }
}
