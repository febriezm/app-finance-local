import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';

/// Header seksi minimalis dengan whitespace yang lega dan tipografi bersih.
/// Menggantikan kartu-kartu berlebih untuk pemisahan visual yang tenang (*quiet*).
class MinimalSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? actionWidget;
  final EdgeInsetsGeometry padding;

  const MinimalSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionWidget,
    this.padding = const EdgeInsets.only(top: 24, bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.sectionTitle.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionWidget != null)
            actionWidget!
          else if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: () {
                AppHaptics.light();
                onAction?.call();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  actionLabel!,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
