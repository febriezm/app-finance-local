import 'package:flutter/material.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';
import '../../features/transactions/domain/entities/transaction.dart';
import '../../features/transactions/domain/entities/transaction_with_details.dart';
import 'finance_amount_text.dart';

/// Item baris transaksi bergaya flat, minimalis, dan clean.
/// Menghindari kartu berlebihan; menggunakan hairline divider atau whitespace.
class TransactionListTile extends StatelessWidget {
  final TransactionWithDetails item;
  final VoidCallback? onTap;
  final bool showDivider;

  const TransactionListTile({
    super.key,
    required this.item,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tx = item.transaction;
    final isVoided = tx.status == TransactionStatus.voided;

    // Tentukan tipe tampilan nominal
    AmountDisplayType amountType;
    if (tx.type == TransactionType.income) {
      amountType = AmountDisplayType.income;
    } else if (tx.type == TransactionType.expense) {
      amountType = AmountDisplayType.expense;
    } else {
      amountType = AmountDisplayType.neutral;
    }

    final date = AppDateFormatter.parseUtcToLocal(tx.occurredAt);
    final dateStr = AppDateFormatter.formatDayMonth(date);
    final detailSubtitle = item.displaySubtitle;
    final subtitleText = detailSubtitle.isNotEmpty ? '$detailSubtitle • $dateStr' : dateStr;

    final iconData = item.category?.iconKey != null
        ? AppIcons.getIcon(item.category!.iconKey)
        : (tx.type == TransactionType.transfer
            ? Icons.swap_horiz_rounded
            : (tx.type == TransactionType.income ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded));

    return InkWell(
      onTap: () {
        AppHaptics.light();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                // Icon outline kontainer lembut
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 0.6,
                    ),
                  ),
                  child: Icon(
                    iconData,
                    size: 19,
                    color: isVoided
                        ? (isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight)
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                ),
                const SizedBox(width: 12),

                // Judul & Keterangan Transaksi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayTitle,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isVoided
                              ? (isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight)
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          decoration: isVoided ? TextDecoration.lineThrough : null,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isVoided ? '$subtitleText • Dibatalkan' : subtitleText,
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Nominal Transaksi
                FinanceAmountText(
                  amount: tx.amount,
                  type: amountType,
                  isVoided: isVoided,
                  style: AppTypography.bodyBold.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              thickness: 0.6,
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              indent: 54,
            ),
        ],
      ),
    );
  }
}
