import 'package:csv/csv.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../../domain/entities/monthly_report.dart';

class CsvExportService {
  const CsvExportService();

  String generateReportCsv(MonthlyReport report, List<TransactionWithDetails> transactions) {
    final rows = <List<dynamic>>[];

    // Header info metadata
    rows.add(['Laporan Keuangan MyFinance']);
    rows.add(['Periode', report.monthKey]);
    rows.add(['Total Pemasukan', report.totalIncome]);
    rows.add(['Total Pengeluaran', report.totalExpense]);
    rows.add(['Arus Kas Bersih (Net Cashflow)', report.netCashflow]);
    rows.add(['Tingkat Tabungan (Savings Rate)', '${(report.savingsRate * 100).toStringAsFixed(1)}%']);
    rows.add([]); // empty row separator

    // Category breakdown section
    rows.add(['Distribusi Pengeluaran per Kategori']);
    rows.add(['Kategori', 'Nominal (Rp)', 'Persentase (%)', 'Jumlah Transaksi']);
    for (final item in report.expenseBreakdown) {
      rows.add([
        item.category.name,
        item.amount,
        (item.percentage * 100).toStringAsFixed(1),
        item.transactionCount,
      ]);
    }
    rows.add([]); // empty row separator

    // Transaction Details Table Header
    rows.add([
      'Tanggal',
      'ID Transaksi',
      'Tipe',
      'Nominal (Rp)',
      'Dompet Asal',
      'Dompet Tujuan',
      'Kategori',
      'Merchant / Penerima',
      'Keterangan',
      'Catatan',
      'Status',
    ]);

    // Rows
    for (final item in transactions) {
      final t = item.transaction;
      final typeLabel = switch (t.type) {
        TransactionType.income => 'Pemasukan',
        TransactionType.expense => 'Pengeluaran',
        TransactionType.transfer => 'Transfer',
      };

      final statusLabel = switch (t.status) {
        TransactionStatus.confirmed => 'Confirmed',
        TransactionStatus.voided => 'Voided',
      };

      rows.add([
        AppDateFormatter.formatDateTime(DateTime.parse(t.occurredAt)),
        t.id,
        typeLabel,
        t.amount,
        item.wallet?.name ?? '',
        item.destinationWallet?.name ?? '',
        item.category?.name ?? '',
        t.merchant ?? '',
        t.description ?? '',
        t.notes ?? '',
        statusLabel,
      ]);
    }

    final csvContent = const ListToCsvConverter().convert(rows);
    // Prepend UTF-8 BOM so Microsoft Excel opens it seamlessly
    return '\uFEFF$csvContent';
  }
}
