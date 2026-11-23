import 'dart:typed_data';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../entities/monthly_report.dart';

abstract interface class ReportRepository {
  /// Mengambil data agregasi laporan bulanan (lengkap dengan breakdown kategori, dompet, dan delta bulan lalu)
  Future<MonthlyReport> getMonthlyReport(String monthKey);

  /// Mengambil daftar transaksi yang membentuk angka laporan pada periode yang dipilih
  Future<List<TransactionWithDetails>> getTransactionsForReport({
    required String monthKey,
    String? categoryId,
    String? walletId,
  });

  /// Mengenerate berkas CSV dari laporan bulanan
  Future<String> exportReportToCsv(
    MonthlyReport report,
    List<TransactionWithDetails> transactions,
  );

  /// Mengenerate berkas PDF cetak dari laporan bulanan
  Future<Uint8List> exportReportToPdf(
    MonthlyReport report,
    List<TransactionWithDetails> transactions,
  );
}
