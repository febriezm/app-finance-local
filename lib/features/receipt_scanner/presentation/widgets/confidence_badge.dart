import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Tag penunjuk tingkat kepastian (certainty/confidence) field OCR sesuai Apple HIG.
class ConfidenceBadge extends StatelessWidget {
  final bool isCertain;
  final String? customLabel;

  const ConfidenceBadge({
    super.key,
    required this.isCertain,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = isCertain
        ? (isDark ? AppColors.incomeDark : AppColors.incomeLight)
        : (isDark ? AppColors.warningDark : AppColors.warningLight);

    final bgColor = isCertain
        ? (isDark ? AppColors.incomeContainerDark : AppColors.incomeContainerLight)
        : (isDark ? AppColors.warningContainerDark : AppColors.warningContainerLight);

    final text = customLabel ?? (isCertain ? 'Pasti' : 'Perlu Diperiksa');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCertain ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.caption2.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
