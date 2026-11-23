import '../formatting/currency_formatter.dart';

extension CurrencyIntExtension on int {
  /// Format integer ini menjadi Rupiah dengan simbol `Rp`.
  String toRupiah({bool withSpace = true}) =>
      CurrencyFormatter.format(this, withSymbol: true, withSpace: withSpace);

  /// Format integer ini tanpa simbol `Rp`.
  String toRupiahNumber() =>
      CurrencyFormatter.format(this, withSymbol: false);

  /// Format integer ini secara ringkas (contoh: Rp 1,5 Jt).
  String toRupiahCompact() => CurrencyFormatter.formatCompact(this);
}
