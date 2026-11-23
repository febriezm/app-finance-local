import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'finance_amount_text.dart';

/// Baris ringkasan finansial kunci-nilai (Key-Value) yang bersih dan minimalis.
/// Menghindari wrapping card berlebih untuk setiap data statistik.
class FinanceSummaryRow extends StatelessWidget {
  final String label;
  final int? amount;
  final String? customValue;
  final AmountDisplayType amountType;
  final Color? valueColor;
  final bool isBold;
  final bool showDivider;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const FinanceSummaryRow({
    super.key,
    required this.label,
    this.amount,
    this.customValue,
    this.amountType = AmountDisplayType.neutral,
    this.valueColor,
    this.isBold = false,
    this.showDivider = true,
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: padding,
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label,
                  style: isBold
                      ? AppTypography.bodyBold.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        )
                      : AppTypography.body.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              if (trailing != null)
                trailing!
              else if (amount != null)
                FinanceAmountText(
                  amount: amount!,
                  type: amountType,
                  color: valueColor,
                  style: isBold
                      ? AppTypography.bodyBold.copyWith(
                          color: valueColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          fontSize: 15,
                        )
                      : AppTypography.bodyMedium.copyWith(
                          color: valueColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                )
              else if (customValue != null)
                Text(
                  customValue!,
                  style: isBold
                      ? AppTypography.bodyBold.copyWith(
                          color: valueColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        )
                      : AppTypography.bodyMedium.copyWith(
                          color: valueColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.6,
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
      ],
    );
  }
}
