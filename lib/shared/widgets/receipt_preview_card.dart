import 'package:flutter/material.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';

/// Kartu pratinjau struk belanja yang bersih, flat, dan informatif.
class ReceiptPreviewCard extends StatelessWidget {
  final String? merchantName;
  final DateTime? date;
  final int? totalAmount;
  final double? confidence;
  final Widget? imagePreview;
  final VoidCallback? onTap;
  final VoidCallback? onRetake;

  const ReceiptPreviewCard({
    super.key,
    this.merchantName,
    this.date,
    this.totalAmount,
    this.confidence,
    this.imagePreview,
    this.onTap,
    this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: border, width: 0.8),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Thumbnail Struk
              if (imagePreview != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: imagePreview!,
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Info Merchant & Tanggal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchantName ?? 'Struk Belanja',
                      style: AppTypography.bodyBold.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date != null ? AppDateFormatter.formatDate(date!) : 'Tanggal struk',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Total Nominal
              if (totalAmount != null)
                Text(
                  CurrencyFormatter.formatRupiah(totalAmount!),
                  style: AppTypography.balanceSmall.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),

          if (confidence != null || onRetake != null) ...[
            const SizedBox(height: 10),
            Divider(height: 1, thickness: 0.6, color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (confidence != null)
                  Text(
                    'Akurasi OCR: ${(confidence! * 100).round()}%',
                    style: AppTypography.caption2.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (onRetake != null)
                  GestureDetector(
                    onTap: () {
                      AppHaptics.light();
                      onRetake?.call();
                    },
                    child: Text(
                      'Foto Ulang',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
