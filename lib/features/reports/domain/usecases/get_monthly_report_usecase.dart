import '../entities/monthly_report.dart';
import '../repositories/report_repository.dart';

class GetMonthlyReportUseCase {
  final ReportRepository repository;

  const GetMonthlyReportUseCase(this.repository);

  Future<MonthlyReport> execute(String monthKey) {
    return repository.getMonthlyReport(monthKey);
  }
}
