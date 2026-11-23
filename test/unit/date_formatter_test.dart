import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myfinance/core/formatting/date_formatter.dart';
import 'package:myfinance/core/extensions/date_extension.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('DateFormatter Tests', () {
    test('toMonthKey generates YYYY-MM based on local date', () {
      final date = DateTime(2026, 11, 17, 15, 30);
      expect(AppDateFormatter.toMonthKey(date), equals('2026-11'));
      expect(date.toMonthKey(), equals('2026-11'));
    });

    test('toUtcIsoString and parseUtcToLocal consistency', () {
      final localNow = DateTime(2026, 11, 17, 15, 30);
      final utcIso = AppDateFormatter.toUtcIsoString(localNow);
      expect(utcIso.endsWith('Z'), isTrue);

      final parsed = AppDateFormatter.parseUtcToLocal(utcIso);
      expect(parsed.year, equals(localNow.year));
      expect(parsed.month, equals(localNow.month));
      expect(parsed.day, equals(localNow.day));
      expect(parsed.hour, equals(localNow.hour));
      expect(parsed.minute, equals(localNow.minute));
    });
  });
}
