import '../entities/budget.dart';
import '../repositories/budget_repository.dart';

class SaveBudgetUseCase {
  final BudgetRepository _repository;

  SaveBudgetUseCase(this._repository);

  Future<void> execute({
    required Budget budget,
    required List<BudgetCategoryLimit> categoryLimits,
  }) {
    return _repository.saveBudget(
      budget: budget,
      categoryLimits: categoryLimits,
    );
  }
}
