import 'dart:typed_data';
import '../repositories/report_repository.dart';

class ExportReportPdfUseCase {
  final ReportRepository repository;

  const ExportReportPdfUseCase(this.repository);

  Future<Uint8List> execute(String monthKey) async {
    final report = await repository.getMonthlyReport(monthKey);
    final transactions = await repository.getTransactionsForReport(monthKey: monthKey);
    return repository.exportReportToPdf(report, transactions);
  }
}
