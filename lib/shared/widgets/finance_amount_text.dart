import 'package:flutter/material.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum AmountDisplayType {
  auto,     // Hijau jika positif/income, merah jika negatif/expense, netral jika 0
  income,   // Selalu format income (+Rp)
  expense,  // Selalu format expense (-Rp)
  neutral,  // Tanpa tanda plus/minus, warna teks standar
}

/// Widget teks finansial berformat Rupiah dengan angka tabular (Tabular Figures).
///
/// Mematuhi prinsip desain minimal:
/// - Warna hijau strictly untuk income / positif.
/// - Warna merah strictly untuk expense / peringatan.
/// - Warna netral untuk saldo akun atau transfer.
class FinanceAmountText extends StatelessWidget {
  final int amount;
  final AmountDisplayType type;
  final TextStyle? style;
  final Color? color;
  final bool showPlusSign;
  final bool isVoided;
  final String? prefix;
  final String? suffix;

  const FinanceAmountText({
    super.key,
    required this.amount,
    this.type = AmountDisplayType.auto,
    this.style,
    this.color,
    this.showPlusSign = true,
    this.isVoided = false,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color textColor;
    String sign = '';

    if (color != null) {
      textColor = color!;
    } else if (isVoided) {
      textColor = isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight;
    } else {
      switch (type) {
        case AmountDisplayType.income:
          textColor = isDark ? AppColors.incomeDark : AppColors.incomeLight;
          if (showPlusSign) sign = '+ ';
          break;
        case AmountDisplayType.expense:
          textColor = isDark ? AppColors.expenseDark : AppColors.expenseLight;
          sign = '- ';
          break;
        case AmountDisplayType.neutral:
          textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
          break;
        case AmountDisplayType.auto:
          if (amount > 0) {
            textColor = isDark ? AppColors.incomeDark : AppColors.incomeLight;
            if (showPlusSign) sign = '+ ';
          } else if (amount < 0) {
            textColor = isDark ? AppColors.expenseDark : AppColors.expenseLight;
            sign = '- ';
          } else {
            textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
          }
          break;
      }
    }

    final formattedAbs = CurrencyFormatter.formatRupiah(amount.abs());
    final displayText = '$sign${prefix ?? ''}$formattedAbs${suffix ?? ''}';

    final effectiveStyle = (style ?? AppTypography.bodyBold).copyWith(
      color: textColor,
      decoration: isVoided ? TextDecoration.lineThrough : null,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Text(
      displayText,
      style: effectiveStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
