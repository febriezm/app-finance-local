import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/core/formatting/date_formatter.dart';
import 'package:myfinance/features/wallets/data/repositories/wallet_repository_impl.dart';
import 'package:myfinance/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:myfinance/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:myfinance/features/receipt_scanner/data/services/local_receipt_parser.dart';
import 'package:myfinance/features/receipt_scanner/data/services/receipt_ocr_service_impl.dart';
import 'package:myfinance/features/receipt_scanner/data/services/attachment_storage_service.dart';
import 'package:myfinance/features/receipt_scanner/domain/usecases/scan_receipt_usecase.dart';
import 'package:myfinance/features/receipt_scanner/domain/usecases/confirm_receipt_transaction_usecase.dart';
import 'package:myfinance/features/wallets/domain/entities/wallet.dart';
import 'package:myfinance/features/transactions/domain/entities/transaction.dart';
import 'package:myfinance/features/budgets/domain/entities/budget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletRepositoryImpl walletRepo;
  late TransactionRepositoryImpl transactionRepo;
  late BudgetRepositoryImpl budgetRepo;
  late ScanReceiptUseCase scanUseCase;
  late ConfirmReceiptTransactionUseCase confirmUseCase;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    walletRepo = WalletRepositoryImpl(db.walletsDao, db.transactionsDao);
    transactionRepo = TransactionRepositoryImpl(db.transactionsDao, db.walletsDao, db.categoriesDao);
    budgetRepo = BudgetRepositoryImpl(db.budgetsDao, db.transactionsDao, db.categoriesDao);

    const ocrService = ReceiptOcrServiceImpl();
    const parser = LocalReceiptParser();
    final attachmentService = AttachmentStorageService(db.transactionsDao);

    scanUseCase = ScanReceiptUseCase(ocrService, parser);
    confirmUseCase = ConfirmReceiptTransactionUseCase(transactionRepo, attachmentService);

    final now = DateTime.now().toUtc().toIso8601String();

    // 1. Setup Wallet: Bank BCA Saldo Rp 1.000.000
    await walletRepo.createWallet(
      Wallet(
        id: 'w-bca',
        name: 'Bank BCA',
        type: WalletType.bank,
        openingBalance: 1000000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    // 2. Setup Monthly Budget: Rp 2.000.000
    final currentMonthKey = AppDateFormatter.toMonthKey(DateTime.now());
    await budgetRepo.saveBudget(
      budget: Budget(
        id: 'b-month',
        monthKey: currentMonthKey,
        totalLimit: 2000000,
        createdAt: now,
        updatedAt: now,
      ),
      categoryLimits: [
        const BudgetCategoryLimit(
          id: 'bcl-shop',
          budgetId: 'b-month',
          categoryId: 'cat-exp-shopping',
          limitAmount: 1000000,
        ),
      ],
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3 Integration Test - Receipt Scanner Lifecycle', () {
    test('Scan Indomaret receipt -> Extract draft -> Review & Confirm -> Updates Ledger, Budget, & Attachment', () async {
      final currentMonthKey = AppDateFormatter.toMonthKey(DateTime.now());

      // 1. Jalankan Scan UseCase dengan sampel struk Indomaret
      final draft = await scanUseCase.execute(imagePath: 'sample:indomaret');

      expect(draft.merchant, equals('Indomaret'));
      expect(draft.totalAmount, equals(47730));
      expect(draft.subtotal, equals(43000));
      expect(draft.taxAmount, equals(4730));
      expect(draft.suggestedCategoryId, equals('cat-exp-shopping'));
      expect(draft.isTotalCertain, isTrue);
      expect(draft.items.length, greaterThanOrEqualTo(3));

      // 2. Konfirmasi Transaksi (Review Flow: Pengguna memilih wallet & kategori)
      final txId = await confirmUseCase.execute(
        draft: draft,
        walletId: 'w-bca',
        categoryId: draft.suggestedCategoryId ?? 'cat-exp-shopping',
        amount: draft.totalAmount!,
        occurredAt: draft.occurredAt ?? DateTime.now(),
        merchant: draft.merchant,
        notes: 'Belanja mingguan dari OCR',
      );

      expect(txId, isNotEmpty);

      // 3. Verifikasi Transaksi di Database
      final savedTx = await transactionRepo.getTransactionById(txId);
      expect(savedTx, isNotNull);
      expect(savedTx!.amount, equals(47730));
      expect(savedTx.type, equals(TransactionType.expense));
      expect(savedTx.source, equals(TransactionSource.receiptScan));
      expect(savedTx.merchant, equals('Indomaret'));
      expect(savedTx.walletId, equals('w-bca'));
      expect(savedTx.categoryId, equals('cat-exp-shopping'));

      // 4. Verifikasi Attachment tercatat di database
      final attachments = await db.transactionsDao.getAttachmentsForTransaction(txId);
      expect(attachments.length, equals(1));
      expect(attachments.first.transactionId, equals(txId));
      expect(attachments.first.localPath, contains('receipts/'));

      // 5. Verifikasi Saldo Dompet Berkurang
      // 1.000.000 - 47.730 = 952.270
      final bcaBalance = await walletRepo.calculateWalletBalance('w-bca');
      expect(bcaBalance, equals(952270));

      // 6. Verifikasi Progress Budget Terupdate
      final progress = await budgetRepo.getBudgetProgress(currentMonthKey);
      expect(progress.totalSpent, equals(47730));
      expect(progress.remaining, equals(2000000 - 47730));

      final shopProgress = progress.categoryProgresses.firstWhere((c) => c.category.id == 'cat-exp-shopping');
      expect(shopProgress.spentAmount, equals(47730));
      expect(shopProgress.remainingAmount, equals(1000000 - 47730));

      // 7. Verifikasi Laporan Bulanan Pengeluaran Terupdate
      final now = DateTime.now();
      final monthlyExpense = await transactionRepo.getMonthlyExpense(now.year, now.month);
      expect(monthlyExpense, equals(47730));
    });

    test('Items in receipt draft are automatically populated into transaction notes and description', () async {
      final draft = await scanUseCase.execute(imagePath: 'sample:indomaret');
      expect(draft.items.isNotEmpty, isTrue);

      final txId = await confirmUseCase.execute(
        draft: draft,
        walletId: 'w-bca',
        categoryId: 'cat-exp-shopping',
        amount: draft.totalAmount!,
        occurredAt: DateTime.now(),
        merchant: draft.merchant,
      );

      final savedTx = await transactionRepo.getTransactionById(txId);
      expect(savedTx, isNotNull);
      expect(savedTx!.notes, contains('INDOMILK'));
      expect(savedTx.description, contains('INDOMILK'));
    });
  });
}
