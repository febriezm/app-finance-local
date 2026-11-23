import 'package:flutter/material.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Indikator progress anggaran bulanan yang minimalis, flat, dan bebas gradien berlebih.
class BudgetProgressBar extends StatelessWidget {
  final int spent;
  final int totalLimit;
  final String? title;
  final double height;
  final bool showLabels;
  final bool compact;

  const BudgetProgressBar({
    super.key,
    required this.spent,
    required this.totalLimit,
    this.title,
    this.height = 6.0,
    this.showLabels = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ratio = totalLimit > 0 ? (spent / totalLimit) : 0.0;
    final clampedRatio = ratio.clamp(0.0, 1.0);
    final percentageInt = (ratio * 100).round();
    final isOverLimit = spent > totalLimit && totalLimit > 0;
    final isNearLimit = ratio >= 0.8 && !isOverLimit;

    // Warna indikator fungsional
    Color barColor;
    if (isOverLimit) {
      barColor = isDark ? AppColors.expenseDark : AppColors.expenseLight;
    } else if (isNearLimit) {
      barColor = isDark ? AppColors.warningDark : AppColors.warningLight;
    } else {
      barColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    }

    final trackColor = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabels && !compact) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                '$percentageInt%',
                style: AppTypography.caption.copyWith(
                  color: isOverLimit
                      ? (isDark ? AppColors.expenseDark : AppColors.expenseLight)
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],

        // Bar Track
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            width: double.infinity,
            color: trackColor,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: clampedRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ),
        ),

        if (showLabels && !compact) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terpakai ${CurrencyFormatter.formatRupiah(spent)}',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                'Batas ${CurrencyFormatter.formatRupiah(totalLimit)}',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
