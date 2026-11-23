import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/core/formatting/date_formatter.dart';
import 'package:myfinance/core/utils/greeting_helper.dart';

void main() {
  group('GreetingHelper & Dynamic Greeting Unit Tests', () {
    test('Pukul 06:00 menghasilkan Selamat pagi', () {
      final time = DateTime(2026, 11, 22, 6, 0);
      expect(GreetingHelper.getGreeting(time), equals('Selamat pagi'));
      expect(AppDateFormatter.getGreeting(time), equals('Selamat pagi'));
    });

    test('Pukul 12:00 menghasilkan Selamat siang', () {
      final time = DateTime(2026, 11, 22, 12, 0);
      expect(GreetingHelper.getGreeting(time), equals('Selamat siang'));
      expect(AppDateFormatter.getGreeting(time), equals('Selamat siang'));
    });

    test('Pukul 16:00 menghasilkan Selamat sore', () {
      final time = DateTime(2026, 11, 22, 16, 0);
      expect(GreetingHelper.getGreeting(time), equals('Selamat sore'));
      expect(AppDateFormatter.getGreeting(time), equals('Selamat sore'));
    });

    test('Pukul 21:00 menghasilkan Selamat malam', () {
      final time = DateTime(2026, 11, 22, 21, 0);
      expect(GreetingHelper.getGreeting(time), equals('Selamat malam'));
      expect(AppDateFormatter.getGreeting(time), equals('Selamat malam'));
    });

    test('Pukul 00:00 (tengah malam) menghasilkan Selamat malam', () {
      final time = DateTime(2026, 11, 22, 0, 0);
      expect(GreetingHelper.getGreeting(time), equals('Selamat malam'));
      expect(AppDateFormatter.getGreeting(time), equals('Selamat malam'));
    });

    test('Pukul 03:00 (dini hari) menghasilkan Selamat malam', () {
      final time = DateTime(2026, 11, 22, 3, 0);
      expect(GreetingHelper.getGreeting(time), equals('Selamat malam'));
      expect(AppDateFormatter.getGreeting(time), equals('Selamat malam'));
    });

    test('Uji batas rentang (Boundary conditions)', () {
      // 03:59:59 -> Selamat malam
      expect(GreetingHelper.getGreeting(DateTime(2026, 11, 22, 3, 59, 59)), equals('Selamat malam'));

      // 04:00:00 -> Selamat pagi (tepat batas pagi)
      expect(GreetingHelper.getGreeting(DateTime(2026, 11, 22, 4, 0, 0)), equals('Selamat pagi'));

      // 10:59:59 -> Selamat pagi (akhir batas pagi)
      expect(GreetingHelper.getGreeting(DateTime(2026, 11, 22, 10, 59, 59)), equals('Selamat pagi'));

      // 11:00:00 -> Selamat siang (tepat batas siang)
      expect(GreetingHelper.getGreeting(DateTime(2026, 11, 22, 11, 0, 0)), equals('Selamat siang'));

      // 14:59:59 -> Selamat siang (akhir batas siang)
      expect(GreetingHelper.getGreeting(DateTime(2026, 11, 22, 14, 59, 59)), equals('Selamat siang'));

      // 15:00:00 -> Selamat sore (tepat batas sore)
      expect(GreetingHelper.getGreeting(DateTime(2026, 11, 22, 15, 0, 0)), equals('Selamat sore'));

      // 18:59:59 -> Selamat sore (akhir batas sore)
      expect(GreetingHelper.getGreeting(DateTime(2026, 11, 22, 18, 59, 59)), equals('Selamat sore'));

      // 19:00:00 -> Selamat malam (tepat batas malam)
      expect(GreetingHelper.getGreeting(DateTime(2026, 11, 22, 19, 0, 0)), equals('Selamat malam'));

      // 23:59:59 -> Selamat malam (akhir batas malam hari ini)
      expect(GreetingHelper.getGreeting(DateTime(2026, 11, 22, 23, 59, 59)), equals('Selamat malam'));
    });

    test('Uji durasi hingga periode berikutnya (durationUntilNextPeriod)', () {
      // Jika saat ini 10:55, batas berikutnya adalah 11:00 (5 menit + 1 detik)
      final at1055 = DateTime(2026, 11, 22, 10, 55, 0);
      final duration = GreetingHelper.durationUntilNextPeriod(at1055);
      expect(duration.inMinutes, equals(5));

      // Jika saat ini 14:30, batas berikutnya adalah 15:00 (30 menit + 1 detik)
      final at1430 = DateTime(2026, 11, 22, 14, 30, 0);
      final durationSiang = GreetingHelper.durationUntilNextPeriod(at1430);
      expect(durationSiang.inMinutes, equals(30));

      // Jika saat ini 23:00, batas berikutnya adalah 04:00 esok hari (5 jam + 1 detik)
      final at2300 = DateTime(2026, 11, 22, 23, 0, 0);
      final durationMalam = GreetingHelper.durationUntilNextPeriod(at2300);
      expect(durationMalam.inHours, equals(5));
    });

    test('Waktu UTC otomatis dikonversi ke waktu lokal perangkat', () {
      // Ambil waktu sekarang dalam UTC dan Local
      final nowUtc = DateTime.now().toUtc();
      final expectedGreeting = GreetingHelper.getGreeting(DateTime.now());
      // GreetingHelper.getGreeting(nowUtc) harus sama dengan expectedGreeting karena di-toLocal()
      expect(GreetingHelper.getGreeting(nowUtc), equals(expectedGreeting));
    });
  });
}
