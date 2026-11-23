import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';

/// Utilitas dialog minimalis dan konsisten untuk MyFinance Minimal.
class MinimalDialog {
  MinimalDialog._();

  /// Menampilkan dialog konfirmasi aksi (contoh: arsip, aktifkan kembali, void transaksi).
  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String cancelText = 'Batal',
    String confirmText = 'Konfirmasi',
    bool isDestructive = false,
    Color? confirmColor,
    Widget? customContent,
  }) {
    AppHaptics.selection();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultConfirmColor = isDestructive
        ? (isDark ? AppColors.expenseDark : AppColors.expenseLight)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    final resolvedConfirmColor = confirmColor ?? defaultConfirmColor;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceModalDark : AppColors.surfaceModalLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.8,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        title: Text(
          title,
          style: AppTypography.title3.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        content: customContent ??
            Text(
              message,
              style: AppTypography.body.copyWith(
                fontSize: 14,
                height: 1.4,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              foregroundColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            onPressed: () {
              AppHaptics.light();
              Navigator.of(ctx).pop(false);
            },
            child: Text(
              cancelText,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              foregroundColor: resolvedConfirmColor,
            ),
            onPressed: () {
              AppHaptics.medium();
              Navigator.of(ctx).pop(true);
            },
            child: Text(
              confirmText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: resolvedConfirmColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Menampilkan dialog informasi sederhana (contoh: Wilayah & Bahasa, Kebijakan, info).
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String closeText = 'Tutup',
    Widget? customContent,
  }) {
    AppHaptics.selection();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceModalDark : AppColors.surfaceModalLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.8,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        title: Text(
          title,
          style: AppTypography.title3.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        content: customContent ??
            Text(
              message,
              style: AppTypography.body.copyWith(
                fontSize: 14,
                height: 1.4,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            onPressed: () {
              AppHaptics.light();
              Navigator.of(ctx).pop();
            },
            child: Text(
              closeText,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
