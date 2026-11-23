import 'package:flutter/material.dart';

/// Spacing, padding, and layout metrics based on Apple Human Interface Guidelines.
///
/// Aturan:
/// - Menggunakan sistem grid 8-point (4, 8, 12, 16, 20, 24, 32, 40, 48).
/// - Touch target minimum: 44 x 44 pt untuk mobile iOS.
class AppSpacing {
  AppSpacing._();

  static const double xxxs = 2.0;
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;

  // Minimum Apple Touch Target Size (Mobile)
  static const double minTouchTarget = 44.0;

  // Standard Border Radii
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 18.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 999.0;

  // Standard EdgeInsets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets listTilePadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
}
