import 'package:flutter/material.dart';

/// Palet warna aplikasi MyFinance Minimal — Quiet, Clean, Premium.
///
/// Prinsip:
/// - Warna digunakan secara terbatas dan fungsional.
/// - Hijau murni untuk income / status positif.
/// - Merah murni untuk expense / status peringatan.
/// - Whitespace dan neutral tones sebagai pemisah utama.
class AppColors {
  AppColors._();

  // === Light Mode (Minimal & Clean) ===
  static const Color backgroundLight = Color(0xFFFAFAF8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color dividerLight = Color(0xFFE5E7EB);

  static const Color textPrimaryLight = Color(0xFF171717);
  static const Color textSecondaryLight = Color(0xFF737373);
  static const Color textTertiaryLight = Color(0xFFA3A3A3);
  static const Color textDisabledLight = Color(0xFFD4D4D4);

  // === Dark Mode (Quiet & Premium) ===
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1C1C1C);
  static const Color surfaceCardDark = Color(0xFF1C1C1C);
  static const Color surfaceElevatedDark = Color(0xFF262626);
  static const Color borderDark = Color(0xFF262626);
  static const Color dividerDark = Color(0xFF262626);

  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFA3A3A3);
  static const Color textTertiaryDark = Color(0xFF737373);
  static const Color textDisabledDark = Color(0xFF525252);

  // === Semantik: Income (Hijau Terbatas) ===
  static const Color incomeLight = Color(0xFF15803D);
  static const Color incomeDark = Color(0xFF22C55E);
  static const Color incomeContainerLight = Color(0xFFF0FDF4);
  static const Color incomeContainerDark = Color(0xFF14532D);

  // === Semantik: Expense (Merah Terbatas) ===
  static const Color expenseLight = Color(0xFFDC2626);
  static const Color expenseDark = Color(0xFFEF4444);
  static const Color expenseContainerLight = Color(0xFFFEF2F2);
  static const Color expenseContainerDark = Color(0xFF7F1D1D);

  // === Semantik: Transfer / Netral ===
  static const Color transferLight = Color(0xFF4B5563);
  static const Color transferDark = Color(0xFF9CA3AF);
  static const Color transferContainerLight = Color(0xFFF3F4F6);
  static const Color transferContainerDark = Color(0xFF262626);

  // === Semantik: Peringatan / Limit ===
  static const Color warningLight = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color warningContainerLight = Color(0xFFFFFBEB);
  static const Color warningContainerDark = Color(0xFF78350F);

  // === Brand / Aksen Utama (Minimalis Monokrom) ===
  static const Color primaryNavy = Color(0xFF171717);
  static const Color primaryNavyLight = Color(0xFF262626);

  // === Aliases untuk kompatibilitas mundur ===
  static const Color primary = incomeLight;
  static const Color primaryLight = incomeDark;
  static const Color error = expenseLight;
  static const Color errorLight = expenseDark;
  static const Color accent = transferLight;
  static const Color accentLight = transferDark;
  static const Color surfaceModalLight = surfaceElevatedLight;
  static const Color surfaceModalDark = surfaceElevatedDark;
}
