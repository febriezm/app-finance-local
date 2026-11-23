import 'package:intl/intl.dart';

/// Formatter tanggal dan waktu aplikasi.
///
/// Aturan:
/// - Penyimpanan database menggunakan ISO-8601 UTC string (`toIso8601String()`).
/// - Tampilan UI selalu dikonversi ke waktu lokal perangkat pengguna (`toLocal()`).
/// - Penentuan periode bulan `month_key` (`YYYY-MM`) didasarkan pada tanggal lokal pengguna.
class AppDateFormatter {
  AppDateFormatter._();

  static const String locale = 'id_ID';

  static const List<String> _indonesianMonths = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static const List<String> _indonesianMonthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  /// Menghasilkan format `month_key` YYYY-MM dari DateTime lokal.
  static String toMonthKey(DateTime dateTime) {
    final local = dateTime.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  /// Format tanggal: `17 Nov 2026`
  static String formatDate(DateTime dateTime) {
    try {
      return DateFormat('dd MMM yyyy', locale).format(dateTime.toLocal());
    } catch (_) {
      final local = dateTime.toLocal();
      final day = local.day.toString().padLeft(2, '0');
      final month = _indonesianMonthsShort[local.month - 1];
      return '$day $month ${local.year}';
    }
  }

  /// Format tanggal & waktu: `17 Nov 2026, 15:30`
  static String formatDateTime(DateTime dateTime) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', locale).format(dateTime.toLocal());
    } catch (_) {
      final local = dateTime.toLocal();
      final day = local.day.toString().padLeft(2, '0');
      final month = _indonesianMonthsShort[local.month - 1];
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$day $month ${local.year}, $hour:$minute';
    }
  }

  /// Format string ISO UTC menjadi tanggal & waktu lokal: `17 Nov 2026, 15:30`
  static String formatDateAndTime(String isoUtcString) {
    try {
      final dt = parseUtcToLocal(isoUtcString);
      return formatDateTime(dt);
    } catch (_) {
      return isoUtcString;
    }
  }

  /// Format bulan & tahun: `November 2026`
  static String formatMonthYear(DateTime dateTime) {
    try {
      return DateFormat('MMMM yyyy', locale).format(dateTime.toLocal());
    } catch (_) {
      final local = dateTime.toLocal();
      final month = _indonesianMonths[local.month - 1];
      return '$month ${local.year}';
    }
  }

  /// Format hari & bulan: `17 Nov`
  static String formatDayMonth(DateTime dateTime) {
    try {
      return DateFormat('dd MMM', locale).format(dateTime.toLocal());
    } catch (_) {
      final local = dateTime.toLocal();
      final day = local.day.toString().padLeft(2, '0');
      final month = _indonesianMonthsShort[local.month - 1];
      return '$day $month';
    }
  }

  /// Konversi string ISO-8601 dari database menjadi DateTime lokal.
  static DateTime parseUtcToLocal(String isoUtcString) {
    return DateTime.parse(isoUtcString).toLocal();
  }

  /// Konversi DateTime menjadi ISO-8601 string UTC untuk penyimpanan database.
  static String toUtcIsoString(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// Menghasilkan teks salam dinamis (Selamat pagi/siang/sore/malam) berdasarkan waktu lokal.
  static String getGreeting([DateTime? dateTime]) {
    final localTime = (dateTime ?? DateTime.now()).toLocal();
    final hour = localTime.hour;
    if (hour >= 4 && hour < 11) {
      return 'Selamat pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat siang';
    } else if (hour >= 15 && hour < 19) {
      return 'Selamat sore';
    } else {
      return 'Selamat malam';
    }
  }
}

typedef DateFormatter = AppDateFormatter;
