import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';
import '../../domain/entities/monthly_report.dart';
import '../widgets/export_sheet.dart';
import '../widgets/month_comparison_card.dart';
import '../widgets/report_transactions_sheet.dart';
import '../widgets/wallet_breakdown_list.dart';

/// Halaman Laporan Keuangan (Reports) — MyFinance Minimal (Quiet, Clean, Premium).
///
/// Karakter Desain:
/// - Fokus pada kejelasan membaca data finansial (readability & financial insights).
/// - Tipografi kuat dengan tabular figures untuk setiap nilai mata uang.
/// - Menghindari card bertumpuk untuk setiap data statistik.
/// - Chart arus kas minimalis (Income vs Expense) proporsional dan mudah dipahami.
/// - Rincian kategori dan akun dompet yang bersih dengan hairline divider.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedTab = 0; // 0: Pengeluaran, 1: Pemasukan, 2: Dompet

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMonthKey = ref.watch(selectedReportMonthProvider);
    final reportAsync = ref.watch(monthlyReportProvider(currentMonthKey));

    final parts = currentMonthKey.split('-');
    final currentMonthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final monthDisplay = AppDateFormatter.formatMonthYear(currentMonthDate);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          MinimalIconButton(
            icon: Icons.ios_share_rounded,
            tooltip: 'Ekspor Laporan (PDF / CSV)',
            onPressed: () => ExportSheet.show(context, currentMonthKey),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(monthlyReportProvider(currentMonthKey));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          children: [
            // 1. Month Selector Minimalis
            MinimalMonthSelector(
              currentMonth: currentMonthDate,
              onMonthChanged: (newDate) {
                ref.read(selectedReportMonthProvider.notifier).state =
                    AppDateFormatter.toMonthKey(newDate);
              },
            ),

            const SizedBox(height: 16),

            reportAsync.when(
              data: (report) {
                if (report.totalTransactionsCount == 0) {
                  return Column(
                    children: [
                      const SizedBox(height: 36),
                      EmptyState(
                        icon: Icons.bar_chart_outlined,
                        title: 'Belum Ada Transaksi',
                        message: 'Tidak ada transaksi tercatat pada bulan $monthDisplay.',
                        actionLabel: 'Catat Transaksi',
                        onActionPressed: () => AddTransactionSheet.show(context),
                      ),
                      const SizedBox(height: 48),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Net Cashflow (Arus Kas Bersih) Header
                    _buildNetCashflowSection(report, isDark),

                    const SizedBox(height: 24),
                    Divider(
                      height: 1,
                      thickness: 0.6,
                      color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    ),
                    const SizedBox(height: 20),

                    // 3. Ringkasan Pemasukan & Pengeluaran Berdampingan
                    _buildIncomeExpenseRow(report, isDark),

                    const SizedBox(height: 28),

                    // 4. Chart Income vs Expense Minimalis
                    const MinimalSectionHeader(
                      title: 'Perbandingan Arus Kas',
                    ),
                    const SizedBox(height: 8),
                    _buildMinimalCashflowChart(report, isDark),

                    const SizedBox(height: 28),

                    // 5. Insight Finansial & Perbandingan vs Bulan Lalu
                    MonthComparisonCard(report: report),

                    const SizedBox(height: 28),

                    // 6. Segmented Switcher untuk Rincian
                    MinimalSectionHeader(
                      title: 'Rincian Transaksi',
                      actionLabel: _selectedTab == 0
                          ? '${report.expenseBreakdown.length} kategori'
                          : _selectedTab == 1
                              ? '${report.incomeBreakdown.length} kategori'
                              : '${report.walletBreakdown.length} akun',
                    ),
                    const SizedBox(height: 10),
                    _buildSegmentedTab(isDark),

                    const SizedBox(height: 16),

                    // 7. Rincian Konten Tab
                    if (_selectedTab == 0)
                      _buildCategoryBreakdownList(
                        items: report.expenseBreakdown,
                        totalAmount: report.totalExpense,
                        isDark: isDark,
                        emptyMessage: 'Tidak ada pengeluaran pada bulan ini.',
                        currentMonthKey: currentMonthKey,
                      )
                    else if (_selectedTab == 1)
                      _buildCategoryBreakdownList(
                        items: report.incomeBreakdown,
                        totalAmount: report.totalIncome,
                        isDark: isDark,
                        emptyMessage: 'Tidak ada pemasukan pada bulan ini.',
                        currentMonthKey: currentMonthKey,
                      )
                    else
                      WalletBreakdownList(
                        items: report.walletBreakdown,
                        isDark: isDark,
                        onWalletTap: (wItem) {
                          ReportTransactionsSheet.show(
                            context,
                            monthKey: currentMonthKey,
                            title: wItem.wallet.name,
                            walletId: wItem.wallet.id,
                          );
                        },
                      ),

                    const SizedBox(height: 48),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 320,
                child: Center(child: LoadingIndicator(message: 'Menganalisis laporan...')),
              ),
              error: (e, _) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Belum dapat memuat data laporan. Silakan muat ulang.',
                    style: AppTypography.subhead,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Arus Kas Bersih (Net Cashflow) — Bagian Utama dengan Tipografi Elegan
  Widget _buildNetCashflowSection(MonthlyReport report, bool isDark) {
    final savingsRatePercent = (report.savingsRate * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'ARUS KAS BERSIH',
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: report.isSurplus
                    ? (isDark ? AppColors.incomeContainerDark : AppColors.incomeContainerLight)
                    : (isDark ? AppColors.expenseContainerDark : AppColors.expenseContainerLight),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    report.isSurplus ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 13,
                    color: report.isSurplus
                        ? (isDark ? AppColors.incomeDark : AppColors.incomeLight)
                        : (isDark ? AppColors.expenseDark : AppColors.expenseLight),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    report.isSurplus ? 'Surplus' : 'Defisit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: report.isSurplus
                          ? (isDark ? AppColors.incomeDark : AppColors.incomeLight)
                          : (isDark ? AppColors.expenseDark : AppColors.expenseLight),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FinanceAmountText(
          amount: report.netCashflow,
          type: AmountDisplayType.auto,
          style: AppTypography.balanceLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Tingkat Tabungan: $savingsRatePercent% dari total pemasukan',
          style: AppTypography.caption.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  /// Ringkasan Pemasukan & Pengeluaran 2-Kolom Flat
  Widget _buildIncomeExpenseRow(MonthlyReport report, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PEMASUKAN',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              FinanceAmountText(
                amount: report.totalIncome,
                type: AmountDisplayType.income,
                style: AppTypography.balanceMedium,
              ),
            ],
          ),
        ),
        Container(
          width: 1,
          height: 38,
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PENGELUARAN',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              FinanceAmountText(
                amount: report.totalExpense,
                type: AmountDisplayType.expense,
                style: AppTypography.balanceMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Minimalist Cashflow Chart: Proportional Vertical Bars & Horizontal Ratio Track
  Widget _buildMinimalCashflowChart(MonthlyReport report, bool isDark) {
    final total = report.totalIncome + report.totalExpense;
    final maxAmount = math.max(report.totalIncome, report.totalExpense);

    final incomeRatio = maxAmount > 0 ? (report.totalIncome / maxAmount).clamp(0.08, 1.0) : 0.08;
    final expenseRatio = maxAmount > 0 ? (report.totalExpense / maxAmount).clamp(0.08, 1.0) : 0.08;

    final incomePercent = total > 0 ? ((report.totalIncome / total) * 100).toStringAsFixed(0) : '0';
    final expensePercent = total > 0 ? ((report.totalExpense / total) * 100).toStringAsFixed(0) : '0';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          // Visual Dual Vertical Bars
          SizedBox(
            height: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Income Bar Column
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$incomePercent%',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 44,
                      height: 72 * incomeRatio,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pemasukan',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                // Center Divider Line
                Container(
                  width: 1,
                  height: 80,
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                ),
                // Expense Bar Column
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$expensePercent%',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 44,
                      height: 72 * expenseRatio,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pengeluaran',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Divider(
            height: 1,
            thickness: 0.6,
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          const SizedBox(height: 14),

          // Proportional Horizontal Ratio Bar
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    if (report.totalIncome > 0)
                      Expanded(
                        flex: report.totalIncome,
                        child: Container(
                          color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                        ),
                      ),
                    if (report.totalIncome > 0 && report.totalExpense > 0)
                      const SizedBox(width: 2),
                    if (report.totalExpense > 0)
                      Expanded(
                        flex: report.totalExpense,
                        child: Container(
                          color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Masuk: $incomePercent%',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Keluar: $expensePercent%',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Segmented Switcher untuk Tab Pilihan Rincian
  Widget _buildSegmentedTab(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'Pengeluaran',
              isSelected: _selectedTab == 0,
              isDark: isDark,
              onTap: () {
                unawaited(AppHaptics.selection());
                setState(() => _selectedTab = 0);
              },
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'Pemasukan',
              isSelected: _selectedTab == 1,
              isDark: isDark,
              onTap: () {
                unawaited(AppHaptics.selection());
                setState(() => _selectedTab = 1);
              },
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'Dompet',
              isSelected: _selectedTab == 2,
              isDark: isDark,
              onTap: () {
                unawaited(AppHaptics.selection());
                setState(() => _selectedTab = 2);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.surfaceModalDark : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.subhead.copyWith(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }

  /// Rincian Kategori Minimalis dengan Progress Bar Tipis
  Widget _buildCategoryBreakdownList({
    required List<CategoryReportItem> items,
    required int totalAmount,
    required bool isDark,
    required String emptyMessage,
    required String currentMonthKey,
  }) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            emptyMessage,
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
            ),
          ),
        ),
      );
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        final catColor = AppIcons.parseColor(item.category.colorHex);
        final percentDisplay = (item.percentage * 100).toStringAsFixed(1);

        return Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                unawaited(AppHaptics.light());
                ReportTransactionsSheet.show(
                  context,
                  monthKey: currentMonthKey,
                  title: item.category.name,
                  categoryId: item.category.id,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: catColor.withValues(alpha: isDark ? 0.4 : 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            AppIcons.getIcon(item.category.iconKey),
                            color: isDark ? Colors.white : catColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.category.name,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${item.transactionCount} transaksi',
                                style: AppTypography.caption.copyWith(
                                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FinanceAmountText(
                              amount: item.amount,
                              type: AmountDisplayType.neutral,
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '$percentDisplay%',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: item.percentage.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                        valueColor: AlwaysStoppedAnimation<Color>(catColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (idx < items.length - 1)
              Divider(
                height: 1,
                thickness: 0.6,
                indent: 48,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
          ],
        );
      }).toList(),
    );
  }
}
