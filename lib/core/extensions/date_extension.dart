import '../formatting/date_formatter.dart';

extension AppDateExtension on DateTime {
  /// Mengembalikan `month_key` dalam format `YYYY-MM` waktu lokal.
  String toMonthKey() => AppDateFormatter.toMonthKey(this);

  /// Format tanggal: `17 Nov 2026`
  String toDisplayDate() => AppDateFormatter.formatDate(this);

  /// Format tanggal & waktu: `17 Nov 2026, 15:30`
  String toDisplayDateTime() => AppDateFormatter.formatDateTime(this);

  /// Format bulan & tahun: `November 2026`
  String toDisplayMonthYear() => AppDateFormatter.formatMonthYear(this);

  /// String ISO-8601 dalam UTC untuk SQLite.
  String toUtcIso() => AppDateFormatter.toUtcIsoString(this);
}
