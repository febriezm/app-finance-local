class AppConstants {
  AppConstants._();

  static const String appName = 'MyFinance';
  static const String appVersion = '1.0.0';
  static const String databaseName = 'myfinance.sqlite';

  // System Categories (Default seed IDs)
  static const String defaultIncomeCategoryId = 'cat-income-default';
  static const String defaultExpenseCategoryId = 'cat-expense-default';

  // Budget Default Alert Thresholds
  static const List<int> defaultBudgetThresholds = [75, 90, 100];
}
