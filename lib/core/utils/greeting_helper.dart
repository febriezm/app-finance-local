/// Helper penentu salam (greeting) dinamis berdasarkan waktu lokal perangkat pengguna.
///
/// Aturan Waktu:
/// - 04:00–10:59 = Selamat pagi
/// - 11:00–14:59 = Selamat siang
/// - 15:00–18:59 = Selamat sore
/// - 19:00–03:59 = Selamat malam
class GreetingHelper {
  GreetingHelper._();

  /// Menghasilkan teks salam berdasarkan [time] lokal perangkat (default: [DateTime.now()]).
  /// Selalu mengevaluasi jam lokal (`toLocal()`), bukan UTC atau hardcoded timezone.
  static String getGreeting([DateTime? time]) {
    final localTime = (time ?? DateTime.now()).toLocal();
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

  /// Menghitung durasi hingga batas periode pergantian salam berikutnya.
  /// Memungkinkan pembaruan salam secara tepat waktu tanpa polling berulang.
  static Duration durationUntilNextPeriod([DateTime? time]) {
    final now = (time ?? DateTime.now()).toLocal();
    final today = DateTime(now.year, now.month, now.day);

    // Titik batas waktu pergantian salam: 04:00, 11:00, 15:00, 19:00, dan 04:00 esok hari
    final boundaries = [
      today.add(const Duration(hours: 4)),
      today.add(const Duration(hours: 11)),
      today.add(const Duration(hours: 15)),
      today.add(const Duration(hours: 19)),
      today.add(const Duration(days: 1, hours: 4)),
    ];

    for (final boundary in boundaries) {
      if (boundary.isAfter(now)) {
        return boundary.difference(now) + const Duration(seconds: 1);
      }
    }

    return const Duration(hours: 1);
  }
}
