import 'dart:typed_data';
import '../../domain/entities/ocr_result.dart';
import '../../domain/entities/receipt_draft.dart';
import '../../domain/entities/receipt_item_draft.dart';
import '../../domain/repositories/receipt_understanding_service.dart';

/// Parser cerdas lokal untuk mengekstraksi informasi struk belanja di Indonesia.
/// Mematuhi Blueprint Section 4.5:
/// - Pengenalan merchant, tanggal, subtotal, pajak, total, dan item.
/// - Menandai tingkat kepastian (confidence flags) untuk field yang ambigu.
/// - Tidak pernah mengasumsikan angka mengambang (semua nominal integer Rupiah).
class LocalReceiptParser implements ReceiptUnderstandingService {
  const LocalReceiptParser();

  static const List<String> _ignoredHeaderPrefixes = [
    'SELAMAT DATANG',
    'TERIMA KASIH',
    'STRUK',
    'INVOICE',
    'NOTA',
    'BILL',
    'RECEIPT',
    'SALINAN',
    'CUSTOMER COPY',
    'MERCHANT COPY',
    'JL.',
    'JALAN',
    'TELP',
    'NPWP',
    'NO.',
    'KASIR',
  ];

  static const Map<String, ({String merchantName, String categoryId})> _knownMerchants = {
    'INDOMARET': (merchantName: 'Indomaret', categoryId: 'cat-exp-shopping'),
    'INDOMARCO': (merchantName: 'Indomaret', categoryId: 'cat-exp-shopping'),
    'ALFAMART': (merchantName: 'Alfamart', categoryId: 'cat-exp-shopping'),
    'SUMBER ALFARIA': (merchantName: 'Alfamart', categoryId: 'cat-exp-shopping'),
    'ALFAMIDI': (merchantName: 'Alfamidi', categoryId: 'cat-exp-shopping'),
    'MIDI UTAMA': (merchantName: 'Alfamidi', categoryId: 'cat-exp-shopping'),
    'SUPER INDO': (merchantName: 'Super Indo', categoryId: 'cat-exp-shopping'),
    'SUPERINDO': (merchantName: 'Super Indo', categoryId: 'cat-exp-shopping'),
    'HYPERMART': (merchantName: 'Hypermart', categoryId: 'cat-exp-shopping'),
    'STARBUCKS': (merchantName: 'Starbucks', categoryId: 'cat-exp-food'),
    'MCDONALD': (merchantName: 'McDonald\'s', categoryId: 'cat-exp-food'),
    'MCD ': (merchantName: 'McDonald\'s', categoryId: 'cat-exp-food'),
    'KFC': (merchantName: 'KFC', categoryId: 'cat-exp-food'),
    'HOKBEN': (merchantName: 'HokBen', categoryId: 'cat-exp-food'),
    'HOKA HOKA BENTO': (merchantName: 'HokBen', categoryId: 'cat-exp-food'),
    'KENANGAN': (merchantName: 'Kopi Kenangan', categoryId: 'cat-exp-food'),
    'JANJI JIWA': (merchantName: 'Kopi Janji Jiwa', categoryId: 'cat-exp-food'),
    'FORE COFFEE': (merchantName: 'Fore Coffee', categoryId: 'cat-exp-food'),
    'PERTAMINA': (merchantName: 'Pertamina SPBU', categoryId: 'cat-exp-transport'),
    'SPBU': (merchantName: 'SPBU Pertamina', categoryId: 'cat-exp-transport'),
    'SHELL': (merchantName: 'Shell SPBU', categoryId: 'cat-exp-transport'),
    'GRAMEDIA': (merchantName: 'Gramedia', categoryId: 'cat-exp-shopping'),
    'GUARDIAN': (merchantName: 'Guardian', categoryId: 'cat-exp-health'),
    'WATSON': (merchantName: 'Watsons', categoryId: 'cat-exp-health'),
    'KIMIA FARMA': (merchantName: 'Kimia Farma', categoryId: 'cat-exp-health'),
    'CINEMA XXI': (merchantName: 'Cinema XXI', categoryId: 'cat-exp-entertainment'),
    'CGV': (merchantName: 'CGV Cinemas', categoryId: 'cat-exp-entertainment'),
  };

  @override
  Future<ReceiptDraft> parse(
    OcrResult result, {
    String? imagePath,
    Uint8List? imageBytes,
  }) async {
    final lines = result.lines.map((l) => l.text.trim()).where((t) => t.isNotEmpty).toList();

    final effectiveImagePath = imagePath ?? result.imagePath;

    if (lines.isEmpty) {
      return ReceiptDraft(
        rawText: result.rawText,
        imagePath: effectiveImagePath,
        imageBytes: imageBytes,
        isMerchantCertain: false,
        isDateCertain: false,
        isTotalCertain: false,
      );
    }

    // 1. Ekstraksi Merchant & Rekomendasi Kategori
    final merchantResult = _extractMerchant(lines);

    // 2. Ekstraksi Tanggal & Waktu
    final dateResult = _extractDateTime(lines);

    // 3. Ekstraksi Finansial: Subtotal, Pajak, Diskon, Service & Grand Total
    final financialResult = _extractFinancials(lines);

    // 4. Ekstraksi Line Items
    final items = _extractItems(lines);

    return ReceiptDraft(
      merchant: merchantResult.merchant,
      occurredAt: dateResult.dateTime,
      totalAmount: financialResult.total,
      subtotal: financialResult.subtotal,
      taxAmount: financialResult.tax,
      serviceCharge: financialResult.service,
      discountAmount: financialResult.discount,
      items: items,
      isMerchantCertain: merchantResult.isCertain,
      isDateCertain: dateResult.isCertain,
      isTotalCertain: financialResult.isTotalCertain,
      suggestedCategoryId: merchantResult.suggestedCategoryId,
      imagePath: effectiveImagePath,
      imageBytes: imageBytes,
      rawText: result.rawText,
    );
  }

  /// Ekstraksi Nama Toko / Merchant
  ({String? merchant, String? suggestedCategoryId, bool isCertain}) _extractMerchant(List<String> lines) {
    // Periksa 6 baris pertama
    final headerLines = lines.take(6).toList();

    // 1. Cocokkan dengan daftar merchant populer
    for (final line in headerLines) {
      final upper = line.toUpperCase();
      for (final entry in _knownMerchants.entries) {
        if (upper.contains(entry.key)) {
          return (
            merchant: entry.value.merchantName,
            suggestedCategoryId: entry.value.categoryId,
            isCertain: true,
          );
        }
      }
    }

    // 2. Ambil baris pertama yang bukan noise / alamat / kontak
    for (final line in headerLines) {
      final upper = line.toUpperCase();
      bool isIgnored = false;
      for (final prefix in _ignoredHeaderPrefixes) {
        if (upper.startsWith(prefix) || upper.contains('NPWP') || upper.contains('TELP')) {
          isIgnored = true;
          break;
        }
      }
      if (!isIgnored && line.length >= 3 && !RegExp(r'^[0-9\W]+$').hasMatch(line)) {
        // Bersihkan karakter aneh
        final cleaned = line.replaceAll(RegExp(r'[^\w\s\.\&\-]'), '').trim();
        if (cleaned.isNotEmpty) {
          String? categoryId;
          final upper = cleaned.toUpperCase();
          if (upper.contains('STORE') || upper.contains('MART') || upper.contains('SHOP') || upper.contains('TOKO') || upper.contains('MARKET')) {
            categoryId = 'cat-exp-shopping';
          } else if (upper.contains('CAFE') || upper.contains('COFFEE') || upper.contains('KOPI') || upper.contains('RESTO') || upper.contains('WARUNG') || upper.contains('BAKERY')) {
            categoryId = 'cat-exp-food';
          } else if (upper.contains('SPBU') || upper.contains('BBM') || upper.contains('PARKIR')) {
            categoryId = 'cat-exp-transport';
          } else if (upper.contains('APOTEK') || upper.contains('FARMA') || upper.contains('KLINIK') || upper.contains('OPTIK')) {
            categoryId = 'cat-exp-health';
          }

          return (
            merchant: cleaned,
            suggestedCategoryId: categoryId,
            isCertain: false, // Toko tidak dikenal di katalog, tandai butuh review
          );
        }
      }
    }

    return (merchant: null, suggestedCategoryId: null, isCertain: false);
  }

  /// Ekstraksi Tanggal & Waktu
  ({DateTime? dateTime, bool isCertain}) _extractDateTime(List<String> lines) {
    // 1. Pola ISO / Tahun 4 Digit di Depan: YYYY-MM-DD, YYYY/MM/DD, YYYY.MM.DD
    final isoDateRegExp = RegExp(
      r'\b(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})\b',
    );
    // 2. Pola tanggal teks: 17 Nov 2026, 17 November 2026, 17-Nov-2026
    final dateTextRegExp = RegExp(
      r'\b(\d{1,2})[\s\-]+(Jan|Feb|Mar|Apr|Mei|Jun|Jul|Agu|Ags|Sep|Okt|Nov|Des|January|February|March|April|May|June|July|August|September|October|November|December)[\s\-]+(\d{2,4})\b',
      caseSensitive: false,
    );
    // 3. Pola tanggal DMY dengan 4-digit tahun: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
    final dmy4RegExp = RegExp(
      r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})\b',
    );
    // 4. Pola tanggal DMY dengan 2-digit tahun: DD/MM/YY, DD-MM-YY, DD.MM.YY
    final dmy2RegExp = RegExp(
      r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2})\b',
    );
    // Pola waktu: HH:mm atau HH:mm:ss
    final timeRegExp = RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?\b');

    int? foundYear;
    int? foundMonth;
    int? foundDay;
    int? foundHour;
    int? foundMinute;
    int? foundSecond;

    final currentYear = DateTime.now().year;

    for (final line in lines) {
      // 1. Cari Waktu pada baris jika belum ditemukan
      if (foundHour == null) {
        final timeMatch = timeRegExp.firstMatch(line);
        if (timeMatch != null) {
          foundHour = int.tryParse(timeMatch.group(1)!);
          foundMinute = int.tryParse(timeMatch.group(2)!);
          if (timeMatch.group(3) != null) {
            foundSecond = int.tryParse(timeMatch.group(3)!);
          }
        }
      }

      // 2. Cari Tanggal pada baris jika belum ditemukan
      if (foundDay == null) {
        // Cek format ISO (YYYY-MM-DD / YYYY/MM/DD) terlebih dahulu agar 4 digit tahun tidak terpangkas
        final isoMatch = isoDateRegExp.firstMatch(line);
        if (isoMatch != null) {
          final year = int.parse(isoMatch.group(1)!);
          final month = int.parse(isoMatch.group(2)!);
          final day = int.parse(isoMatch.group(3)!);

          if (year >= 2000 && year <= currentYear + 1 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            foundYear = year;
            foundMonth = month;
            foundDay = day;
            continue;
          }
        }

        // Cek format teks (17 Nov 2026 / 17 November 2026)
        final textMatch = dateTextRegExp.firstMatch(line);
        if (textMatch != null) {
          final day = int.parse(textMatch.group(1)!);
          final monthStr = textMatch.group(2)!.toLowerCase();
          int year = int.parse(textMatch.group(3)!);
          if (year < 100) year += 2000;

          final m = _parseIndonesianMonth(monthStr);
          if (m != null && year >= 2000 && year <= currentYear + 1 && day >= 1 && day <= 31) {
            foundDay = day;
            foundMonth = m;
            foundYear = year;
            continue;
          }
        }

        // Cek format DMY dengan tahun 4-digit (DD/MM/YYYY)
        final dmy4Match = dmy4RegExp.firstMatch(line);
        if (dmy4Match != null) {
          final p1 = int.parse(dmy4Match.group(1)!);
          final p2 = int.parse(dmy4Match.group(2)!);
          final p3 = int.parse(dmy4Match.group(3)!);

          if (p3 >= 2000 && p3 <= currentYear + 1) {
            if (p1 <= 31 && p2 <= 12) {
              foundDay = p1;
              foundMonth = p2;
              foundYear = p3;
              continue;
            } else if (p1 <= 12 && p2 <= 31) {
              foundMonth = p1;
              foundDay = p2;
              foundYear = p3;
              continue;
            }
          }
        }

        // Cek format DMY dengan tahun 2-digit (DD/MM/YY)
        final dmy2Match = dmy2RegExp.firstMatch(line);
        if (dmy2Match != null) {
          final p1 = int.parse(dmy2Match.group(1)!);
          final p2 = int.parse(dmy2Match.group(2)!);
          int p3 = int.parse(dmy2Match.group(3)!);
          if (p3 < 100) p3 += 2000;

          if (p3 >= 2000 && p3 <= currentYear + 1) {
            if (p1 <= 31 && p2 <= 12) {
              foundDay = p1;
              foundMonth = p2;
              foundYear = p3;
              continue;
            } else if (p1 <= 12 && p2 <= 31) {
              foundMonth = p1;
              foundDay = p2;
              foundYear = p3;
              continue;
            }
          }
        }
      }
    }

    if (foundDay != null && foundMonth != null && foundYear != null) {
      try {
        final parsed = DateTime(
          foundYear,
          foundMonth,
          foundDay,
          foundHour ?? 12,
          foundMinute ?? 0,
          foundSecond ?? 0,
        );
        return (
          dateTime: parsed,
          isCertain: true,
        );
      } catch (_) {}
    }

    return (dateTime: DateTime.now(), isCertain: false);
  }

  int? _parseIndonesianMonth(String str) {
    if (str.startsWith('jan')) return 1;
    if (str.startsWith('feb')) return 2;
    if (str.startsWith('mar')) return 3;
    if (str.startsWith('apr')) return 4;
    if (str.startsWith('mei') || str.startsWith('may')) return 5;
    if (str.startsWith('jun')) return 6;
    if (str.startsWith('jul')) return 7;
    if (str.startsWith('agu') || str.startsWith('ags') || str.startsWith('aug')) return 8;
    if (str.startsWith('sep')) return 9;
    if (str.startsWith('okt') || str.startsWith('oct')) return 10;
    if (str.startsWith('nov')) return 11;
    if (str.startsWith('des') || str.startsWith('dec')) return 12;
    return null;
  }

  /// Ekstraksi Grand Total, Subtotal, Pajak, Diskon, dan Service
  ({int? total, int? subtotal, int? tax, int? service, int? discount, bool isTotalCertain})
      _extractFinancials(List<String> lines) {
    int? detectedTotal;
    int? detectedSubtotal;
    int? detectedTax;
    int? detectedService;
    int? detectedDiscount;
    bool isTotalCertain = false;

    // Kata kunci penolak pembayaran (metode bayar, kembalian, dsb)
    final paymentFilter = RegExp(
      r'\b(TUNAI|CASH|KEMBALI|KEMBALIAN|CHANGE|BAYAR|DEBIT|KREDIT|QRIS|BCA|MANDIRI|BRI|BNI|OVO|GOPAY|DANA|SHOPEEPAY)\b',
      caseSensitive: false,
    );

    // Kata kunci Total
    final totalRegExp = RegExp(
      r'\b(GRAND\s*TOTAL|TOTAL\s*BELANJA|TOTAL\s*AKHIR|TOTAL\s*BAYAR|TAGIHAN|TOTAL)\b',
      caseSensitive: false,
    );

    final subtotalRegExp = RegExp(r'\b(SUBTOTAL|SUB\s*TOTAL|SUB-TOTAL)\b', caseSensitive: false);
    final taxRegExp = RegExp(r'\b(PPN|PB1|PAJAK|TAX)\b', caseSensitive: false);
    final serviceRegExp = RegExp(r'\b(SERVICE|SERVICE\s*CHARGE|LAYANAN)\b', caseSensitive: false);
    final discountRegExp = RegExp(r'\b(DISKON|DISCOUNT|POTONGAN|HEMAT)\b', caseSensitive: false);

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      final isExplicitTotal = totalRegExp.hasMatch(line);
      final isPaymentLine = !isExplicitTotal && paymentFilter.hasMatch(line);

      // Cek Diskon
      if (discountRegExp.hasMatch(line)) {
        final amount = _parseAmountFromLine(line) ?? (i + 1 < lines.length ? _parseAmountFromLine(lines[i + 1]) : null);
        if (amount != null) detectedDiscount = amount;
      }

      // Cek Pajak
      if (taxRegExp.hasMatch(line) && !line.toUpperCase().contains('NPWP')) {
        final amount = _parseAmountFromLine(line) ?? (i + 1 < lines.length ? _parseAmountFromLine(lines[i + 1]) : null);
        if (amount != null) detectedTax = amount;
      }

      // Cek Service
      if (serviceRegExp.hasMatch(line)) {
        final amount = _parseAmountFromLine(line) ?? (i + 1 < lines.length ? _parseAmountFromLine(lines[i + 1]) : null);
        if (amount != null) detectedService = amount;
      }

      // Cek Subtotal
      if (subtotalRegExp.hasMatch(line)) {
        final amount = _parseAmountFromLine(line) ?? (i + 1 < lines.length ? _parseAmountFromLine(lines[i + 1]) : null);
        if (amount != null) detectedSubtotal = amount;
      }

      // Cek Total
      if (!isPaymentLine && isExplicitTotal) {
        final match = totalRegExp.firstMatch(line)!;
        final textAfterTotal = line.substring(match.end);
        final amountAfter = _parseAmountFromLine(textAfterTotal);
        final amount = amountAfter ?? _parseAmountFromLine(line) ?? (i + 1 < lines.length ? _parseAmountFromLine(lines[i + 1]) : null);
        if (amount != null && amount > 0) {
          detectedTotal = amount;
          isTotalCertain = true;
        }
      }
    }

    // Jika total belum ditemukan dari keyword eksplisit, cari angka terbesar sebelum baris pembayaran
    if (detectedTotal == null || detectedTotal == 0) {
      int maxCandidate = 0;
      for (final line in lines) {
        if (paymentFilter.hasMatch(line)) continue;
        final amount = _parseAmountFromLine(line);
        if (amount != null && amount > maxCandidate) {
          maxCandidate = amount;
        }
      }
      if (maxCandidate > 0) {
        detectedTotal = maxCandidate;
        isTotalCertain = false; // Ambigu, wajib verifikasi manual
      }
    }

    return (
      total: detectedTotal,
      subtotal: detectedSubtotal,
      tax: detectedTax,
      service: detectedService,
      discount: detectedDiscount,
      isTotalCertain: isTotalCertain && (detectedTotal != null && detectedTotal > 0),
    );
  }

  /// Ekstraksi angka Rupiah integer dari string baris
  int? _parseAmountFromLine(String line) {
    // Ambil pola angka Rupiah: "45.000", "45,000", "45000", "45.000,00"
    final matches = RegExp(r'(?:Rp\.?\s*)?([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{2})?|[0-9]{3,})').allMatches(line);

    int? candidate;
    for (final m in matches) {
      final str = m.group(1);
      if (str == null) continue;

      // Bersihkan pemisah
      final clean = _normalizeRupiahString(str);
      final val = int.tryParse(clean);
      if (val != null && val > 0) {
        // Ambil match paling kanan pada baris (biasanya kolom harga/total)
        candidate = val;
      }
    }
    return candidate;
  }

  String _normalizeRupiahString(String input) {
    String s = input.trim();
    // Hilangkan desimal sen jika berakhiran ,00 atau .00
    if (s.endsWith(',00') || s.endsWith('.00')) {
      s = s.substring(0, s.length - 3);
    }
    // Hapus semua karakter non-digit
    return s.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Ekstraksi item belanja
  List<ReceiptItemDraft> _extractItems(List<String> lines) {
    final items = <ReceiptItemDraft>[];

    // Pola 1: [Qty] x [Harga Satuan] ... [Total]
    // Contoh: "2 x 15.000  30.000" atau "INDOMIE GORENG  2 x 3.500  7.000"
    final itemWithQtyRegExp = RegExp(
      r'(\d+)\s*[xX]\s*([0-9.,]+)\s+([0-9.,]+)',
    );

    // Pola 2: Format tabel kolom POS standar: [Qty]  [Harga Satuan]  [Total]
    // Contoh: "1             7,700             7,700"
    final columnItemRegExp = RegExp(
      r'^\s*(\d{1,3})\s+([0-9.,]{3,})\s+([0-9.,]{3,})\s*$',
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Cek Pola 1 (dengan 'x')
      final match = itemWithQtyRegExp.firstMatch(line);
      if (match != null) {
        final qty = int.tryParse(match.group(1)!) ?? 1;
        final unitPrice = int.tryParse(_normalizeRupiahString(match.group(2)!)) ?? 0;
        final totalPrice = int.tryParse(_normalizeRupiahString(match.group(3)!)) ?? (qty * unitPrice);

        String name = 'Item';
        final textBefore = line.substring(0, match.start).trim();
        if (textBefore.length >= 3) {
          name = textBefore;
        } else if (i > 0) {
          final prevLine = lines[i - 1].trim();
          if (!prevLine.contains(':') && prevLine.length >= 3 && !RegExp(r'^\d+$').hasMatch(prevLine)) {
            name = prevLine;
          }
        }

        if (totalPrice > 0) {
          items.add(ReceiptItemDraft(
            name: name,
            quantity: qty,
            unitPrice: unitPrice > 0 ? unitPrice : (totalPrice ~/ qty),
            totalPrice: totalPrice,
          ));
        }
        continue;
      }

      // Cek Pola 2 (kolom tanpa 'x')
      final colMatch = columnItemRegExp.firstMatch(line);
      if (colMatch != null) {
        final qty = int.tryParse(colMatch.group(1)!) ?? 1;
        final unitPrice = int.tryParse(_normalizeRupiahString(colMatch.group(2)!)) ?? 0;
        final totalPrice = int.tryParse(_normalizeRupiahString(colMatch.group(3)!)) ?? (qty * unitPrice);

        String name = 'Item';
        if (i > 0) {
          final prevLine = lines[i - 1].trim();
          if (!prevLine.contains(':') && prevLine.length >= 3 && !RegExp(r'^\d+$').hasMatch(prevLine)) {
            name = prevLine;
          }
        }

        if (totalPrice > 0) {
          items.add(ReceiptItemDraft(
            name: name,
            quantity: qty,
            unitPrice: unitPrice > 0 ? unitPrice : (totalPrice ~/ qty),
            totalPrice: totalPrice,
          ));
        }
      }
    }

    return items;
  }
}
