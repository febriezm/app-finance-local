import 'package:flutter/services.dart';

/// Utilitas getaran haptik khas Apple iOS
/// Menghasilkan umpan balik taktil yang halus dan presisi pada interaksi pengguna.
class AppHaptics {
  AppHaptics._();

  /// Haptik untuk seleksi ringan (ganti tab, geser slider, pilih kategori)
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Haptik untuk interaksi standar (tap tombol, toggle switch)
  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Haptik untuk aksi konfirmasi (simpan transaksi, pulihkan data)
  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Haptik untuk aksi berisiko atau penting (hapus data, void transaksi)
  static Future<void> heavy() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
