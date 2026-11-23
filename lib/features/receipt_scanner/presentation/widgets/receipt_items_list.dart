import 'package:flutter/material.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/receipt_item_draft.dart';

/// Daftar rincian item belanja hasil scan struk — MyFinance Minimal.
class ReceiptItemsList extends StatelessWidget {
  final List<ReceiptItemDraft> items;

  const ReceiptItemsList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'Tidak ada rincian item spesifik yang terdeteksi dari struk ini.',
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
            ),
          ),
        ),
      );
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevatedDark : AppColors.dividerLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: AppTypography.caption2.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.quantity > 1)
                          Text(
                            '@ ${CurrencyFormatter.formatRupiah(item.unitPrice)}',
                            style: AppTypography.caption.copyWith(
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.formatRupiah(item.totalPrice),
                    style: AppTypography.headline.copyWith(
                      fontSize: 13,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            if (idx < items.length - 1)
              Divider(
                height: 1,
                thickness: 0.6,
                indent: 36,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
          ],
        );
      }).toList(),
    );
  }
}
