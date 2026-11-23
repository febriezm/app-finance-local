import 'package:flutter/material.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';

/// Pemilih bulan minimalis dengan tipografi bersih dan tombol panah outline.
class MinimalMonthSelector extends StatelessWidget {
  final DateTime currentMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const MinimalMonthSelector({
    super.key,
    required this.currentMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isCurrentMonth = currentMonth.year == now.year && currentMonth.month == now.month;
    final monthDisplay = AppDateFormatter.formatMonthYear(currentMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Panah Sebelumnya
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            onPressed: () {
              AppHaptics.selection();
              final prev = DateTime(currentMonth.year, currentMonth.month - 1, 1);
              onMonthChanged(prev);
            },
          ),

          // Teks Bulan & Tombol Reset Bulan Ini jika relevan
          GestureDetector(
            onTap: isCurrentMonth
                ? null
                : () {
                    AppHaptics.selection();
                    onMonthChanged(DateTime(now.year, now.month, 1));
                  },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  monthDisplay,
                  style: AppTypography.sectionTitle.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isCurrentMonth)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Ketuk untuk bulan ini',
                      style: AppTypography.caption2.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Panah Berikutnya
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            onPressed: () {
              AppHaptics.selection();
              final next = DateTime(currentMonth.year, currentMonth.month + 1, 1);
              onMonthChanged(next);
            },
          ),
        ],
      ),
    );
  }
}
