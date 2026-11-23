import 'package:flutter/material.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../domain/entities/monthly_report.dart';

/// Kartu ringkasan perbandingan metrik finansial vs bulan lalu — MyFinance Minimal.
class MonthComparisonCard extends StatelessWidget {
  final MonthlyReport report;

  const MonthComparisonCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPreviousData = report.previousMonthIncome > 0 || report.previousMonthExpense > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MinimalSectionHeader(
          title: 'Perbandingan vs Bulan Lalu',
        ),
        if (!hasPreviousData)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'Belum ada data transaksi pada bulan sebelumnya untuk dibandingkan.',
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              ),
            ),
          )
        else ...[
          FinanceSummaryRow(
            label: 'Pemasukan',
            customValue:
                '${CurrencyFormatter.formatRupiah(report.totalIncome)} (${_formatPercentage(report.incomeChangePercentage)})',
            valueColor: report.incomeChangePercentage != null && report.incomeChangePercentage! >= 0
                ? (isDark ? AppColors.incomeDark : AppColors.incomeLight)
                : (isDark ? AppColors.expenseDark : AppColors.expenseLight),
          ),
          FinanceSummaryRow(
            label: 'Pengeluaran',
            customValue:
                '${CurrencyFormatter.formatRupiah(report.totalExpense)} (${_formatPercentage(report.expenseChangePercentage)})',
            valueColor: report.expenseChangePercentage != null && report.expenseChangePercentage! <= 0
                ? (isDark ? AppColors.incomeDark : AppColors.incomeLight)
                : (isDark ? AppColors.expenseDark : AppColors.expenseLight),
          ),
          if (report.netCashflowChangePercentage != null)
            FinanceSummaryRow(
              label: 'Arus Kas Bersih',
              customValue:
                  '${CurrencyFormatter.formatRupiah(report.netCashflow)} (${_formatPercentage(report.netCashflowChangePercentage)})',
              valueColor: report.netCashflow >= 0
                  ? (isDark ? AppColors.incomeDark : AppColors.incomeLight)
                  : (isDark ? AppColors.expenseDark : AppColors.expenseLight),
              showDivider: false,
            ),
        ],
      ],
    );
  }

  String _formatPercentage(double? pct) {
    if (pct == null) return '0%';
    final sign = pct > 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }
}
