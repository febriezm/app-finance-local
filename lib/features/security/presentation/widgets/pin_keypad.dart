import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_haptics.dart';

/// Papan Tombol Numerik PIN — MyFinance Minimal (Quiet, Clean, Premium).
///
/// Karakteristik:
/// - Tata letak 3x3 + 0 dengan lebar proporsional (max 300px).
/// - Tombol lingkaran datar (flat) 70x70 dengan sentuhan haptic lembut.
/// - Border hairline 0.6px tanpa bayangan berat atau skeuomorfik.
/// - Tombol Hapus (Backspace) dan Biometrik di baris terbawah.
class PinKeypad extends StatelessWidget {
  final void Function(String digit) onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onBiometricPressed;
  final bool showBiometricButton;
  final IconData biometricIcon;

  const PinKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    this.onBiometricPressed,
    this.showBiometricButton = false,
    this.biometricIcon = Icons.fingerprint_rounded,
  });

  static const List<Map<String, String>> _keys = [
    {'digit': '1', 'letters': ''},
    {'digit': '2', 'letters': 'ABC'},
    {'digit': '3', 'letters': 'DEF'},
    {'digit': '4', 'letters': 'GHI'},
    {'digit': '5', 'letters': 'JKL'},
    {'digit': '6', 'letters': 'MNO'},
    {'digit': '7', 'letters': 'PQRS'},
    {'digit': '8', 'letters': 'TUV'},
    {'digit': '9', 'letters': 'WXYZ'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Baris 1-3
          for (int row = 0; row < 3; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int col = 0; col < 3; col++)
                    _buildDigitButton(_keys[row * 3 + col], isDark),
                ],
              ),
            ),

          // Baris 4 (Biometrik, 0, Hapus)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tombol Kiri (Biometrik / Kosong)
                SizedBox(
                  width: 70,
                  height: 70,
                  child: showBiometricButton && onBiometricPressed != null
                      ? InkResponse(
                          onTap: () {
                            unawaited(AppHaptics.light());
                            onBiometricPressed!();
                          },
                          radius: 35,
                          containedInkWell: true,
                          highlightShape: BoxShape.circle,
                          child: Center(
                            child: Icon(
                              biometricIcon,
                              size: 28,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Tombol 0
                _buildDigitButton({'digit': '0', 'letters': ''}, isDark),

                // Tombol Kanan (Hapus Backspace)
                SizedBox(
                  width: 70,
                  height: 70,
                  child: InkResponse(
                    onTap: () {
                      unawaited(AppHaptics.light());
                      onDeletePressed();
                    },
                    radius: 35,
                    containedInkWell: true,
                    highlightShape: BoxShape.circle,
                    child: Center(
                      child: Icon(
                        Icons.backspace_outlined,
                        size: 22,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitButton(Map<String, String> item, bool isDark) {
    final digit = item['digit']!;
    final letters = item['letters']!;
    final surfaceButton = isDark ? const Color(0xFF191919) : const Color(0xFFF7F7F8);
    final borderButton = isDark ? AppColors.borderDark : AppColors.borderLight;

    return InkResponse(
      onTap: () {
        unawaited(AppHaptics.light());
        onDigitPressed(digit);
      },
      radius: 35,
      containedInkWell: true,
      highlightShape: BoxShape.circle,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: surfaceButton,
          shape: BoxShape.circle,
          border: Border.all(color: borderButton, width: 0.6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              digit,
              style: AppTypography.pageTitle.copyWith(
                fontSize: 25,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                height: 1.1,
              ),
            ),
            if (letters.isNotEmpty)
              Text(
                letters,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: isDark ? AppColors.textDisabledDark : AppColors.textSecondaryLight,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
