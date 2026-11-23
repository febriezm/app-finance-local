import 'package:flutter/material.dart';

/// Tipografi aplikasi MyFinance Minimal — Typography-First, Clean, Quiet.
///
/// Skala Tipografi:
/// - Large balance: 30-34 px (dengan tabular figures).
/// - Page title: 22-24 px.
/// - Section title: 16 px.
/// - Body: 14 px.
/// - Caption: 11-12 px.
class AppTypography {
  AppTypography._();

  // === Angka Finansial (Tabular Figures) ===
  static const TextStyle balanceLarge = TextStyle(
    fontSize: 32, // 30-34px
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.15,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle balanceMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle balanceSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.25,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // === Judul & Bagian (Titles & Sections) ===
  static const TextStyle pageTitle = TextStyle(
    fontSize: 24, // 22-24px
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16, // 16px
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  // === Teks Isi (Body Text) ===
  static const TextStyle body = TextStyle(
    fontSize: 14, // 14px
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.45,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.45,
  );

  // === Teks Keterangan (Captions & Footnotes) ===
  static const TextStyle caption = TextStyle(
    fontSize: 12, // 11-12px
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    height: 1.35,
  );

  static const TextStyle caption2 = TextStyle(
    fontSize: 11, // 11px
    fontWeight: FontWeight.w400,
    letterSpacing: 0.05,
    height: 1.3,
  );

  // === Kompatibilitas Mundur (Aliases untuk kode yang memanggil nama lama) ===
  static const TextStyle largeTitle = pageTitle;
  static const TextStyle title1 = pageTitle;
  static const TextStyle title2 = pageTitle;
  static const TextStyle title3 = sectionTitle;
  static const TextStyle headline = sectionTitle;
  static const TextStyle subhead = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    height: 1.35,
  );
  static const TextStyle callout = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    height: 1.35,
  );
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.35,
  );
  static const TextStyle caption1 = caption;
}
