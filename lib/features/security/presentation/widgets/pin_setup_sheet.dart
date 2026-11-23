import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_haptics.dart';
import 'pin_dots_indicator.dart';
import 'pin_keypad.dart';

/// Modal Sheet Pengaturan PIN — MyFinance Minimal (Quiet, Clean, Premium).
///
/// Alur:
/// 1. Masukkan 6 Digit Angka (Tahap 1).
/// 2. Konfirmasi 6 Digit Angka (Tahap 2).
/// 3. Validasi kecocokan PIN & simpan hash aman ke penyimpanan lokal.
class PinSetupSheet extends ConsumerStatefulWidget {
  final bool isChangingPin;
  final VoidCallback? onSuccess;

  const PinSetupSheet({
    super.key,
    this.isChangingPin = false,
    this.onSuccess,
  });

  static Future<bool?> show(BuildContext context, {bool isChangingPin = false}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PinSetupSheet(
        isChangingPin: isChangingPin,
        onSuccess: () => Navigator.of(ctx).pop(true),
      ),
    );
  }

  @override
  ConsumerState<PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends ConsumerState<PinSetupSheet> {
  String _firstPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;
  bool _enableBiometrics = true;
  bool _isSubmitting = false;

  void _onDigitPressed(String digit) {
    if (_isSubmitting) return;

    bool shouldFinalize = false;
    setState(() {
      _errorMessage = null;
      if (!_isConfirming) {
        if (_firstPin.length < 6) {
          _firstPin += digit;
          if (_firstPin.length == 6) {
            // Berpindah ke tahap konfirmasi
            Future.delayed(const Duration(milliseconds: 180), () {
              if (mounted) {
                setState(() {
                  _isConfirming = true;
                });
              }
            });
          }
        }
      } else {
        if (_confirmPin.length < 6) {
          _confirmPin += digit;
          if (_confirmPin.length == 6) {
            shouldFinalize = true;
          }
        }
      }
    });

    if (shouldFinalize) {
      _finalizePin();
    }
  }

  void _onDeletePressed() {
    if (_isSubmitting) return;

    setState(() {
      _errorMessage = null;
      if (!_isConfirming) {
        if (_firstPin.isNotEmpty) {
          _firstPin = _firstPin.substring(0, _firstPin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          // Kembali ke tahap awal jika menekan hapus saat konfirmasi kosong
          _isConfirming = false;
        }
      }
    });
  }

  Future<void> _finalizePin() async {
    setState(() => _isSubmitting = true);

    if (_firstPin == _confirmPin) {
      unawaited(AppHaptics.medium());
      final success = await ref.read(appLockControllerProvider.notifier).setupPin(
            _firstPin,
            enableBiometrics: _enableBiometrics,
          );
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          widget.onSuccess?.call();
        }
      }
    } else {
      unawaited(AppHaptics.heavy());
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Kode sandi konfirmasi tidak cocok. Ulangi kembali.';
          _confirmPin = '';
          _firstPin = '';
          _isConfirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lockState = ref.watch(appLockControllerProvider);
    final surfaceColor = isDark ? AppColors.surfaceModalDark : AppColors.surfaceModalLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final expenseColor = isDark ? AppColors.expenseDark : AppColors.expenseLight;
    final currentLength = _isConfirming ? _confirmPin.length : _firstPin.length;

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

            // Header Hening
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isChangingPin ? 'Ubah Kode Sandi PIN' : 'Atur Kode Sandi PIN',
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
            const SizedBox(height: 14),

            // Judul Tahap & Subtitle
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Column(
                key: ValueKey<bool>(_isConfirming),
                children: [
                  Text(
                    _isConfirming ? 'Konfirmasi Kode Sandi' : 'Masukkan 6 Digit Angka',
                    style: AppTypography.title2.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isConfirming
                        ? 'Masukkan kembali kode sandi untuk memverifikasi'
                        : 'Kode sandi ini akan digunakan untuk membuka aplikasi',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Indikator 6 Titik PIN
            PinDotsIndicator(
              currentLength: currentLength,
              hasError: _errorMessage != null,
            ),
            const SizedBox(height: 14),

            // Pesan Status / Error (Zero Layout Shift)
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

            // Opsi Biometrik jika perangkat mendukung (pada tahap awal)
            if (lockState.isBiometricsAvailable) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () {
                    unawaited(AppHaptics.selection());
                    setState(() {
                      _enableBiometrics = !_enableBiometrics;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _enableBiometrics,
                            activeColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            checkColor: isDark ? AppColors.backgroundDark : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() {
                                _enableBiometrics = val ?? true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Aktifkan juga ${lockState.biometricLabel}',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
            ],

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
