import 'package:drift/drift.dart';
import 'budgets_table.dart';
import 'categories_table.dart';

@DataClassName('BudgetCategoryLimitEntry')
class BudgetCategoryLimitsTable extends Table {
  @override
  String get tableName => 'budget_category_limits';

  TextColumn get id => text()(); // UUID PK
  TextColumn get budgetId => text().references(
        BudgetsTable,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get categoryId => text().references(CategoriesTable, #id)();
  IntColumn get limitAmount => integer()(); // Batas pengeluaran kategori (Rupiah)

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {budgetId, categoryId},
      ];
}
