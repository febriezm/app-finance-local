import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../domain/entities/wallet_report_item.dart';

/// Daftar distribusi transaksi per akun dompet — MyFinance Minimal.
class WalletBreakdownList extends StatelessWidget {
  final List<WalletReportItem> items;
  final bool isDark;
  final void Function(WalletReportItem item)? onWalletTap;

  const WalletBreakdownList({
    super.key,
    required this.items,
    required this.isDark,
    this.onWalletTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Belum ada transaksi pada dompet di bulan ini.',
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
        final walletColor = AppIcons.parseColor(item.wallet.colorHex);
        final isNetPositive = item.netFlow >= 0;

        return Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                unawaited(AppHaptics.light());
                onWalletTap?.call(item);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: walletColor.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: walletColor.withValues(alpha: isDark ? 0.4 : 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        AppIcons.getIcon(item.wallet.iconKey),
                        color: isDark ? Colors.white : walletColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.wallet.name,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.transactionCount} transaksi  •  +${CurrencyFormatter.formatRupiah(item.incomeAmount + item.transferInAmount)}  •  -${CurrencyFormatter.formatRupiah(item.expenseAmount + item.transferOutAmount)}',
                            style: AppTypography.caption.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FinanceAmountText(
                          amount: item.netFlow,
                          type: AmountDisplayType.auto,
                          style: AppTypography.balanceSmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          isNetPositive ? 'Arus Kas +' : 'Arus Kas -',
                          style: AppTypography.caption2.copyWith(
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (idx < items.length - 1)
              Divider(
                height: 1,
                thickness: 0.6,
                indent: 52,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
          ],
        );
      }).toList(),
    );
  }
}
