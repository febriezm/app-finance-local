import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';

/// Bilah navigasi bawah (*Bottom Navigation Bar*) minimalis, flat, dan bersih.
/// Menggunakan garis pemisah tipis (*hairline divider*) tanpa shadow berlebih.
class MinimalBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onQuickAction;

  const MinimalBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onQuickAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final activeColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final inactiveColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 0.8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              // Tab 0: Home
              _buildNavItem(
                index: 0,
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                isActive: currentIndex == 0,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),

              // Tab 1: Transaksi
              _buildNavItem(
                index: 1,
                label: 'Transaksi',
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                isActive: currentIndex == 1,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),

              // Center Quick Action (+)
              Expanded(
                child: Center(
                  child: InkWell(
                    onTap: () {
                      AppHaptics.medium();
                      onQuickAction();
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: isDark ? AppColors.backgroundDark : Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

              // Tab 2: Dompet
              _buildNavItem(
                index: 2,
                label: 'Dompet',
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                isActive: currentIndex == 2,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),

              // Tab 3: Laporan
              _buildNavItem(
                index: 3,
                label: 'Laporan',
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                isActive: currentIndex == 3,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          onTap(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.caption2.copyWith(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
