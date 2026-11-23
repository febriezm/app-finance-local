import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../app/router.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/greeting_helper.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../budgets/domain/entities/budget.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';
import '../../../wallets/domain/entities/wallet.dart';

/// Dashboard / Home Screen — MyFinance Minimal (Quiet, Clean, Premium).
///
/// Karakter Desain:
/// - Typography-first dengan angka finansial tabular figures.
/// - Whitespace sebagai pemisah utama (tanpa card & shadow berlebihan).
/// - Warna fungsional terbatas (hijau income, merah expense, netral untuk saldo).
/// - Quick action pills yang tenang dan ramah sentuhan (touch target >= 44pt).
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with WidgetsBindingObserver {
  Timer? _greetingRefreshTimer;
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleGreetingRefresh();
  }

  @override
  void dispose() {
    _greetingRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        setState(() {});
        _scheduleGreetingRefresh();
      }
    }
  }

  void _scheduleGreetingRefresh() {
    _greetingRefreshTimer?.cancel();
    final duration = GreetingHelper.durationUntilNextPeriod();
    _greetingRefreshTimer = Timer(duration, () {
      if (mounted) {
        setState(() {});
        _scheduleGreetingRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalBalance = ref.watch(netOperationalBalanceProvider);
    final walletsAsync = ref.watch(walletsWithBalanceStreamProvider);
    final recentTransactionsAsync = ref.watch(recentTransactionsStreamProvider);

    // Current month key & streams
    final currentMonthKey = AppDateFormatter.toMonthKey(DateTime.now());
    final budgetProgressAsync = ref.watch(budgetProgressStreamProvider(currentMonthKey));
    final monthlyIncomeAsync = ref.watch(monthlyIncomeProvider(currentMonthKey));
    final monthlyExpenseAsync = ref.watch(monthlyExpenseProvider(currentMonthKey));

    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final bgScaffold = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgScaffold,
      appBar: AppBar(
        title: const Text('MyFinance'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bgScaffold,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 21),
            tooltip: 'Notifikasi',
            onPressed: () {
              AppHaptics.selection();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tidak ada notifikasi baru.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 21),
            tooltip: 'Pengaturan',
            onPressed: () {
              AppHaptics.selection();
              context.push(AppRouter.settings);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        backgroundColor: surfaceColor,
        onRefresh: () async {
          ref.invalidate(walletsWithBalanceStreamProvider);
          ref.invalidate(recentTransactionsStreamProvider);
          ref.invalidate(budgetProgressStreamProvider(currentMonthKey));
          ref.invalidate(monthlyIncomeProvider(currentMonthKey));
          ref.invalidate(monthlyExpenseProvider(currentMonthKey));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // 1. Header & Greeting
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${GreetingHelper.getGreeting()},',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Ringkasan Finansial',
                          style: AppTypography.pageTitle.copyWith(
                            fontSize: 22,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Kas Aktif',
                          style: AppTypography.caption2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Dedicated Balance Card (Focal Point Utama — MyFinance Minimal)
            _buildDedicatedBalanceCard(
              context,
              totalBalance: totalBalance,
              walletsAsync: walletsAsync,
              incomeAsync: monthlyIncomeAsync,
              expenseAsync: monthlyExpenseAsync,
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),

            const SizedBox(height: 14),

            // 3. Quick Actions (Pill Buttons Minimalis)
            Row(
              children: [
                _buildQuickActionPill(
                  context,
                  label: 'Pengeluaran',
                  icon: Icons.arrow_outward_rounded,
                  color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                  onTap: () => AddTransactionSheet.show(context, initialType: TransactionType.expense),
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 8),
                _buildQuickActionPill(
                  context,
                  label: 'Pemasukan',
                  icon: Icons.arrow_downward_rounded,
                  color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                  onTap: () => AddTransactionSheet.show(context, initialType: TransactionType.income),
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 8),
                _buildQuickActionPill(
                  context,
                  label: 'Transfer',
                  icon: Icons.swap_horiz_rounded,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  onTap: () => AddTransactionSheet.show(context, initialType: TransactionType.transfer),
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 4. Ringkasan Anggaran (Budget Summary Flat)
            _buildBudgetSummary(
              context,
              budgetAsync: budgetProgressAsync,
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),

            const SizedBox(height: 22),

            // 6. Dompet & Rekening (Wallets Glance)
            MinimalSectionHeader(
              title: 'Dompet & Rekening',
              actionLabel: 'Lihat Semua',
              onAction: () {
                AppHaptics.selection();
                context.push(AppRouter.wallets);
              },
              padding: const EdgeInsets.only(top: 4, bottom: 10),
            ),
            _buildWalletsHorizontalList(
              context,
              walletsAsync: walletsAsync,
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),

            const SizedBox(height: 22),

            // 7. Transaksi Terkini
            MinimalSectionHeader(
              title: 'Transaksi Terkini',
              actionLabel: 'Lihat Semua',
              onAction: () {
                AppHaptics.selection();
                context.go(AppRouter.transactions);
              },
              padding: const EdgeInsets.only(top: 4, bottom: 8),
            ),
            _buildRecentTransactionsList(
              context,
              recentAsync: recentTransactionsAsync,
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionPill(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDedicatedBalanceCard(
    BuildContext context, {
    required int totalBalance,
    required AsyncValue<List<WalletWithBalance>> walletsAsync,
    required AsyncValue<int> incomeAsync,
    required AsyncValue<int> expenseAsync,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final income = incomeAsync.value ?? 0;
    final expense = expenseAsync.value ?? 0;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textTertiary = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return Container(
      key: const Key('dedicated_balance_card'),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Label + Visibility Toggle + Wallets Glance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'TOTAL SALDO BERSIH',
                        style: AppTypography.caption.copyWith(
                          color: textSecondary,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        AppHaptics.light();
                        setState(() {
                          _isBalanceVisible = !_isBalanceVisible;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          _isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 16,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              walletsAsync.maybeWhen(
                data: (wallets) {
                  final activeCount = wallets.where((w) => !w.wallet.isArchived).length;
                  return Text(
                    '$activeCount Dompet',
                    style: AppTypography.caption2.copyWith(
                      color: textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Hero Balance Amount (Focal Point Utama)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _isBalanceVisible
                ? FinanceAmountText(
                    amount: totalBalance,
                    type: AmountDisplayType.neutral,
                    style: AppTypography.balanceLarge.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  )
                : Text(
                    'Rp ••••••••',
                    style: AppTypography.balanceLarge.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          // 3. Hairline Divider
          Divider(height: 0.8, thickness: 0.8, color: dividerColor),

          const SizedBox(height: 14),

          // 4. Compact Arus Kas Bulan Berjalan (Income & Expense)
          Row(
            children: [
              // Pemasukan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Pemasukan',
                            style: AppTypography.caption2.copyWith(
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: _isBalanceVisible
                          ? FinanceAmountText(
                              amount: income,
                              type: AmountDisplayType.income,
                              showPlusSign: false,
                              style: AppTypography.bodyBold.copyWith(
                                fontSize: 14,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            )
                          : Text(
                              'Rp ••••••',
                              style: AppTypography.bodyBold.copyWith(
                                fontSize: 14,
                                color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // Vertical subtle separator
              const SizedBox(width: 10),
              Container(
                height: 28,
                width: 0.8,
                color: dividerColor,
              ),
              const SizedBox(width: 10),

              // Pengeluaran
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Pengeluaran',
                            style: AppTypography.caption2.copyWith(
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: _isBalanceVisible
                          ? FinanceAmountText(
                              amount: expense,
                              type: AmountDisplayType.expense,
                              showPlusSign: false,
                              style: AppTypography.bodyBold.copyWith(
                                fontSize: 14,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            )
                          : Text(
                              'Rp ••••••',
                              style: AppTypography.bodyBold.copyWith(
                                fontSize: 14,
                                color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSummary(
    BuildContext context, {
    required AsyncValue<BudgetProgress> budgetAsync,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return budgetAsync.maybeWhen(
      data: (progress) {
        if (!progress.hasBudget) {
          return InkWell(
            onTap: () {
              AppHaptics.light();
              context.push(AppRouter.budgets);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 18,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Belum ada anggaran bulan ini',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  Text(
                    'Atur Anggaran',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ],
              ),
            ),
          );
        }

        final pct = (progress.percentage * 100).toStringAsFixed(0);
        final showWarningBadge = progress.status != BudgetStatus.normal;
        final warningColor = progress.status == BudgetStatus.critical || progress.status == BudgetStatus.exceeded
            ? (isDark ? AppColors.expenseDark : AppColors.expenseLight)
            : (isDark ? AppColors.warningDark : AppColors.warningLight);

        return InkWell(
          onTap: () {
            AppHaptics.light();
            context.push(AppRouter.budgets);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
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
                    Row(
                      children: [
                        Text(
                          'Sisa Anggaran: ',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        FinanceAmountText(
                          amount: progress.remaining,
                          type: AmountDisplayType.neutral,
                          style: AppTypography.bodyBold.copyWith(
                            fontSize: 14,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    if (showWarningBadge)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: warningColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: warningColor.withValues(alpha: 0.3), width: 0.6),
                        ),
                        child: Text(
                          progress.status.displayName,
                          style: AppTypography.caption2.copyWith(
                            color: warningColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Text(
                        '$pct%',
                        style: AppTypography.caption2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                BudgetProgressBar(
                  spent: progress.totalSpent,
                  totalLimit: progress.totalLimit,
                  height: 6.0,
                  showLabels: false,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Terpakai ${CurrencyFormatter.formatRupiah(progress.totalSpent)}',
                      style: AppTypography.caption2.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      'Batas ${CurrencyFormatter.formatRupiah(progress.totalLimit)}',
                      style: AppTypography.caption2.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildWalletsHorizontalList(
    BuildContext context, {
    required AsyncValue<List<WalletWithBalance>> walletsAsync,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return walletsAsync.when(
      data: (wallets) {
        final activeWallets = wallets.where((w) => !w.wallet.isArchived).toList();
        if (activeWallets.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 24,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Belum ada dompet aktif',
                    style: AppTypography.body.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRouter.wallets),
                  child: const Text('Tambah'),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: activeWallets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = activeWallets[index];
              final walletColor = AppIcons.parseColor(item.wallet.colorHex);

              return InkWell(
                onTap: () {
                  AppHaptics.light();
                  context.push(AppRouter.wallets);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 154,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: walletColor.withValues(alpha: isDark ? 0.2 : 0.12),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              AppIcons.getIcon(item.wallet.iconKey),
                              color: walletColor,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.wallet.name,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.wallet.type.displayName,
                            style: AppTypography.caption2.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 1),
                          FinanceAmountText(
                            amount: item.currentBalance,
                            type: AmountDisplayType.neutral,
                            style: AppTypography.bodyBold.copyWith(
                              fontSize: 13,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecentTransactionsList(
    BuildContext context, {
    required AsyncValue<List<TransactionWithDetails>> recentAsync,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return recentAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 32,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada transaksi',
                  style: AppTypography.body.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => AddTransactionSheet.show(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor, width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                  ),
                  child: const Text('Catat Transaksi'),
                ),
              ],
            ),
          );
        }

        final displayList = transactions.take(5).toList();
        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: displayList.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return TransactionListTile(
                item: item,
                showDivider: index < displayList.length - 1,
                onTap: () {
                  AppHaptics.selection();
                  context.go(AppRouter.transactions);
                },
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Gagal memuat mutasi transaksi terbaru.',
          style: AppTypography.caption,
        ),
      ),
    );
  }
}
