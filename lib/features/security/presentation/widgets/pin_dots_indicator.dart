import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Indikator 6 Titik PIN — MyFinance Minimal (Quiet, Clean, Premium).
class PinDotsIndicator extends StatelessWidget {
  final int pinLength;
  final int currentLength;
  final bool hasError;

  const PinDotsIndicator({
    super.key,
    this.pinLength = 6,
    required this.currentLength,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseColor = isDark ? AppColors.expenseDark : AppColors.expenseLight;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final emptyBorderColor = isDark ? Colors.white24 : Colors.black12;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pinLength, (index) {
        final isFilled = index < currentLength;
        final color = hasError
            ? expenseColor
            : isFilled
                ? primaryTextColor
                : emptyBorderColor;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: isFilled ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: isFilled ? 1.4 : 1.2,
            ),
          ),
        );
      }),
    );
  }
}
