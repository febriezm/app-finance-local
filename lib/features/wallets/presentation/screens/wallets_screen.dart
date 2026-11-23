import 'dart:async';
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
import '../../../reports/presentation/widgets/report_transactions_sheet.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';
import '../../domain/entities/wallet.dart';

/// Halaman Dompet & Rekening — MyFinance Minimal (Quiet, Clean, Premium).
///
/// Karakter Desain:
/// - Total balance minimalis tanpa card bertumpuk.
/// - Daftar dompet terkelompok (Grouped List): Rekening Bank, Kas Tunai, E-Wallet, Lainnya.
/// - Setiap akun menggunakan [WalletListTile] dengan icon sederhana, typography bersih, angka tabular, dan divider tipis.
/// - Mempertahankan seluruh fitur: Tambah, Edit, Detail, Arsip/Aktifkan, Riwayat Mutasi, dan Transfer.
class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen> {
  bool _isBalanceVisible = true;

  void _showAddWalletSheet(BuildContext context) {
    unawaited(AppHaptics.selection());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddWalletModal(),
    );
  }

  void _showEditWalletSheet(BuildContext context, Wallet wallet) {
    unawaited(AppHaptics.selection());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditWalletModal(wallet: wallet),
    );
  }

  void _showWalletDetailSheet(BuildContext context, WidgetRef ref, WalletWithBalance item) {
    unawaited(AppHaptics.light());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArchived = item.wallet.isArchived;
    final walletColor = AppIcons.parseColor(item.wallet.colorHex);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceModalDark : AppColors.surfaceModalLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Wallet Header (Icon, Name, Type)
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: walletColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: walletColor.withValues(alpha: isDark ? 0.4 : 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      AppIcons.getIcon(item.wallet.iconKey),
                      color: isDark ? Colors.white : walletColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.wallet.name,
                                style: AppTypography.title3.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isArchived) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Arsip',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.wallet.type.displayName,
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (isArchived) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dompet ini diarsipkan sebagai cadangan dan tidak muncul sebagai opsi sumber dana transaksi.',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? Colors.orange.shade200 : Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Saldo Berjalan (Large Focus)
              Text(
                'SALDO BERJALAN',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              FinanceAmountText(
                amount: item.currentBalance,
                type: AmountDisplayType.auto,
                style: AppTypography.balanceMedium,
                color: item.currentBalance >= 0
                    ? (isDark ? AppColors.incomeDark : AppColors.incomeLight)
                    : (isDark ? AppColors.expenseDark : AppColors.expenseLight),
              ),

              const SizedBox(height: 20),
              Divider(
                height: 1,
                thickness: 0.6,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              const SizedBox(height: 12),

              // Detail List (Quiet Key-Value pairs)
              FinanceSummaryRow(
                label: 'Saldo Awal',
                customValue: CurrencyFormatter.formatRupiah(item.wallet.openingBalance),
              ),
              const SizedBox(height: 8),
              FinanceSummaryRow(
                label: 'Tipe Akun',
                customValue: item.wallet.type.displayName,
              ),
              const SizedBox(height: 8),
              FinanceSummaryRow(
                label: 'Mata Uang',
                customValue: item.wallet.currencyCode,
              ),
              const SizedBox(height: 8),
              FinanceSummaryRow(
                label: 'Status',
                customValue: isArchived ? 'Diarsipkan (Cadangan)' : 'Aktif',
              ),

              const SizedBox(height: 24),
              Divider(
                height: 1,
                thickness: 0.6,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              const SizedBox(height: 16),

              // Action Buttons
              // 1. Mutasi Transaksi
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('Riwayat Mutasi Transaksi'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 0.8,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ReportTransactionsSheet.show(
                      context,
                      monthKey: AppDateFormatter.toMonthKey(DateTime.now()),
                      title: 'Mutasi ${item.wallet.name}',
                      walletId: item.wallet.id,
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // 2. Transfer Antar Dompet (hanya jika aktif)
              if (!isArchived) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Transfer dari Dompet Ini'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      AddTransactionSheet.show(
                        context,
                        initialType: TransactionType.transfer,
                        initialWalletId: item.wallet.id,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // 3. Edit & Arsip Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 0.8,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _showEditWalletSheet(context, item.wallet);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: isArchived
                        ? OutlinedButton.icon(
                            icon: const Icon(Icons.unarchive_outlined, size: 18, color: Colors.green),
                            label: const Text(
                              'Aktifkan',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Colors.green, width: 0.8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              final confirm = await MinimalDialog.showConfirm(
                                context,
                                title: 'Aktifkan Kembali Dompet?',
                                message: 'Dompet "${item.wallet.name}" akan kembali ke daftar aktif dan dapat dipilih sebagai sumber dana transaksi.',
                                confirmText: 'Aktifkan',
                                confirmColor: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                              );

                              if (confirm == true) {
                                await ref.read(walletsControllerProvider.notifier).unarchiveWallet(item.wallet.id);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Dompet "${item.wallet.name}" diaktifkan kembali.')),
                                  );
                                }
                              }
                            },
                          )
                        : OutlinedButton.icon(
                            icon: const Icon(Icons.archive_outlined, size: 18, color: Colors.orange),
                            label: const Text(
                              'Arsipkan',
                              style: TextStyle(color: Colors.orange),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Colors.orange, width: 0.8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              final confirm = await MinimalDialog.showConfirm(
                                context,
                                title: 'Arsipkan Dompet?',
                                message: 'Dompet "${item.wallet.name}" akan dipindahkan ke daftar arsip cadangan. Riwayat mutasi transaksi tetap tersimpan utuh.',
                                confirmText: 'Arsipkan',
                                confirmColor: Colors.orange,
                              );

                              if (confirm == true) {
                                await ref.read(walletsControllerProvider.notifier).archiveWallet(item.wallet.id);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Dompet "${item.wallet.name}" berhasil diarsipkan.')),
                                  );
                                }
                              }
                            },
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDedicatedAssetCard(
    BuildContext context, {
    required int totalBalance,
    required List<WalletWithBalance> wallets,
    required List<WalletWithBalance> archivedWallets,
    required List<WalletWithBalance> bankWallets,
    required List<WalletWithBalance> cashWallets,
    required List<WalletWithBalance> eWalletWallets,
    required List<WalletWithBalance> otherWallets,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textTertiary = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    final bankAndCashTotal = (bankWallets + cashWallets).fold<int>(0, (sum, w) => sum + w.currentBalance);
    final eWalletAndOtherTotal = (eWalletWallets + otherWallets).fold<int>(0, (sum, w) => sum + w.currentBalance);

    final walletCountLabel = archivedWallets.isNotEmpty
        ? '${wallets.length} Aktif • ${archivedWallets.length} Arsip'
        : '${wallets.length} Dompet Aktif';

    return Container(
      key: const Key('dedicated_asset_balance_card'),
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
                        'TOTAL SALDO ASET',
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
              Text(
                walletCountLabel,
                style: AppTypography.caption2.copyWith(
                  color: textTertiary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
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

          // 4. Compact Asset Breakdown
          Row(
            children: [
              // Kas & Bank
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
                            'Kas & Bank',
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
                              amount: bankAndCashTotal,
                              type: AmountDisplayType.neutral,
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
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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

              // E-Wallet & Lainnya
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
                            color: isDark ? AppColors.transferDark : AppColors.transferLight,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'E-Wallet & Lainnya',
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
                              amount: eWalletAndOtherTotal,
                              type: AmountDisplayType.neutral,
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
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletsAsync = ref.watch(walletsWithBalanceStreamProvider);
    final archivedWalletsAsync = ref.watch(archivedWalletsWithBalanceStreamProvider);
    final totalBalance = ref.watch(totalAllAssetBalanceProvider);

    final archivedWallets = archivedWalletsAsync.asData?.value ?? [];
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Dompet & Rekening'),
        actions: [
          MinimalIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Tambah Dompet',
            onPressed: () => _showAddWalletSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: walletsAsync.when(
        data: (wallets) {
          if (wallets.isEmpty && archivedWallets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Belum Ada Dompet',
                  message: 'Tambahkan dompet pertama Anda (rekening bank, kas tunai, atau e-wallet) untuk mulai mencatat keuangan.',
                  actionLabel: 'Tambah Dompet',
                  onActionPressed: () => _showAddWalletSheet(context),
                ),
              ),
            );
          }

          // Klasifikasi kelompok akun
          final bankWallets = wallets.where((w) => w.wallet.type == WalletType.bank).toList();
          final cashWallets = wallets.where((w) => w.wallet.type == WalletType.cash).toList();
          final eWalletWallets = wallets.where((w) => w.wallet.type == WalletType.eWallet).toList();
          final otherWallets = wallets.where((w) => w.wallet.type == WalletType.other).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            children: [
              const SizedBox(height: 4),

              // 1. Dedicated Asset Balance Card (Focal Point Utama — MyFinance Minimal)
              _buildDedicatedAssetCard(
                context,
                totalBalance: totalBalance,
                wallets: wallets,
                archivedWallets: archivedWallets,
                bankWallets: bankWallets,
                cashWallets: cashWallets,
                eWalletWallets: eWalletWallets,
                otherWallets: otherWallets,
                isDark: isDark,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
              ),

              const SizedBox(height: 14),

              // Quick Actions Bar (Transfer & Tambah Dompet)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        unawaited(AppHaptics.light());
                        AddTransactionSheet.show(
                          context,
                          initialType: TransactionType.transfer,
                        );
                      },
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Transfer Saldo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        side: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 0.8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddWalletSheet(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tambah'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        side: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 0.8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // 2. Rekening Bank Group
              if (bankWallets.isNotEmpty) ...[
                MinimalSectionHeader(
                  title: 'Rekening Bank',
                  actionLabel: '${bankWallets.length}',
                ),
                ...bankWallets.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: WalletCard(
                      wallet: item.wallet,
                      currentBalance: item.currentBalance,
                      isBalanceVisible: _isBalanceVisible,
                      onTap: () => _showWalletDetailSheet(context, ref, item),
                    ),
                  );
                }),
                const SizedBox(height: 14),
              ],

              // 3. Kas Tunai Group
              if (cashWallets.isNotEmpty) ...[
                MinimalSectionHeader(
                  title: 'Kas Tunai',
                  actionLabel: '${cashWallets.length}',
                ),
                ...cashWallets.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: WalletCard(
                      wallet: item.wallet,
                      currentBalance: item.currentBalance,
                      isBalanceVisible: _isBalanceVisible,
                      onTap: () => _showWalletDetailSheet(context, ref, item),
                    ),
                  );
                }),
                const SizedBox(height: 14),
              ],

              // 4. E-Wallet Group
              if (eWalletWallets.isNotEmpty) ...[
                MinimalSectionHeader(
                  title: 'E-Wallet',
                  actionLabel: '${eWalletWallets.length}',
                ),
                ...eWalletWallets.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: WalletCard(
                      wallet: item.wallet,
                      currentBalance: item.currentBalance,
                      isBalanceVisible: _isBalanceVisible,
                      onTap: () => _showWalletDetailSheet(context, ref, item),
                    ),
                  );
                }),
                const SizedBox(height: 14),
              ],

              // 5. Lainnya Group
              if (otherWallets.isNotEmpty) ...[
                MinimalSectionHeader(
                  title: 'Lainnya / Investasi',
                  actionLabel: '${otherWallets.length}',
                ),
                ...otherWallets.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: WalletCard(
                      wallet: item.wallet,
                      currentBalance: item.currentBalance,
                      isBalanceVisible: _isBalanceVisible,
                      onTap: () => _showWalletDetailSheet(context, ref, item),
                    ),
                  );
                }),
                const SizedBox(height: 14),
              ],

              // State jika dompet aktif kosong tetapi arsip tersedia
              if (wallets.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Tidak ada dompet aktif. Tambahkan dompet baru atau aktifkan dari daftar arsip di bawah.',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 6. Dompet Diarsipkan / Cadangan Group
              if (archivedWallets.isNotEmpty) ...[
                MinimalSectionHeader(
                  title: 'Dompet Diarsipkan',
                  actionLabel: '${archivedWallets.length}',
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Dompet cadangan disimpan sebagai arsip saldo dan tidak dapat dipilih sebagai sumber dana transaksi.',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                    ),
                  ),
                ),
                ...archivedWallets.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: WalletCard(
                      wallet: item.wallet,
                      currentBalance: item.currentBalance,
                      isBalanceVisible: _isBalanceVisible,
                      onTap: () => _showWalletDetailSheet(context, ref, item),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Belum dapat memuat data dompet. Silakan muat ulang.',
              style: AppTypography.subhead,
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal Tambah Dompet Baru — MyFinance Minimal (Quiet, Clean, Premium)
class _AddWalletModal extends ConsumerStatefulWidget {
  const _AddWalletModal();

  @override
  ConsumerState<_AddWalletModal> createState() => _AddWalletModalState();
}

class _AddWalletModalState extends ConsumerState<_AddWalletModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _openingBalanceController = TextEditingController();

  WalletType _selectedType = WalletType.bank;
  int _openingBalance = 0;
  String _selectedColorHex = '0xFF0E7A4A';
  String _selectedIconKey = 'bank';
  bool _isLoading = false;
  String? _nameError;

  final List<String> _colors = const [
    '0xFF0E7A4A', // Emerald
    '0xFF2ED573', // Mint
    '0xFF10AC84', // Teal
    '0xFF0984E3', // Blue
    '0xFF9B59B6', // Purple
    '0xFFE67E22', // Orange
    '0xFFD63031', // Crimson
    '0xFF2C3E50', // Navy
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  void _onBalanceChanged(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    final num = int.tryParse(clean) ?? 0;
    _openingBalance = num;
    final formatted = num > 0 ? CurrencyFormatter.formatRupiah(num) : '';
    if (_openingBalanceController.text != formatted) {
      _openingBalanceController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _onTypeSelected(WalletType type) {
    unawaited(AppHaptics.selection());
    setState(() {
      _selectedType = type;
      switch (type) {
        case WalletType.cash:
          _selectedIconKey = 'cash';
          break;
        case WalletType.bank:
          _selectedIconKey = 'bank';
          break;
        case WalletType.eWallet:
          _selectedIconKey = 'card';
          break;
        case WalletType.other:
          _selectedIconKey = 'wallet';
          break;
      }
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Nama dompet wajib diisi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _nameError = null;
    });

    try {
      final success = await ref.read(walletsControllerProvider.notifier).createWallet(
            name: name,
            type: _selectedType,
            openingBalance: _openingBalance,
            iconKey: _selectedIconKey,
            colorHex: _selectedColorHex,
          );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          unawaited(AppHaptics.medium());
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Dompet "$name" berhasil dibuat.')),
            );
          }
        } else {
          final err = ref.read(walletsControllerProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membuat dompet: ${err ?? "Terjadi kesalahan"}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final surfaceElevated = isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: keyboardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceModalDark : AppColors.surfaceModalLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Top Header: Batal, Title, Simpan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Batal',
                      style: TextStyle(fontSize: 15, color: textSecondary),
                    ),
                  ),
                  Text(
                    'Tambah Dompet Baru',
                    style: AppTypography.headline.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
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
                              color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.6, color: dividerColor),

            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Nama Dompet
                  Text(
                    'NAMA DOMPET / REKENING',
                    style: AppTypography.caption1.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: AppTypography.body,
                    decoration: InputDecoration(
                      hintText: 'Contoh: BCA Utama, GoPay, Dompet Tunai',
                      filled: true,
                      fillColor: surfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          width: 1.2,
                        ),
                      ),
                      errorText: _nameError,
                    ),
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Tipe Dompet
                  Text(
                    'TIPE DOMPET',
                    style: AppTypography.caption1.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: WalletType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return InkWell(
                        onTap: () => _onTypeSelected(type),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? AppColors.surfaceElevatedDark : AppColors.textPrimaryLight)
                                : (isDark ? AppColors.surfaceModalDark : AppColors.surfaceModalLight),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? AppColors.borderLight : AppColors.textPrimaryLight)
                                  : borderColor,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? (isDark ? AppColors.textPrimaryDark : Colors.white)
                                  : textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Saldo Awal
                  Text(
                    'SALDO AWAL',
                    style: AppTypography.caption1.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _openingBalanceController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.title3.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rp 0',
                      filled: true,
                      fillColor: surfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          width: 1.2,
                        ),
                      ),
                    ),
                    onChanged: _onBalanceChanged,
                  ),

                  const SizedBox(height: 20),

                  // Pilihan Warna Aksen
                  Text(
                    'WARNA AKSEN',
                    style: AppTypography.caption1.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _colors.map((cHex) {
                      final color = AppIcons.parseColor(cHex);
                      final isSelected = _selectedColorHex == cHex;
                      return GestureDetector(
                        onTap: () {
                          unawaited(AppHaptics.selection());
                          setState(() => _selectedColorHex = cHex);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 14),
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                          ),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal Edit Dompet — MyFinance Minimal (Quiet, Clean, Premium)
class _EditWalletModal extends ConsumerStatefulWidget {
  final Wallet wallet;

  const _EditWalletModal({required this.wallet});

  @override
  ConsumerState<_EditWalletModal> createState() => _EditWalletModalState();
}

class _EditWalletModalState extends ConsumerState<_EditWalletModal> {
  late final TextEditingController _nameController;
  late WalletType _selectedType;
  late String _selectedColorHex;
  late String _selectedIconKey;
  bool _isLoading = false;
  String? _nameError;

  late final List<String> _colors;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wallet.name);
    _selectedType = widget.wallet.type;
    _selectedColorHex = widget.wallet.colorHex ?? '0xFF0E7A4A';
    _selectedIconKey = widget.wallet.iconKey ?? 'wallet';

    const defaultColors = [
      '0xFF0E7A4A', // Emerald
      '0xFF2ED573', // Mint
      '0xFF10AC84', // Teal
      '0xFF0984E3', // Blue
      '0xFF9B59B6', // Purple
      '0xFFE67E22', // Orange
      '0xFFD63031', // Crimson
      '0xFF2C3E50', // Navy
    ];

    if (!defaultColors.contains(_selectedColorHex)) {
      _colors = [_selectedColorHex, ...defaultColors];
    } else {
      _colors = defaultColors;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onTypeSelected(WalletType type) {
    unawaited(AppHaptics.selection());
    setState(() {
      _selectedType = type;
      switch (type) {
        case WalletType.cash:
          _selectedIconKey = 'cash';
          break;
        case WalletType.bank:
          _selectedIconKey = 'bank';
          break;
        case WalletType.eWallet:
          _selectedIconKey = 'card';
          break;
        case WalletType.other:
          _selectedIconKey = 'wallet';
          break;
      }
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Nama dompet wajib diisi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _nameError = null;
    });

    try {
      final success = await ref.read(walletsControllerProvider.notifier).updateWallet(
            id: widget.wallet.id,
            name: name,
            type: _selectedType,
            openingBalance: widget.wallet.openingBalance,
            iconKey: _selectedIconKey,
            colorHex: _selectedColorHex,
            isArchived: widget.wallet.isArchived,
            openingDate: widget.wallet.openingDate,
            currencyCode: widget.wallet.currencyCode,
            createdAt: widget.wallet.createdAt,
          );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          unawaited(AppHaptics.medium());
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Dompet "$name" berhasil diperbarui.')),
            );
          }
        } else {
          final err = ref.read(walletsControllerProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui: ${err ?? "Terjadi kesalahan"}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final surfaceElevated = isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: keyboardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceModalDark : AppColors.surfaceModalLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Top Header: Batal, Title, Simpan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Batal',
                      style: TextStyle(fontSize: 15, color: textSecondary),
                    ),
                  ),
                  Text(
                    'Edit Dompet',
                    style: AppTypography.headline.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
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
                              color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.6, color: dividerColor),

            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Nama Dompet
                  Text(
                    'NAMA DOMPET / REKENING',
                    style: AppTypography.caption1.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: AppTypography.body,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: surfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          width: 1.2,
                        ),
                      ),
                      errorText: _nameError,
                    ),
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Tipe Dompet
                  Text(
                    'TIPE DOMPET',
                    style: AppTypography.caption1.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: WalletType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return InkWell(
                        onTap: () => _onTypeSelected(type),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? AppColors.surfaceElevatedDark : AppColors.textPrimaryLight)
                                : (isDark ? AppColors.surfaceModalDark : AppColors.surfaceModalLight),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? AppColors.borderLight : AppColors.textPrimaryLight)
                                  : borderColor,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? (isDark ? AppColors.textPrimaryDark : Colors.white)
                                  : textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Saldo Awal (Aturan MyFinance: Ditampilkan terformat sesuai integritas buku kas)
                  Text(
                    'SALDO AWAL',
                    style: AppTypography.caption1.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          CurrencyFormatter.formatRupiah(widget.wallet.openingBalance),
                          style: AppTypography.title3.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceModalDark : AppColors.surfaceModalLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: borderColor, width: 0.6),
                          ),
                          child: Text(
                            'Tersimpan',
                            style: AppTypography.caption2.copyWith(color: textSecondary, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saldo awal dikunci untuk menjaga konsistensi kalkulasi mutasi transaksi.',
                    style: AppTypography.caption2.copyWith(color: textSecondary, fontSize: 11),
                  ),

                  const SizedBox(height: 20),

                  // Warna Aksen
                  Text(
                    'WARNA AKSEN',
                    style: AppTypography.caption1.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _colors.map((cHex) {
                      final color = AppIcons.parseColor(cHex);
                      final isSelected = _selectedColorHex == cHex;
                      return GestureDetector(
                        onTap: () {
                          unawaited(AppHaptics.selection());
                          setState(() => _selectedColorHex = cHex);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 14),
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                          ),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
