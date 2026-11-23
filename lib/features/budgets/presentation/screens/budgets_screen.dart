import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/budget.dart';

/// Halaman Anggaran Bulanan — MyFinance Minimal (Quiet, Clean, Premium).
///
/// Karakter Desain:
/// - Month selector terintegrasi (MinimalMonthSelector).
/// - Tipografi hening dengan tabular figures untuk nominal uang.
/// - Progress bar tipis (BudgetProgressBar) tanpa gradient tebal.
/// - Warna fungsional terbatas: peringatan hanya muncul saat mendekati/melebihi limit.
/// - List alokasi kategori flat dengan hairline divider.
/// - Empty state yang bersih dan minimalis.
class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  void _openSetBudgetModal(BuildContext context, BudgetProgress progress) {
    AppHaptics.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SetBudgetModal(
        monthKey: progress.monthKey,
        currentProgress: progress,
      ),
    );
  }

  Color _getStatusColor(BudgetStatus status, bool isDark) {
    switch (status) {
      case BudgetStatus.normal:
        return isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
      case BudgetStatus.warning:
        return isDark ? AppColors.warningDark : AppColors.warningLight;
      case BudgetStatus.critical:
        return const Color(0xFFE17055);
      case BudgetStatus.exceeded:
        return isDark ? AppColors.expenseDark : AppColors.expenseLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMonthKey = ref.watch(selectedBudgetMonthProvider);
    final budgetProgressAsync = ref.watch(budgetProgressStreamProvider(currentMonthKey));

    final parts = currentMonthKey.split('-');
    final currentMonthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
    final monthDisplay = AppDateFormatter.formatMonthYear(currentMonthDate);

    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final bgScaffold = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgScaffold,
      appBar: AppBar(
        title: const Text('Anggaran Bulanan'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bgScaffold,
        actions: [
          budgetProgressAsync.maybeWhen(
            data: (progress) => IconButton(
              icon: const Icon(Icons.tune_rounded, size: 21),
              tooltip: 'Atur Anggaran',
              onPressed: () => _openSetBudgetModal(context, progress),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: budgetProgressAsync.when(
        data: (progress) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // 1. Month Selector
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MinimalMonthSelector(
                  currentMonth: currentMonthDate,
                  onMonthChanged: (newDate) {
                    ref.read(selectedBudgetMonthProvider.notifier).state = AppDateFormatter.toMonthKey(newDate);
                  },
                ),
              ),

              // 2. Configuration Warning Banner jika alokasi kategori melebihi total limit
              if (progress.hasConfigurationWarning) ...[
                _buildConfigurationWarning(isDark, borderColor),
                const SizedBox(height: 14),
              ],

              // 3. Main Budget Overview
              if (progress.hasBudget)
                _buildMainBudgetOverview(context, progress, isDark, surfaceColor, borderColor)
              else
                _buildEmptyBudgetOverview(context, progress, monthDisplay, isDark, surfaceColor, borderColor),

              const SizedBox(height: 24),

              // 4. Category Limits Section
              _buildCategoryLimitsSection(context, progress, isDark, surfaceColor, borderColor),

              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(child: LoadingIndicator(message: 'Memuat data anggaran...')),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Belum dapat memuat data anggaran. Silakan muat ulang.',
              style: AppTypography.body.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationWarning(bool isDark, Color borderColor) {
    final warningColor = isDark ? AppColors.warningDark : AppColors.warningLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningColor.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: warningColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perhatian Konfigurasi Anggaran',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: warningColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total alokasi kategori melebihi total anggaran bulanan. Pengeluaran aktual tetap dihitung secara akurat.',
                  style: AppTypography.caption2.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBudgetOverview(
    BuildContext context,
    BudgetProgress progress,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    final statusColor = _getStatusColor(progress.status, isDark);
    final percentLabel = (progress.percentage * 100).toStringAsFixed(0);
    final isNearOrOver = progress.status != BudgetStatus.normal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress.remaining >= 0 ? 'Sisa Anggaran' : 'Defisit Anggaran',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  letterSpacing: 0.2,
                ),
              ),
              if (isNearOrOver)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 0.6),
                  ),
                  child: Text(
                    progress.status.displayName,
                    style: AppTypography.caption2.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Text(
                  '$percentLabel%',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          FinanceAmountText(
            amount: progress.remaining,
            type: AmountDisplayType.neutral,
            style: AppTypography.balanceLarge.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              color: progress.remaining >= 0
                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                  : (isDark ? AppColors.expenseDark : AppColors.expenseLight),
            ),
          ),
          const SizedBox(height: 14),
          BudgetProgressBar(
            spent: progress.totalSpent,
            totalLimit: progress.totalLimit,
            height: 6.0,
            showLabels: false,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terpakai ($percentLabel%)',
                    style: AppTypography.caption2.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FinanceAmountText(
                    amount: progress.totalSpent,
                    type: AmountDisplayType.neutral,
                    style: AppTypography.bodyBold.copyWith(fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Batas Anggaran',
                    style: AppTypography.caption2.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FinanceAmountText(
                    amount: progress.totalLimit,
                    type: AmountDisplayType.neutral,
                    style: AppTypography.bodyBold.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBudgetOverview(
    BuildContext context,
    BudgetProgress progress,
    String monthDisplay,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            size: 38,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum Ada Anggaran',
            style: AppTypography.sectionTitle.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Tetapkan batas pengeluaran untuk bulan $monthDisplay agar keuangan Anda tetap sehat.',
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Atur Anggaran Bulan Ini'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: borderColor, width: 0.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            onPressed: () => _openSetBudgetModal(context, progress),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryLimitsSection(
    BuildContext context,
    BudgetProgress progress,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MinimalSectionHeader(
          title: 'Alokasi Kategori',
          actionLabel: 'Sesuaikan',
          onAction: () => _openSetBudgetModal(context, progress),
          padding: const EdgeInsets.only(top: 4, bottom: 8),
        ),
        if (progress.categoryProgresses.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Belum ada limit spesifik kategori. Seluruh pengeluaran dihitung pada total anggaran bulanan.',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Column(
              children: progress.categoryProgresses.asMap().entries.map((entry) {
                final index = entry.key;
                final catProgress = entry.value;
                final statusColor = _getStatusColor(catProgress.status, isDark);
                final isNearOrOver = catProgress.status != BudgetStatus.normal;
                final catPercent = (catProgress.percentage * 100).toStringAsFixed(0);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor, width: 0.6),
                                ),
                                child: Icon(
                                  AppIcons.getIcon(catProgress.category.iconKey),
                                  size: 16,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      catProgress.category.name,
                                      style: AppTypography.bodyBold.copyWith(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      catProgress.remainingAmount >= 0
                                          ? 'Sisa ${CurrencyFormatter.formatRupiah(catProgress.remainingAmount)}'
                                          : 'Melebihi ${CurrencyFormatter.formatRupiah(catProgress.remainingAmount.abs())}',
                                      style: AppTypography.caption.copyWith(
                                        color: catProgress.remainingAmount >= 0
                                            ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                                            : (isDark ? AppColors.expenseDark : AppColors.expenseLight),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$catPercent%',
                                    style: AppTypography.bodyBold.copyWith(
                                      fontSize: 14,
                                      color: isNearOrOver
                                          ? statusColor
                                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${CurrencyFormatter.formatCompact(catProgress.spentAmount)} / ${CurrencyFormatter.formatCompact(catProgress.limitAmount)}',
                                    style: AppTypography.caption2.copyWith(
                                      color: isDark ? AppColors.textDisabledDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          BudgetProgressBar(
                            spent: catProgress.spentAmount,
                            totalLimit: catProgress.limitAmount,
                            height: 4.0,
                            showLabels: false,
                          ),
                        ],
                      ),
                    ),
                    if (index < progress.categoryProgresses.length - 1)
                      Divider(height: 1, thickness: 0.6, color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

/// Modal Sheet untuk mengatur Total Budget & Limit Kategori
class _SetBudgetModal extends ConsumerStatefulWidget {
  final String monthKey;
  final BudgetProgress currentProgress;

  const _SetBudgetModal({
    required this.monthKey,
    required this.currentProgress,
  });

  @override
  ConsumerState<_SetBudgetModal> createState() => _SetBudgetModalState();
}

class _SetBudgetModalState extends ConsumerState<_SetBudgetModal> {
  final TextEditingController _totalBudgetController = TextEditingController();
  final Map<String, TextEditingController> _categoryControllers = {};
  final Map<String, int> _categoryAmounts = {};

  int _totalBudget = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _totalBudget = widget.currentProgress.totalLimit;
    if (_totalBudget > 0) {
      _totalBudgetController.text = CurrencyFormatter.formatRupiah(_totalBudget);
    }

    for (final cp in widget.currentProgress.categoryProgresses) {
      _categoryAmounts[cp.category.id] = cp.limitAmount;
    }
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    for (final c in _categoryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTotalBudgetChanged(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    final num = int.tryParse(clean) ?? 0;
    setState(() {
      _totalBudget = num;
    });
    final formatted = num > 0 ? CurrencyFormatter.formatRupiah(num) : '';
    if (_totalBudgetController.text != formatted) {
      _totalBudgetController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _onCategoryLimitChanged(String catId, String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    final num = int.tryParse(clean) ?? 0;
    setState(() {
      if (num > 0) {
        _categoryAmounts[catId] = num;
      } else {
        _categoryAmounts.remove(catId);
      }
    });

    final controller = _categoryControllers[catId];
    if (controller != null) {
      final formatted = num > 0 ? CurrencyFormatter.formatRupiah(num) : '';
      if (controller.text != formatted) {
        controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  int get _sumCategoryLimits {
    return _categoryAmounts.values.fold<int>(0, (sum, val) => sum + val);
  }

  Future<void> _save() async {
    if (_totalBudget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total batas anggaran harus lebih besar dari Rp 0.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final success = await ref.read(budgetsControllerProvider.notifier).saveBudget(
          monthKey: widget.monthKey,
          totalLimit: _totalBudget,
          categoryLimitsMap: _categoryAmounts,
        );
    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        unawaited(AppHaptics.light());
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anggaran bulanan berhasil disimpan.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan anggaran. Silakan periksa data.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider(CategoryType.expense));
    final sumCategories = _sumCategoryLimits;
    final isOverAllocated = sumCategories > _totalBudget && _totalBudget > 0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isMobile = MediaQuery.of(context).size.width < 600 ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;

    final effectiveBottomPadding = isMobile
        ? math.max(bottomInset + 120, 380.0)
        : math.max(bottomInset + 20, 40.0);
    final fieldScrollPadding = isMobile
        ? const EdgeInsets.only(bottom: 380)
        : const EdgeInsets.all(20);

    final parts = widget.monthKey.split('-');
    final monthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final monthTitle = AppDateFormatter.formatMonthYear(monthDate);

    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final cardBg = isDark ? const Color(0xFF191919) : const Color(0xFFF9FAFB);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    AppHaptics.selection();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                Text(
                  'Atur Anggaran ($monthTitle)',
                  style: AppTypography.pageTitle.copyWith(fontSize: 16),
                ),
                TextButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.6, color: isDark ? AppColors.dividerDark : AppColors.dividerLight),

          // Scrollable Form
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(16, 16, 16, effectiveBottomPadding),
                children: [
                  // Total Limit Input
                  Text(
                    'TOTAL ANGGARAN BULANAN',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: _totalBudgetController,
                      keyboardType: TextInputType.number,
                      scrollPadding: fieldScrollPadding,
                      style: AppTypography.bodyBold.copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Rp 0',
                        hintStyle: AppTypography.body.copyWith(
                          color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: _onTotalBudgetChanged,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status Alokasi Kategori
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isOverAllocated
                          ? (isDark ? AppColors.warningDark.withValues(alpha: 0.1) : AppColors.warningLight.withValues(alpha: 0.1))
                          : cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOverAllocated
                            ? (isDark ? AppColors.warningDark : AppColors.warningLight)
                            : borderColor,
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Alokasi Kategori:',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            FinanceAmountText(
                              amount: sumCategories,
                              type: AmountDisplayType.neutral,
                              style: AppTypography.bodyBold.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                        if (isOverAllocated) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 15,
                                color: isDark ? AppColors.warningDark : AppColors.warningLight,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Alokasi kategori melebihi total anggaran. Data tetap dapat disimpan.',
                                  style: AppTypography.caption2.copyWith(
                                    color: isDark ? AppColors.warningDark : AppColors.warningLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Category Limits List Header
                  Text(
                    'BATAS PENGELUARAN PER KATEGORI (OPSIONAL)',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tentukan batas maksimal untuk kategori tertentu. Kosongkan jika tidak ada batas khusus.',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.textDisabledDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category List
                  categoriesAsync.when(
                    data: (categories) {
                      if (categories.isEmpty) {
                        return const Center(child: Text('Belum ada kategori pengeluaran aktif.'));
                      }

                      return Column(
                        children: categories.map((cat) {
                          // Buat controller jika belum ada
                          if (!_categoryControllers.containsKey(cat.id)) {
                            final savedAmount = _categoryAmounts[cat.id] ?? 0;
                            _categoryControllers[cat.id] = TextEditingController(
                              text: savedAmount > 0 ? CurrencyFormatter.formatRupiah(savedAmount) : '',
                            );
                          }
                          final ctrl = _categoryControllers[cat.id]!;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor, width: 0.8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      AppIcons.getIcon(cat.iconKey),
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      cat.name,
                                      style: AppTypography.bodyMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 4,
                                    child: TextField(
                                      controller: ctrl,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.end,
                                      scrollPadding: fieldScrollPadding,
                                      style: AppTypography.bodyBold.copyWith(fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'Tanpa batas',
                                        hintStyle: AppTypography.caption.copyWith(
                                          color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
                                        ),
                                        isDense: true,
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                      ),
                                      onChanged: (val) => _onCategoryLimitChanged(cat.id, val),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Gagal memuat kategori anggaran.', style: TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tombol Simpan Utama
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                            )
                          : const Text(
                              'Simpan Anggaran',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
