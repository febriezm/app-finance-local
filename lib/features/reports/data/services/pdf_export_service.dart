// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../../domain/entities/monthly_report.dart';

class PdfExportService {
  const PdfExportService();

  Future<Uint8List> generateReportPdf(
    MonthlyReport report,
    List<TransactionWithDetails> transactions,
  ) async {
    final pdf = pw.Document();

    final parts = report.monthKey.split('-');
    final reportDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final monthDisplay = AppDateFormatter.formatMonthYear(reportDate);

    // Filter confirmed transactions
    final confirmedTransactions = transactions
        .where((t) => t.transaction.status == TransactionStatus.confirmed)
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MyFinance',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Laporan Keuangan Bulanan',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          monthDisplay,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Dibuat: ${AppDateFormatter.formatDate(DateTime.now())}',
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'MyFinance | Laporan Privat & Aman di Perangkat (Offline-first)',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                  pw.Text(
                    'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // 1. Summary KPI Grid
            pw.Row(
              children: [
                _buildKpiCard(
                  title: 'Total Pemasukan',
                  value: CurrencyFormatter.formatRupiah(report.totalIncome),
                  accentColor: PdfColors.green700,
                  subtext: report.incomeChangePercentage != null
                      ? '${report.incomeChangePercentage! >= 0 ? "+" : ""}${report.incomeChangePercentage!.toStringAsFixed(1)}% vs bln lalu'
                      : null,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  title: 'Total Pengeluaran',
                  value: CurrencyFormatter.formatRupiah(report.totalExpense),
                  accentColor: PdfColors.red700,
                  subtext: report.expenseChangePercentage != null
                      ? '${report.expenseChangePercentage! >= 0 ? "+" : ""}${report.expenseChangePercentage!.toStringAsFixed(1)}% vs bln lalu'
                      : null,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  title: 'Arus Kas Bersih',
                  value: CurrencyFormatter.formatRupiah(report.netCashflow),
                  accentColor: report.isSurplus ? PdfColors.teal700 : PdfColors.amber800,
                  subtext: report.isSurplus ? 'Surplus' : 'Defisit',
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  title: 'Rasio Tabungan',
                  value: '${(report.savingsRate * 100).toStringAsFixed(1)}%',
                  accentColor: PdfColors.blue700,
                  subtext: 'dari pemasukan',
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // 2. Category Breakdown Section
            pw.Text(
              'Distribusi Pengeluaran per Kategori',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            ),
            pw.SizedBox(height: 8),

            if (report.expenseBreakdown.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Center(
                  child: pw.Text('Tidak ada pengeluaran pada periode ini.', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _tableHeaderCell('Kategori'),
                      _tableHeaderCell('Nominal', align: pw.TextAlign.right),
                      _tableHeaderCell('Porsi (%)', align: pw.TextAlign.right),
                      _tableHeaderCell('Transaksi', align: pw.TextAlign.center),
                    ],
                  ),
                  ...report.expenseBreakdown.map((item) {
                    return pw.TableRow(
                      children: [
                        _tableBodyCell(item.category.name),
                        _tableBodyCell(CurrencyFormatter.formatRupiah(item.amount), align: pw.TextAlign.right),
                        _tableBodyCell('${(item.percentage * 100).toStringAsFixed(1)}%', align: pw.TextAlign.right),
                        _tableBodyCell('${item.transactionCount}', align: pw.TextAlign.center),
                      ],
                    );
                  }),
                ],
              ),

            pw.SizedBox(height: 24),

            // 3. Transactions Detail Section
            pw.Text(
              'Daftar Transaksi (${confirmedTransactions.length})',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            ),
            pw.SizedBox(height: 8),

            if (confirmedTransactions.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Center(
                  child: pw.Text('Tidak ada transaksi tercatat.', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _tableHeaderCell('Tanggal'),
                      _tableHeaderCell('Tipe'),
                      _tableHeaderCell('Keterangan / Merchant'),
                      _tableHeaderCell('Dompet'),
                      _tableHeaderCell('Nominal', align: pw.TextAlign.right),
                    ],
                  ),
                  ...confirmedTransactions.map((item) {
                    final t = item.transaction;
                    final isExpense = t.type == TransactionType.expense;
                    final isIncome = t.type == TransactionType.income;
                    final prefix = isIncome ? '+' : (isExpense ? '-' : '');
                    final color = isIncome ? PdfColors.green800 : (isExpense ? PdfColors.red800 : PdfColors.blueGrey800);

                    return pw.TableRow(
                      children: [
                        _tableBodyCell(AppDateFormatter.formatDate(DateTime.parse(t.occurredAt))),
                        _tableBodyCell(t.type.displayName),
                        _tableBodyCell(item.displayTitle),
                        _tableBodyCell(item.wallet?.name ?? (t.type == TransactionType.transfer ? '${item.wallet?.name ?? ""} → ${item.destinationWallet?.name ?? ""}' : '-')),
                        _tableBodyCell('$prefix${CurrencyFormatter.formatRupiah(t.amount)}', align: pw.TextAlign.right, color: color),
                      ],
                    );
                  }),
                ],
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildKpiCard({
    required String title,
    required String value,
    required PdfColor accentColor,
    String? subtext,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          border: pw.Border.all(color: PdfColors.grey200, width: 0.8),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
              ),
            ),
            if (subtext != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                subtext,
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
      ),
    );
  }

  static pw.Widget _tableBodyCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor color = PdfColors.blueGrey900,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8, color: color),
      ),
    );
  }
}
