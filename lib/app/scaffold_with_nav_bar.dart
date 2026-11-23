import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/app_haptics.dart';
import '../features/transactions/domain/entities/transaction.dart';
import '../features/transactions/presentation/widgets/add_transaction_sheet.dart';
import 'router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  void _onTap(BuildContext context, int index) {
    if (index == 2) {
      // Tombol tengah: Tampilkan modal aksi cepat (Quick Actions)
      AppHaptics.light();
      _showQuickActionModal(context);
      return;
    }

    AppHaptics.selection();
    final targetBranch = index > 2 ? index - 1 : index;
    navigationShell.goBranch(
      targetBranch,
      initialLocation: targetBranch == navigationShell.currentIndex,
    );
  }

  void _showQuickActionModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceModalDark : AppColors.surfaceModalLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Aksi Cepat',
                    style: AppTypography.title3.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Catat Pengeluaran
                _buildActionTile(
                  context,
                  isDark: isDark,
                  icon: Icons.arrow_upward_rounded,
                  iconColor: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                  title: 'Catat Pengeluaran',
                  subtitle: 'Catat belanja atau pengeluaran harian',
                  onTap: () {
                    Navigator.pop(ctx);
                    AddTransactionSheet.show(context, initialType: TransactionType.expense);
                  },
                ),
                Divider(height: 1, thickness: 0.6, indent: 64, color: dividerColor),

                // Catat Pemasukan
                _buildActionTile(
                  context,
                  isDark: isDark,
                  icon: Icons.arrow_downward_rounded,
                  iconColor: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                  title: 'Catat Pemasukan',
                  subtitle: 'Gaji, bonus, atau pendapatan lainnya',
                  onTap: () {
                    Navigator.pop(ctx);
                    AddTransactionSheet.show(context, initialType: TransactionType.income);
                  },
                ),
                Divider(height: 1, thickness: 0.6, indent: 64, color: dividerColor),

                // Transfer Saldo
                _buildActionTile(
                  context,
                  isDark: isDark,
                  icon: Icons.swap_horiz_rounded,
                  iconColor: isDark ? AppColors.transferDark : AppColors.transferLight,
                  title: 'Transfer Saldo',
                  subtitle: 'Pindah dana antar rekening & dompet',
                  onTap: () {
                    Navigator.pop(ctx);
                    AddTransactionSheet.show(context, initialType: TransactionType.transfer);
                  },
                ),
                Divider(height: 1, thickness: 0.6, indent: 64, color: dividerColor),

                // Anggaran Bulanan
                _buildActionTile(
                  context,
                  isDark: isDark,
                  icon: Icons.pie_chart_outline_rounded,
                  iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  title: 'Anggaran Bulanan',
                  subtitle: 'Kelola batas pengeluaran & kategori',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(AppRouter.budgets);
                  },
                ),
                Divider(height: 1, thickness: 0.6, indent: 64, color: dividerColor),

                // Scan Struk (OCR)
                _buildActionTile(
                  context,
                  isDark: isDark,
                  icon: Icons.document_scanner_outlined,
                  iconColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  title: 'Scan Struk (OCR)',
                  subtitle: 'Ekstraksi otomatis struk belanja on-device',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(AppRouter.receiptScanner);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 0.6,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyBold.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption1.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final navIndex = currentIndex >= 2 ? currentIndex + 1 : currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 0.6,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navIndex,
          onTap: (index) => _onTap(context, index),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transaksi',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: isDark ? AppColors.backgroundDark : Colors.white,
                ),
              ),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Dompet',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Laporan',
            ),
          ],
        ),
      ),
    );
  }
}
