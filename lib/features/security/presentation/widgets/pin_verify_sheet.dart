import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_haptics.dart';
import 'pin_dots_indicator.dart';
import 'pin_keypad.dart';

/// Modal Sheet Verifikasi PIN — MyFinance Minimal (Quiet, Clean, Premium).
class PinVerifySheet extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final Future<bool> Function(String pin) onPinEntered;

  const PinVerifySheet({
    super.key,
    this.title = 'Masukkan Kode Sandi PIN',
    this.subtitle = 'Verifikasi identitas Anda untuk melanjutkan',
    required this.onPinEntered,
  });

  static Future<bool?> show(
    BuildContext context, {
    String title = 'Masukkan Kode Sandi PIN',
    String subtitle = 'Verifikasi identitas Anda untuk melanjutkan',
    required Future<bool> Function(String pin) onPinEntered,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PinVerifySheet(
        title: title,
        subtitle: subtitle,
        onPinEntered: onPinEntered,
      ),
    );
  }

  @override
  ConsumerState<PinVerifySheet> createState() => _PinVerifySheetState();
}

class _PinVerifySheetState extends ConsumerState<PinVerifySheet> {
  String _enteredPin = '';
  String? _errorMessage;
  bool _isVerifying = false;

  void _onDigitPressed(String digit) {
    if (_isVerifying) return;
    bool shouldVerify = false;
    setState(() {
      _errorMessage = null;
      if (_enteredPin.length < 6) {
        _enteredPin += digit;
        if (_enteredPin.length == 6) {
          shouldVerify = true;
        }
      }
    });

    if (shouldVerify) {
      _verify();
    }
  }

  void _onDeletePressed() {
    if (_isVerifying) return;
    setState(() {
      _errorMessage = null;
      if (_enteredPin.isNotEmpty) {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      }
    });
  }

  Future<void> _verify() async {
    setState(() => _isVerifying = true);
    final isValid = await widget.onPinEntered(_enteredPin);
    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (isValid) {
      unawaited(AppHaptics.medium());
      if (mounted) Navigator.pop(context, true);
    } else {
      unawaited(AppHaptics.heavy());
      if (mounted) {
        setState(() {
          _errorMessage = 'Kode sandi salah. Silakan coba lagi.';
          _enteredPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceModalDark : AppColors.surfaceModalLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final expenseColor = isDark ? AppColors.expenseDark : AppColors.expenseLight;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle minimalis
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: AppTypography.title2.copyWith(fontSize: 17),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              widget.subtitle,
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),

            // Indikator Titik PIN
            PinDotsIndicator(
              currentLength: _enteredPin.length,
              hasError: _errorMessage != null,
            ),
            const SizedBox(height: 14),

            // Pesan Error (Zero Layout Shift)
            SizedBox(
              height: 22,
              child: _errorMessage != null
                  ? Text(
                      _errorMessage!,
                      style: AppTypography.caption.copyWith(
                        color: expenseColor,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 6),

            // Papan Tombol Angka Minimalis
            PinKeypad(
              onDigitPressed: _onDigitPressed,
              onDeletePressed: _onDeletePressed,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
