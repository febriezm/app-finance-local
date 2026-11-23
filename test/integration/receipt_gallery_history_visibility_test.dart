import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/app/app_providers.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/core/formatting/date_formatter.dart';
import 'package:myfinance/features/wallets/data/repositories/wallet_repository_impl.dart';
import 'package:myfinance/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:myfinance/features/receipt_scanner/data/services/local_receipt_parser.dart';
import 'package:myfinance/features/receipt_scanner/data/services/attachment_storage_service.dart';
import 'package:myfinance/features/receipt_scanner/domain/usecases/confirm_receipt_transaction_usecase.dart';
import 'package:myfinance/features/receipt_scanner/domain/entities/ocr_result.dart';
import 'package:myfinance/features/wallets/domain/entities/wallet.dart';
import 'package:myfinance/features/transactions/domain/entities/transaction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletRepositoryImpl walletRepo;
  late TransactionRepositoryImpl transactionRepo;
  late LocalReceiptParser parser;
  late ConfirmReceiptTransactionUseCase confirmUseCase;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    walletRepo = WalletRepositoryImpl(db.walletsDao, db.transactionsDao);
    transactionRepo = TransactionRepositoryImpl(db.transactionsDao, db.walletsDao, db.categoriesDao);
    parser = const LocalReceiptParser();
    final attachmentService = AttachmentStorageService(db.transactionsDao);
    confirmUseCase = ConfirmReceiptTransactionUseCase(transactionRepo, attachmentService);

    final now = DateTime.now().toUtc().toIso8601String();
    await walletRepo.createWallet(
      Wallet(
        id: 'w-cash',
        name: 'Dompet Tunai',
        type: WalletType.cash,
        openingBalance: 500000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Gallery Receipt Scan & Transaction History Visibility Integration Tests', () {
    test('Gallery receipt with ISO date 2026-11-17 appears in both Home and Riwayat Transaksi', () async {
      const galleryReceiptOcr = '''
MINIMARKET ALFA
Tanggal: 2026-11-17 11:30:00
Kasir: 01

TEH BOTOL SOSRO 450ML
2 x 4,000       8,000

TOTAL:          8,000
TUNAI:         10,000
KEMBALI:        2,000
''';

      // 1. Ekstraksi OCR dari gambar galeri
      final ocrResult = OcrResult.fromString(galleryReceiptOcr);
      final draft = await parser.parse(ocrResult);

      expect(draft.occurredAt, isNotNull);
      expect(draft.occurredAt!.year, equals(2026));
      expect(draft.occurredAt!.month, equals(11));
      expect(draft.occurredAt!.day, equals(17));
      expect(draft.totalAmount, equals(8000));

      // 2. Konfirmasi & Simpan Transaksi
      final txId = await confirmUseCase.execute(
        draft: draft,
        walletId: 'w-cash',
        categoryId: 'cat-exp-food',
        amount: draft.totalAmount!,
        occurredAt: draft.occurredAt!,
        merchant: draft.merchant,
      );

      expect(txId, isNotEmpty);

      // 3. Verifikasi Data Source Home (recentTransactionsStreamProvider)
      final recentList = await transactionRepo.getRecentTransactions(limit: 20);
      expect(recentList.any((t) => t.transaction.id == txId), isTrue);

      final savedItem = recentList.firstWhere((t) => t.transaction.id == txId);
      expect(savedItem.transaction.merchant, equalsIgnoringCase('Minimarket Alfa'));
      expect(savedItem.transaction.amount, equals(8000));

      // 4. Verifikasi Data Source Riwayat Transaksi (Filter Bulan Berjalan: 2026-11)
      final currentMonthKey = AppDateFormatter.toMonthKey(DateTime(2026, 11, 1));
      final txLocalDt = AppDateFormatter.parseUtcToLocal(savedItem.transaction.occurredAt);
      final txMonthKey = AppDateFormatter.toMonthKey(txLocalDt);

      // Transaksi WAJIB cocok dengan filter bulan riwayat transaksi
      expect(txMonthKey, equals(currentMonthKey));

      final historyFiltered = recentList.where((item) {
        final dt = AppDateFormatter.parseUtcToLocal(item.transaction.occurredAt);
        return AppDateFormatter.toMonthKey(dt) == currentMonthKey &&
            item.transaction.status == TransactionStatus.confirmed;
      }).toList();

      expect(historyFiltered.any((t) => t.transaction.id == txId), isTrue);
    });

    test('Gallery receipt from previous month (October 2026) syncs selectedTransactionMonthProvider and is visible', () async {
      const pastGalleryReceiptOcr = '''
TOKO BUKU GRAMEDIA
Tanggal: 2026-10-15 15:20:00

BUKU CATATAN SPIRAL
1 x 35,000      35,000

TOTAL:          35,000
''';

      final ocrResult = OcrResult.fromString(pastGalleryReceiptOcr);
      final draft = await parser.parse(ocrResult);

      expect(draft.occurredAt, isNotNull);
      expect(draft.occurredAt!.year, equals(2026));
      expect(draft.occurredAt!.month, equals(10));
      expect(draft.occurredAt!.day, equals(15));

      final txId = await confirmUseCase.execute(
        draft: draft,
        walletId: 'w-cash',
        categoryId: 'cat-exp-shopping',
        amount: draft.totalAmount!,
        occurredAt: draft.occurredAt!,
        merchant: draft.merchant,
      );

      // ProviderContainer untuk verifikasi state management Riverpod
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(transactionRepo),
        ],
      );

      // Sinkronisasi bulan seperti di ReceiptReviewScreen
      container.read(selectedTransactionMonthProvider.notifier).state =
          DateTime(draft.occurredAt!.year, draft.occurredAt!.month, 1);

      final activeMonth = container.read(selectedTransactionMonthProvider);
      expect(activeMonth.year, equals(2026));
      expect(activeMonth.month, equals(10));

      // Verifikasi filter riwayat di bulan Oktober 2026
      final targetMonthKey = AppDateFormatter.toMonthKey(activeMonth);
      expect(targetMonthKey, equals('2026-10'));

      final allRecent = await transactionRepo.getRecentTransactions(limit: 50);
      final octFiltered = allRecent.where((item) {
        final dt = AppDateFormatter.parseUtcToLocal(item.transaction.occurredAt);
        return AppDateFormatter.toMonthKey(dt) == targetMonthKey &&
            item.transaction.status == TransactionStatus.confirmed;
      }).toList();

      expect(octFiltered.any((t) => t.transaction.id == txId), isTrue);
      container.dispose();
    });

    test('Receipt transaction can be edited and voided like a normal transaction', () async {
      const receiptOcr = '''
CAFE KOPI
Tanggal: 2026-11-20 09:00:00
KOPI HITAM: 18,000
TOTAL: 18,000
''';
      final draft = await parser.parse(OcrResult.fromString(receiptOcr));
      final txId = await confirmUseCase.execute(
        draft: draft,
        walletId: 'w-cash',
        categoryId: 'cat-exp-food',
        amount: draft.totalAmount!,
        occurredAt: draft.occurredAt!,
        merchant: draft.merchant,
      );

      // 1. Verifikasi saldo berkurang
      var balance = await walletRepo.calculateWalletBalance('w-cash');
      expect(balance, equals(500000 - 18000));

      // 2. Void / Batalkan Transaksi
      await transactionRepo.voidTransaction(txId);
      final voidedTx = await transactionRepo.getTransactionById(txId);
      expect(voidedTx!.status, equals(TransactionStatus.voided));

      // 3. Verifikasi saldo pulih setelah void
      balance = await walletRepo.calculateWalletBalance('w-cash');
      expect(balance, equals(500000));
    });
  });
}
