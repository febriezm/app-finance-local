import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'web_auth_helper.dart';

/// Service untuk mengelola autentikasi keamanan (Biometrik / Face ID / Touch ID / PIN)
/// Beroperasi 100% lokal di Secure Enclave & penyimpanan lokal privat tanpa server/cloud.
class AppLockService {
  final LocalAuthentication? _auth;

  AppLockService({LocalAuthentication? auth})
      : _auth = kIsWeb ? null : (auth ?? LocalAuthentication());

  /// Memeriksa apakah perangkat mendukung dan memiliki biometrik aktif
  Future<bool> isBiometricsAvailable() async {
    if (kIsWeb) {
      try {
        return await WebAuthHelper.isAvailable();
      } catch (_) {
        return false;
      }
    }

    try {
      if (_auth == null) return false;
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (e) {
      debugPrint('Biometrics check error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Mendapatkan daftar jenis biometrik yang tersedia di perangkat (Face ID / Fingerprint)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];
    try {
      if (_auth == null) return [];
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Label jenis biometrik yang ramah pengguna
  Future<String> getBiometricTypeLabel() async {
    if (kIsWeb) {
      final webAuthAvailable = await WebAuthHelper.isAvailable();
      if (webAuthAvailable) {
        return 'Face ID / Touch ID';
      }
      return 'Kode Sandi PIN';
    }

    final biometrics = await getAvailableBiometrics();
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Touch ID / Sidik Jari';
    }
    return 'Biometrik Perangkat';
  }

  /// Meminta otentikasi biometrik dengan fallback ke PIN perangkat
  Future<bool> authenticate({
    String reason = 'Buka kunci MyFinance untuk mengakses data keuangan Anda',
  }) async {
    if (kIsWeb) {
      try {
        return await WebAuthHelper.authenticate(reason);
      } catch (_) {
        return false;
      }
    }

    try {
      if (_auth == null) return false;
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Menghentikan otentikasi yang sedang berjalan bila ada
  Future<void> cancelAuthentication() async {
    if (kIsWeb) return;
    try {
      await _auth?.stopAuthentication();
    } catch (_) {}
  }

  /// Meng-hash PIN menggunakan SHA-256
  static String hashPin(String pin) {
    final bytes = utf8.encode('myfinance_salt_$pin');
    return sha256.convert(bytes).toString();
  }

  /// Memvalidasi PIN terhadap hash yang tersimpan
  static bool verifyPin(String pin, String storedHash) {
    return hashPin(pin) == storedHash;
  }
}
