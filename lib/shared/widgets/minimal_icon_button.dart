import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_haptics.dart';

/// Tombol ikon minimalis yang memenuhi standar aksesibilitas Apple Touch Target (min 44x44 pt).
class MinimalIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;
  final EdgeInsetsGeometry padding;

  const MinimalIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.size = 22.0,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed != null
            ? () {
                AppHaptics.light();
                onPressed?.call();
              }
            : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: AppSpacing.minTouchTarget,
            minHeight: AppSpacing.minTouchTarget,
          ),
          padding: padding,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: size,
            color: onPressed != null
                ? iconColor
                : (isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
