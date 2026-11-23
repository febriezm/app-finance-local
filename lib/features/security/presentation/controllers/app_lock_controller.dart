import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/daos/app_settings_dao.dart';
import '../../../../core/services/app_lock_service.dart';

class AppLockState {
  final bool isAppLockEnabled;
  final bool isUnlocked;
  final bool hasPinSet;
  final bool isBiometricsAvailable;
  final bool isBiometricsEnabled;
  final bool isAuthenticating;
  final String? errorMessage;
  final int failedPinAttempts;
  final String biometricLabel;

  const AppLockState({
    this.isAppLockEnabled = false,
    this.isUnlocked = true,
    this.hasPinSet = false,
    this.isBiometricsAvailable = false,
    this.isBiometricsEnabled = false,
    this.isAuthenticating = false,
    this.errorMessage,
    this.failedPinAttempts = 0,
    this.biometricLabel = 'Biometrik',
  });

  AppLockState copyWith({
    bool? isAppLockEnabled,
    bool? isUnlocked,
    bool? hasPinSet,
    bool? isBiometricsAvailable,
    bool? isBiometricsEnabled,
    bool? isAuthenticating,
    String? errorMessage,
    int? failedPinAttempts,
    String? biometricLabel,
  }) {
    return AppLockState(
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      hasPinSet: hasPinSet ?? this.hasPinSet,
      isBiometricsAvailable: isBiometricsAvailable ?? this.isBiometricsAvailable,
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      errorMessage: errorMessage,
      failedPinAttempts: failedPinAttempts ?? this.failedPinAttempts,
      biometricLabel: biometricLabel ?? this.biometricLabel,
    );
  }
}

class AppLockController extends StateNotifier<AppLockState> {
  static const String keyAppLockEnabled = 'app_lock_enabled';
  static const String keyAppLockPinHash = 'app_lock_pin_hash';
  static const String keyAppLockBiometricsEnabled = 'app_lock_biometrics_enabled';

  final AppLockService _lockService;
  final AppSettingsDao? _appSettingsDao;
  DateTime? _pausedAt;

  AppLockController({
    required AppLockService lockService,
    AppSettingsDao? appSettingsDao,
    bool initialLockEnabled = false,
    bool initialHasPin = false,
  })  : _lockService = lockService,
        _appSettingsDao = appSettingsDao,
        super(AppLockState(
          isAppLockEnabled: initialLockEnabled,
          isUnlocked: !initialLockEnabled,
          hasPinSet: initialHasPin,
        )) {
    init();
  }

  Future<void> init() async {
    try {
      final bioAvailable = await _lockService.isBiometricsAvailable();
      final bioLabel = await _lockService.getBiometricTypeLabel();

      String? enabledStr;
      String? pinHash;
      String? bioEnabledStr;

      if (_appSettingsDao != null) {
        try {
          enabledStr = await _appSettingsDao.getSetting(keyAppLockEnabled);
          pinHash = await _appSettingsDao.getSetting(keyAppLockPinHash);
          bioEnabledStr = await _appSettingsDao.getSetting(keyAppLockBiometricsEnabled);
        } catch (e) {
          debugPrint('AppLockController: error reading settings: $e');
        }
      }

      final isEnabled = _appSettingsDao != null
          ? (enabledStr == 'true')
          : state.isAppLockEnabled;
      final hasPin = _appSettingsDao != null
          ? (pinHash != null && pinHash.isNotEmpty)
          : state.hasPinSet;
      final isBioEnabled = bioEnabledStr == 'true' || (bioAvailable && bioEnabledStr == null);

      state = state.copyWith(
        isAppLockEnabled: isEnabled,
        isUnlocked: !isEnabled,
        hasPinSet: hasPin,
        isBiometricsAvailable: bioAvailable,
        isBiometricsEnabled: isBioEnabled,
        biometricLabel: bioLabel,
      );
    } catch (e, st) {
      debugPrint('AppLockController init error: $e\n$st');
    }
  }

  /// Menyiapkan PIN 6-digit baru dan mengaktifkan Kunci Aplikasi
  Future<bool> setupPin(String pin, {bool enableBiometrics = true}) async {
    if (pin.length != 6) {
      state = state.copyWith(errorMessage: 'PIN harus terdiri dari 6 digit angka.');
      return false;
    }

    state = state.copyWith(isAuthenticating: true, errorMessage: null);
    final hash = AppLockService.hashPin(pin);

    if (_appSettingsDao != null) {
      await _appSettingsDao.setSetting(keyAppLockPinHash, hash);
      await _appSettingsDao.setSetting(keyAppLockEnabled, 'true');
      await _appSettingsDao.setSetting(
        keyAppLockBiometricsEnabled,
        enableBiometrics ? 'true' : 'false',
      );
    }

    state = state.copyWith(
      isAppLockEnabled: true,
      isUnlocked: true,
      hasPinSet: true,
      isBiometricsEnabled: enableBiometrics,
      isAuthenticating: false,
      errorMessage: null,
      failedPinAttempts: 0,
    );
    return true;
  }

  /// Membuka kunci menggunakan verifikasi PIN 6-digit
  Future<bool> unlockWithPin(String pin) async {
    String? storedHash;
    if (_appSettingsDao != null) {
      storedHash = await _appSettingsDao.getSetting(keyAppLockPinHash);
    }

    // Jika belum ada hash di DB, periksa state hasPinSet
    if (storedHash == null) {
      if (!state.hasPinSet) {
        state = state.copyWith(isUnlocked: true, errorMessage: null);
        return true;
      }
      state = state.copyWith(
        isUnlocked: false,
        errorMessage: 'Kode sandi belum dikonfigurasi.',
      );
      return false;
    }

    final isValid = AppLockService.verifyPin(pin, storedHash);
    if (isValid) {
      state = state.copyWith(
        isUnlocked: true,
        errorMessage: null,
        failedPinAttempts: 0,
      );
      return true;
    } else {
      final attempts = state.failedPinAttempts + 1;
      state = state.copyWith(
        isUnlocked: false,
        failedPinAttempts: attempts,
        errorMessage: 'Kode sandi salah. Silakan coba lagi.',
      );
      return false;
    }
  }

  /// Membuka kunci menggunakan Biometrik / Face ID
  Future<bool> unlockWithBiometrics() async {
    if (!state.isBiometricsAvailable || !state.isBiometricsEnabled) {
      return false;
    }

    state = state.copyWith(isAuthenticating: true, errorMessage: null);
    final success = await _lockService.authenticate(
      reason: 'Buka kunci MyFinance untuk mengakses data keuangan Anda',
    );

    if (success) {
      state = state.copyWith(
        isUnlocked: true,
        isAuthenticating: false,
        errorMessage: null,
        failedPinAttempts: 0,
      );
      return true;
    } else {
      state = state.copyWith(
        isAuthenticating: false,
        errorMessage: 'Verifikasi ${state.biometricLabel} tidak berhasil. Gunakan PIN.',
      );
      return false;
    }
  }

  /// Buka kunci umum (mencoba biometrik terlebih dahulu jika tersedia)
  Future<bool> unlock() async {
    if (!state.isAppLockEnabled || state.isUnlocked) {
      state = state.copyWith(isUnlocked: true);
      return true;
    }

    if (state.isBiometricsAvailable && state.isBiometricsEnabled) {
      final bioSuccess = await unlockWithBiometrics();
      if (bioSuccess) return true;
    }

    return false;
  }

  /// Menonaktifkan Kunci Aplikasi setelah verifikasi PIN yang benar
  Future<bool> disableAppLock(String pin) async {
    String? storedHash;
    if (_appSettingsDao != null) {
      storedHash = await _appSettingsDao.getSetting(keyAppLockPinHash);
    }

    if (storedHash != null && !AppLockService.verifyPin(pin, storedHash)) {
      state = state.copyWith(errorMessage: 'Kode sandi salah.');
      return false;
    }

    if (_appSettingsDao != null) {
      await _appSettingsDao.setSetting(keyAppLockEnabled, 'false');
    }

    state = state.copyWith(
      isAppLockEnabled: false,
      isUnlocked: true,
      errorMessage: null,
    );
    return true;
  }

  /// Mengubah PIN setelah verifikasi PIN lama
  Future<bool> changePin({required String oldPin, required String newPin}) async {
    String? storedHash;
    if (_appSettingsDao != null) {
      storedHash = await _appSettingsDao.getSetting(keyAppLockPinHash);
    }

    if (storedHash != null && !AppLockService.verifyPin(oldPin, storedHash)) {
      state = state.copyWith(errorMessage: 'Kode sandi lama salah.');
      return false;
    }

    if (newPin.length != 6) {
      state = state.copyWith(errorMessage: 'Kode sandi baru harus 6 digit.');
      return false;
    }

    final newHash = AppLockService.hashPin(newPin);
    if (_appSettingsDao != null) {
      await _appSettingsDao.setSetting(keyAppLockPinHash, newHash);
    }

    state = state.copyWith(errorMessage: null);
    return true;
  }

  /// Toggle biometrik on/off
  Future<void> setBiometricsEnabled(bool enable) async {
    if (_appSettingsDao != null) {
      await _appSettingsDao.setSetting(
        keyAppLockBiometricsEnabled,
        enable ? 'true' : 'false',
      );
    }
    state = state.copyWith(isBiometricsEnabled: enable);
  }

  /// Mengunci aplikasi secara manual
  void lock() {
    if (state.isAppLockEnabled) {
      state = state.copyWith(isUnlocked: false, errorMessage: null);
    }
  }

  /// Dipanggil saat aplikasi masuk ke background
  void onAppPaused() {
    _pausedAt = DateTime.now();
  }

  /// Dipanggil saat aplikasi kembali ke foreground
  Future<void> onAppResumed() async {
    if (!state.isAppLockEnabled) return;

    if (_pausedAt != null) {
      final elapsed = DateTime.now().difference(_pausedAt!);
      if (elapsed.inSeconds >= 1) {
        state = state.copyWith(isUnlocked: false, errorMessage: null);
        if (state.isBiometricsAvailable && state.isBiometricsEnabled) {
          await unlockWithBiometrics();
        }
      }
    }
  }

  /// Kompatibilitas mundur dengan toggleAppLock lama
  Future<bool> toggleAppLock(bool enable) async {
    if (!enable) {
      if (_appSettingsDao != null) {
        await _appSettingsDao.setSetting(keyAppLockEnabled, 'false');
      }
      state = state.copyWith(isAppLockEnabled: false, isUnlocked: true);
      return true;
    }
    return false;
  }
}
