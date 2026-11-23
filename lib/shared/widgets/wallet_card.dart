import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';
import '../../features/wallets/domain/entities/wallet.dart';
import 'finance_amount_text.dart';

/// Individual Wallet Card — MyFinance Minimal (Quiet, Clean, Premium).
///
/// Visual Hierarchy:
/// - Primary: Saldo Wallet (besar, prominent, tabular figures)
/// - Secondary: Nama Wallet (15pt, semibold)
/// - Supporting: Jenis Wallet & Ikon dengan aksen warna terkendali
/// - Action: Tap card membuka detail modal
class WalletCard extends StatelessWidget {
  final Wallet wallet;
  final int currentBalance;
  final VoidCallback? onTap;
  final bool isBalanceVisible;

  const WalletCard({
    super.key,
    required this.wallet,
    required this.currentBalance,
    this.onTap,
    this.isBalanceVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textTertiary = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final walletColor = AppIcons.parseColor(wallet.colorHex);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            AppHaptics.light();
            onTap?.call();
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon + Name & Type + Chevron/Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon Container dengan soft tint terkendali
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: walletColor.withValues(alpha: isDark ? 0.20 : 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: walletColor.withValues(alpha: isDark ? 0.40 : 0.25),
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

                    // Name & Type
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
                              color: textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status / Chevron Indicator
                    if (wallet.isArchived)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Arsip',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ),

                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: textTertiary,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bottom Section: SALDO label & Primary Balance Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SALDO',
                      style: AppTypography.caption2.copyWith(
                        color: textTertiary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // Hero Saldo inside card (Primary element)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: isBalanceVisible
                      ? FinanceAmountText(
                          amount: currentBalance,
                          type: AmountDisplayType.neutral,
                          style: AppTypography.title2.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: currentBalance >= 0
                                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                : (isDark ? AppColors.expenseDark : AppColors.expenseLight),
                          ),
                        )
                      : Text(
                          'Rp ••••••••',
                          style: AppTypography.title2.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
