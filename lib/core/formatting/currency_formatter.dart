import 'package:intl/intl.dart';
import '../constants/currency_constants.dart';

/// Formatter khusus untuk mata uang Rupiah (IDR).
///
/// Seluruh nominal uang WAJIB menggunakan tipe [int] (integer Rupiah)
/// untuk mencegah floating-point rounding errors pada kalkulasi keuangan.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _idrNumberFormat = NumberFormat.currency(
    locale: CurrencyConstants.locale,
    symbol: '',
    decimalDigits: 0,
  );

  /// Format angka integer Rupiah menjadi string terformat.
  ///
  /// Contoh:
  /// - `format(1000000)` -> `"Rp 1.000.000"`
  /// - `format(-25000)` -> `"-Rp 25.000"`
  /// - `format(1000000, withSpace: false)` -> `"Rp1.000.000"`
  /// - `format(1000000, withSymbol: false)` -> `"1.000.000"`
  static String format(
    int amount, {
    bool withSymbol = true,
    bool withSpace = true,
  }) {
    final isNegative = amount < 0;
    final absoluteAmount = amount.abs();
    final formattedNumber = _idrNumberFormat.format(absoluteAmount).trim();

    if (!withSymbol) {
      return isNegative ? '-$formattedNumber' : formattedNumber;
    }

    final space = withSpace ? ' ' : '';
    final symbol = '${CurrencyConstants.currencySymbol}$space';

    return isNegative ? '-$symbol$formattedNumber' : '$symbol$formattedNumber';
  }

  /// Alias praktis format Rupiah
  static String formatRupiah(int amount) => format(amount);

  /// Parse string input dari pengguna menjadi integer Rupiah.
  /// Menghilangkan simbol "Rp", spasi, titik pemisah ribuan, dll.
  /// Mengembalikan 0 jika string kosong atau tidak valid.
  static int parse(String input) {
    if (input.trim().isEmpty) return 0;

    // Bersihkan karakter non-digit selain tanda minus
    final isNegative = input.contains('-');
    final digitsOnly = input.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) return 0;

    final parsed = int.tryParse(digitsOnly) ?? 0;
    return isNegative ? -parsed : parsed;
  }

  /// Format ringkas untuk angka besar pada chart/summary kartu (misal: "1,5 Jt", "500 Rb").
  static String formatCompact(int amount) {
    final isNegative = amount < 0;
    final abs = amount.abs();

    String result;
    if (abs >= 1000000000) {
      final value = (abs / 1000000000).toStringAsFixed(1).replaceAll('.0', '');
      result = '$value M';
    } else if (abs >= 1000000) {
      final value = (abs / 1000000).toStringAsFixed(1).replaceAll('.0', '');
      result = '$value Jt';
    } else if (abs >= 1000) {
      final value = (abs / 1000).toStringAsFixed(0);
      result = '$value Rb';
    } else {
      result = abs.toString();
    }

    final prefix = isNegative ? '-Rp ' : 'Rp ';
    return '$prefix$result';
  }
}
