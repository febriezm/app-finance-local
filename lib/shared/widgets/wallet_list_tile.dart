import 'package:flutter/material.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';
import '../../features/wallets/domain/entities/wallet.dart';

/// Item baris akun dompet / rekening dengan tampilan bersih, flat, dan elegan.
class WalletListTile extends StatelessWidget {
  final Wallet wallet;
  final int currentBalance;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isSelected;
  final bool showDivider;

  const WalletListTile({
    super.key,
    required this.wallet,
    required this.currentBalance,
    this.onTap,
    this.trailing,
    this.isSelected = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletColor = AppIcons.parseColor(wallet.colorHex);

    return InkWell(
      onTap: () {
        AppHaptics.light();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                // Ikon Dompet dengan aksen warna halus
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
                    AppIcons.getIcon(wallet.iconKey),
                    size: 20,
                    color: isDark ? Colors.white : walletColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Nama & Tipe Dompet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        wallet.type.displayName,
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

                // Saldo & Trailing
                if (trailing != null)
                  trailing!
                else
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            CurrencyFormatter.formatRupiah(currentBalance),
                            style: AppTypography.balanceSmall.copyWith(
                              color: currentBalance >= 0
                                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                  : (isDark ? AppColors.expenseDark : AppColors.expenseLight),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (wallet.isArchived)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Diarsipkan',
                              style: AppTypography.caption2.copyWith(
                                color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
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
              indent: 56,
            ),
        ],
      ),
    );
  }
}
