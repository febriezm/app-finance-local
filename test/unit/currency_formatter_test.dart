import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/core/formatting/currency_formatter.dart';
import 'package:myfinance/core/extensions/currency_extension.dart';

void main() {
  group('CurrencyFormatter Tests (Strict Integer Math)', () {
    test('format integer Rupiah with symbol and space', () {
      expect(CurrencyFormatter.format(1000000), equals('Rp 1.000.000'));
      expect(CurrencyFormatter.format(50000), equals('Rp 50.000'));
      expect(CurrencyFormatter.format(0), equals('Rp 0'));
    });

    test('format negative integer Rupiah', () {
      expect(CurrencyFormatter.format(-1000000), equals('-Rp 1.000.000'));
      expect(CurrencyFormatter.format(-25000), equals('-Rp 25.000'));
    });

    test('format without symbol or without space', () {
      expect(
        CurrencyFormatter.format(1000000, withSymbol: false),
        equals('1.000.000'),
      );
      expect(
        CurrencyFormatter.format(-50000, withSymbol: false),
        equals('-50.000'),
      );
      expect(
        CurrencyFormatter.format(1000000, withSpace: false),
        equals('Rp1.000.000'),
      );
    });

    test('parse user input correctly into integer Rupiah', () {
      expect(CurrencyFormatter.parse('1000000'), equals(1000000));
      expect(CurrencyFormatter.parse('1.000.000'), equals(1000000));
      expect(CurrencyFormatter.parse('Rp 1.000.000'), equals(1000000));
      expect(CurrencyFormatter.parse('Rp1.500.000'), equals(1500000));
      expect(CurrencyFormatter.parse('-50.000'), equals(-50000));
      expect(CurrencyFormatter.parse(''), equals(0));
      expect(CurrencyFormatter.parse('abc'), equals(0));
    });

    test('formatCompact displays clean representations', () {
      expect(CurrencyFormatter.formatCompact(1500000000), equals('Rp 1.5 M'));
      expect(CurrencyFormatter.formatCompact(1000000000), equals('Rp 1 M'));
      expect(CurrencyFormatter.formatCompact(2500000), equals('Rp 2.5 Jt'));
      expect(CurrencyFormatter.formatCompact(1000000), equals('Rp 1 Jt'));
      expect(CurrencyFormatter.formatCompact(500000), equals('Rp 500 Rb'));
      expect(CurrencyFormatter.formatCompact(500), equals('Rp 500'));
      expect(CurrencyFormatter.formatCompact(-1000000), equals('-Rp 1 Jt'));
    });

    test('CurrencyIntExtension works seamlessly on int', () {
      expect(1000000.toRupiah(), equals('Rp 1.000.000'));
      expect(1000000.toRupiah(withSpace: false), equals('Rp1.000.000'));
      expect(1000000.toRupiahNumber(), equals('1.000.000'));
      expect(1000000.toRupiahCompact(), equals('Rp 1 Jt'));
    });
  });
}
