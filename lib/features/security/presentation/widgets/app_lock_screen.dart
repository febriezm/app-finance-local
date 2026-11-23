import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_haptics.dart';
import 'pin_dots_indicator.dart';
import 'pin_keypad.dart';

/// Layar Kunci Aplikasi — MyFinance Minimal (Quiet, Clean, Premium).
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _enteredPin = '';
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoBiometrics();
    });
  }

  Future<void> _tryAutoBiometrics() async {
    final lockState = ref.read(appLockControllerProvider);
    if (lockState.isBiometricsAvailable && lockState.isBiometricsEnabled) {
      await ref.read(appLockControllerProvider.notifier).unlockWithBiometrics();
    }
  }

  void _onDigitPressed(String digit) {
    if (_isChecking) return;
    bool shouldVerify = false;
    setState(() {
      if (_enteredPin.length < 6) {
        _enteredPin += digit;
        if (_enteredPin.length == 6) {
          shouldVerify = true;
        }
      }
    });

    if (shouldVerify) {
      _verifyPin();
    }
  }

  void _onDeletePressed() {
    if (_isChecking) return;

    setState(() {
      if (_enteredPin.isNotEmpty) {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      }
    });
  }

  Future<void> _verifyPin() async {
    setState(() => _isChecking = true);
    final success = await ref
        .read(appLockControllerProvider.notifier)
        .unlockWithPin(_enteredPin);
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (success) {
      unawaited(AppHaptics.medium());
    } else {
      unawaited(AppHaptics.heavy());
      if (mounted) {
        setState(() {
          _enteredPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lockState = ref.watch(appLockControllerProvider);
    final bgScaffold = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final expenseColor = isDark ? AppColors.expenseDark : AppColors.expenseLight;

    return Scaffold(
      backgroundColor: bgScaffold,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(height: 12),

                      // Bagian Atas: Gembok Minimalis & Judul
                      Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor, width: 0.8),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 26,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'MyFinance Terkunci',
                            style: AppTypography.pageTitle.copyWith(fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Masukkan 6 digit kode sandi Anda',
                            style: AppTypography.caption.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),

                          // Indikator Titik PIN
                          PinDotsIndicator(
                            currentLength: _enteredPin.length,
                            hasError: lockState.errorMessage != null,
                          ),

                          const SizedBox(height: 14),

                          // Pesan Error jika salah
                          SizedBox(
                            height: 24,
                            child: lockState.errorMessage != null
                                ? Text(
                                    lockState.errorMessage!,
                                    style: AppTypography.caption.copyWith(
                                      color: expenseColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),

                      // Bagian Bawah: Keypad Numerik
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PinKeypad(
                          onDigitPressed: _onDigitPressed,
                          onDeletePressed: _onDeletePressed,
                          showBiometricButton: lockState.isBiometricsAvailable && lockState.isBiometricsEnabled,
                          biometricIcon: Icons.fingerprint_rounded,
                          onBiometricPressed: () {
                            ref.read(appLockControllerProvider.notifier).unlockWithBiometrics();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
