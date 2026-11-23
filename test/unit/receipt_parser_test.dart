import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/features/receipt_scanner/domain/entities/ocr_result.dart';
import 'package:myfinance/features/receipt_scanner/data/services/local_receipt_parser.dart';
import 'package:myfinance/features/receipt_scanner/data/services/receipt_ocr_service_impl.dart';

void main() {
  late LocalReceiptParser parser;

  setUp(() {
    parser = const LocalReceiptParser();
  });

  group('Phase 3 - Local Receipt Parser Unit Tests', () {
    test('1. Minimarket (Indomaret) parses merchant, date, items, subtotal, PPN, and total correctly', () async {
      final sample = ReceiptOcrServiceImpl.sampleReceipts['indomaret']!;
      final ocrResult = OcrResult.fromString(sample);

      final draft = await parser.parse(ocrResult);

      expect(draft.merchant, equals('Indomaret'));
      expect(draft.isMerchantCertain, isTrue);
      expect(draft.suggestedCategoryId, equals('cat-exp-shopping'));

      // Tanggal: 17/11/2026 14:25
      expect(draft.occurredAt, isNotNull);
      expect(draft.occurredAt!.year, equals(2026));
      expect(draft.occurredAt!.month, equals(11));
      expect(draft.occurredAt!.day, equals(17));
      expect(draft.isDateCertain, isTrue);

      // Total belanja Rp 47.730 (Bukan TUNAI Rp 100.000 atau KEMBALIAN Rp 52.270!)
      expect(draft.totalAmount, equals(47730));
      expect(draft.subtotal, equals(43000));
      expect(draft.taxAmount, equals(4730));
      expect(draft.isTotalCertain, isTrue);

      // Line items
      expect(draft.items.length, greaterThanOrEqualTo(3));
      final indomilk = draft.items.firstWhere((i) => i.name.contains('INDOMILK'));
      expect(indomilk.quantity, equals(1));
      expect(indomilk.unitPrice, equals(7500));
      expect(indomilk.totalPrice, equals(7500));
    });

    test('2. Restoran (HokBen) parses merchant, PB1, Service charge, and Grand Total', () async {
      final sample = ReceiptOcrServiceImpl.sampleReceipts['restoran']!;
      final ocrResult = OcrResult.fromString(sample);

      final draft = await parser.parse(ocrResult);

      expect(draft.merchant, equals('HokBen'));
      expect(draft.suggestedCategoryId, equals('cat-exp-food'));

      // Tanggal: 17 Nov 2026 19:15
      expect(draft.occurredAt!.year, equals(2026));
      expect(draft.occurredAt!.month, equals(11));
      expect(draft.occurredAt!.day, equals(17));

      // Financials: Subtotal 146.000, PB1 14.600, Service 7.300, Grand Total 167.900
      expect(draft.subtotal, equals(146000));
      expect(draft.taxAmount, equals(14600));
      expect(draft.serviceCharge, equals(7300));
      expect(draft.totalAmount, equals(167900));
      expect(draft.isTotalCertain, isTrue);

      // Items
      expect(draft.items.isNotEmpty, isTrue);
    });

    test('3. SPBU (Pertamina) parses fuel purchase and category transport', () async {
      final sample = ReceiptOcrServiceImpl.sampleReceipts['spbu']!;
      final ocrResult = OcrResult.fromString(sample);

      final draft = await parser.parse(ocrResult);

      expect(draft.merchant, contains('Pertamina'));
      expect(draft.suggestedCategoryId, equals('cat-exp-transport'));
      expect(draft.totalAmount, equals(250000));
      expect(draft.isTotalCertain, isTrue);
    });

    test('4. Kafe (Starbucks) avoids CASH/CHANGE and captures Total Bayar', () async {
      final sample = ReceiptOcrServiceImpl.sampleReceipts['kafe']!;
      final ocrResult = OcrResult.fromString(sample);

      final draft = await parser.parse(ocrResult);

      expect(draft.merchant, equals('Starbucks'));
      expect(draft.suggestedCategoryId, equals('cat-exp-food'));
      expect(draft.subtotal, equals(149000));
      expect(draft.taxAmount, equals(14900));
      expect(draft.totalAmount, equals(163900));
      expect(draft.totalAmount, isNot(equals(200000))); // Bukan uang tunai yang diserahkan
      expect(draft.isTotalCertain, isTrue);
    });

    test('5. Ambiguous receipt flags isTotalCertain as false to require manual confirmation', () async {
      final sample = ReceiptOcrServiceImpl.sampleReceipts['ambiguous']!;
      final ocrResult = OcrResult.fromString(sample);

      final draft = await parser.parse(ocrResult);

      // Tidak ada kata kunci TOTAL eksplisit -> isTotalCertain harus false
      expect(draft.isTotalCertain, isFalse);
      expect(draft.merchant, equals('TOKO SERBA ADA'));
      expect(draft.isMerchantCertain, isFalse); // Bukan merchant populer
    });

    test('6. Empty OCR input returns safe empty draft without crashing', () async {
      final ocrResult = OcrResult.fromString('');
      final draft = await parser.parse(ocrResult);

      expect(draft.merchant, isNull);
      expect(draft.totalAmount, isNull);
      expect(draft.isTotalCertain, isFalse);
      expect(draft.items, isEmpty);
    });

    test('7. Random non-receipt image input does not fake Indomaret and returns empty OcrResult', () async {
      const ocrService = ReceiptOcrServiceImpl();
      // Simulasikan pemindaian foto kamera acak
      final ocrResult = await ocrService.recognize('camera_photo_random.jpg');

      expect(ocrResult.lines, isEmpty);
      expect(ocrResult.rawText, isEmpty);

      final draft = await parser.parse(ocrResult);
      expect(draft.merchant, isNull);
      expect(draft.totalAmount, isNull);
      expect(draft.isTotalCertain, isFalse);
      expect(draft.isMerchantCertain, isFalse);
    });

    test('8. Image bytes are preserved across ReceiptDraft for attachment saving', () async {
      final fakeBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final ocrResult = OcrResult.fromString('', imagePath: 'user_pic.jpg');
      final draft = await parser.parse(ocrResult, imageBytes: fakeBytes);

      expect(draft.imageBytes, equals(fakeBytes));
      expect(draft.imagePath, equals('user_pic.jpg'));
    });

    test('9. Real Minimarket receipt (Mekar Store) parses merchant, date/time on separate lines, items, and total 7.700', () async {
      const mekarStoreText = '''
Mekar Store
Jl. Mekar Kencana No.22

NO : R43-031126252          03/11/2026
Pelanggan :                 18:23:45
OPR : KASIR 1

ULTRAMILK LOW FAT FRESH MILK 250ML/89980
1             7,700             7,700

ITEM : 1          Total   :     7,700
@ITEM: 1          Bayar   :    10,000
                  Kembali :     2,300

Terima kasih !!!Silahkan datang kembali
''';

      final ocrResult = OcrResult.fromString(mekarStoreText);
      final draft = await parser.parse(ocrResult);

      // Merchant
      expect(draft.merchant, equals('Mekar Store'));
      expect(draft.suggestedCategoryId, equals('cat-exp-shopping'));

      // Date & Time (Date on line 3, Time on line 4)
      expect(draft.occurredAt, isNotNull);
      expect(draft.occurredAt!.year, equals(2026));
      expect(draft.occurredAt!.month, equals(11));
      expect(draft.occurredAt!.day, equals(3));
      expect(draft.occurredAt!.hour, equals(18));
      expect(draft.occurredAt!.minute, equals(23));

      // Financials: Total 7.700 (bukan Bayar 10.000 atau Kembali 2.300!)
      expect(draft.totalAmount, equals(7700));
      expect(draft.isTotalCertain, isTrue);

      // Line items: ULTRAMILK LOW FAT FRESH MILK 250ML/89980
      expect(draft.items.length, equals(1));
      final item = draft.items.first;
      expect(item.name, contains('ULTRAMILK'));
      expect(item.quantity, equals(1));
      expect(item.unitPrice, equals(7700));
      expect(item.totalPrice, equals(7700));
    });

    test('8. ISO date YYYY-MM-DD in gallery receipt parses year as 2026, NOT 2017', () async {
      const isoReceiptText = '''
SUPERMARKET HERO
Tanggal: 2026-11-17 10:45:00
Kasir: 02

ROTI TAWAR SARI ROTI
1 x 15,000       15,000

TOTAL:          15,000
TUNAI:          20,000
KEMBALI:         5,000
''';
      final ocrResult = OcrResult.fromString(isoReceiptText);
      final draft = await parser.parse(ocrResult);

      expect(draft.occurredAt, isNotNull);
      expect(draft.occurredAt!.year, equals(2026));
      expect(draft.occurredAt!.month, equals(11));
      expect(draft.occurredAt!.day, equals(17));
      expect(draft.occurredAt!.hour, equals(10));
      expect(draft.occurredAt!.minute, equals(45));
      expect(draft.totalAmount, equals(15000));
      expect(draft.isDateCertain, isTrue);
    });

    test('9. Gallery receipt with earlier month (2026/10/25) preserves month 10', () async {
      const pastReceiptText = '''
KAFE KENANGAN
Date: 2026/10/25 14:10

KOPI KENANGAN MANTAN
1 x 22,000       22,000

TOTAL:          22,000
''';
      final ocrResult = OcrResult.fromString(pastReceiptText);
      final draft = await parser.parse(ocrResult);

      expect(draft.occurredAt, isNotNull);
      expect(draft.occurredAt!.year, equals(2026));
      expect(draft.occurredAt!.month, equals(10));
      expect(draft.occurredAt!.day, equals(25));
      expect(draft.totalAmount, equals(22000));
    });
  });
}
