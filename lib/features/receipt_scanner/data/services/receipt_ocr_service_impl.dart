import 'dart:typed_data';
import '../../domain/entities/ocr_result.dart';
import '../../domain/repositories/receipt_ocr_service.dart';
import 'ocr_runner.dart';

/// Implementasi layanan OCR on-device sesuai Blueprint Section 4.5.
/// Berjalan sepenuhnya di perangkat (on-device) tanpa koneksi internet.
class ReceiptOcrServiceImpl implements ReceiptOcrService {
  const ReceiptOcrServiceImpl();

  @override
  Future<OcrResult> recognize(String imagePath, [Uint8List? imageBytes]) async {
    // 1. Cek apakah ini sample receipt identifier
    if (imagePath.startsWith('sample:')) {
      final sampleKey = imagePath.replaceFirst('sample:', '');
      final text = _sampleReceipts[sampleKey] ?? _sampleReceipts['indomaret']!;
      return OcrResult.fromString(text, imagePath: imagePath);
    }

    // 2. Jalankan OCR On-Device untuk gambar pengguna (kamera / galeri)
    final recognizedText = await runOcr(imagePath, imageBytes);

    if (recognizedText.trim().isEmpty) {
      // Tidak ada teks terdeteksi atau gambar bukan struk belanja.
      // Mengembalikan OcrResult kosong sehingga parser menandai perlu input manual
      // sesuai aturan Blueprint Section 4.5 & 14 #9.
      return OcrResult(
        rawText: '',
        lines: const [],
        imagePath: imagePath,
      );
    }

    return OcrResult.fromString(
      recognizedText,
      imagePath: imagePath,
    );
  }

  /// Koleksi sampel struk belanja riil Indonesia untuk pengujian akurat & cepat
  static const Map<String, String> _sampleReceipts = {
    'indomaret': '''
PT. INDOMARCO PRISMATAMA
INDOMARET KEMANG RAYA
JL. KEMANG RAYA NO. 12, JAKARTA SELATAN
NPWP: 01.337.994.6-054.000
========================================
17/11/2026 14:25  KASIR: SITI
----------------------------------------
INDOMILK UHT 250ML
  1 x 7.500      7.500
ROTI TAWAR KUPAS
  1 x 16.000    16.000
AQUA AIR MINERAL 600ML
  2 x 3.500      7.000
CHITATO SAPI PANGGANG
  1 x 12.500    12.500
----------------------------------------
SUBTOTAL              43.000
PPN (11%)              4.730
TOTAL BELANJA         47.730
TUNAI                100.000
KEMBALIAN             52.270
========================================
TERIMA KASIH TELAH BERBELANJA
''',
    'restoran': '''
HOKBEN KEMANG
PT. EKA BOGAINTI
JL. BANGKA RAYA NO. 45
========================================
TANGGAL: 17 Nov 2026  19:15
MEJA: 08
----------------------------------------
SIMPLE SET TERIYAKI
  2 x 42.000     84.000
TOKYO BOWL CHICKEN
  1 x 38.000     38.000
OCHA DINGIN
  3 x 8.000      24.000
----------------------------------------
SUBTOTAL             146.000
PB1 (10%)             14.600
SERVICE CHARGE         7.300
GRAND TOTAL          167.900
BCA DEBIT            167.900
KEMBALI                    0
========================================
''',
    'spbu': '''
SPBU PERTAMINA 31.127.02
JL. MT HARYONO KAV 18
JAKARTA
========================================
TANGGAL: 17/11/2026 08:40:12
POMPA: 04
PRODUK: PERTAMAX
LITER: 20.00 L
HARGA/LITER: Rp 12.500
----------------------------------------
TOTAL               250.000
BAYAR QRIS          250.000
KEMBALIAN                 0
========================================
PASTI PAS! TERIMA KASIH
''',
    'kafe': '''
STARBUCKS COFFEE
SENAYAN CITY GROUND FLOOR
JAKARTA PUSAT
========================================
17-11-2026 16:30
ORDER: #104
----------------------------------------
CAFFE LATTE GRANDE
  1 x 55.000     55.000
CARAMEL MACCHIATO
  1 x 62.000     62.000
BUTTER CROISSANT
  1 x 32.000     32.000
----------------------------------------
SUBTOTAL             149.000
PAJAK (PB1)           14.900
TOTAL BAYAR          163.900
CASH                 200.000
CHANGE                36.100
========================================
''',
    'ambiguous': '''
TOKO SERBA ADA
JL. MAWAR NO. 1
========================================
17/11/2026
BARANG A
15.000
BARANG B
25.000
========================================
KASIR: BUDI
''',
  };

  static Map<String, String> get sampleReceipts => _sampleReceipts;
}
