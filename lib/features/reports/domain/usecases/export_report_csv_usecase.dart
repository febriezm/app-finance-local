import '../repositories/report_repository.dart';

class ExportReportCsvUseCase {
  final ReportRepository repository;

  const ExportReportCsvUseCase(this.repository);

  Future<String> execute(String monthKey) async {
    final report = await repository.getMonthlyReport(monthKey);
    final transactions = await repository.getTransactionsForReport(monthKey: monthKey);
    return repository.exportReportToCsv(report, transactions);
  }
}
