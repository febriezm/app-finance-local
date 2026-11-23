import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:myfinance/app/app_providers.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/features/categories/domain/entities/category.dart';
import 'package:myfinance/features/wallets/domain/entities/wallet.dart';
import 'package:myfinance/features/receipt_scanner/domain/entities/receipt_draft.dart';
import 'package:myfinance/features/receipt_scanner/domain/entities/receipt_item_draft.dart';
import 'package:myfinance/features/receipt_scanner/presentation/screens/receipt_review_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase inMemoryDb;

  setUp(() async {
    inMemoryDb = AppDatabase(NativeDatabase.memory());
    final now = DateTime.now().toUtc().toIso8601String();

    // Setup dummy wallet
    await inMemoryDb.walletsDao.insertWallet(
      WalletsTableCompanion.insert(
        id: 'w-cash',
        name: 'Dompet Tunai',
        type: 'cash',
        openingBalance: 500000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() async {
    // Memory database is garbage collected
  });

  ReceiptDraft createSampleDraft({int totalAmount = 45000}) {
    // 1x1 transparent PNG bytes
    final dummyBytes = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);

    return ReceiptDraft(
      merchant: 'Indomaret Sudirman',
      occurredAt: DateTime(2026, 11, 20, 14, 30),
      totalAmount: totalAmount,
      subtotal: 41000,
      taxAmount: 4000,
      items: const [
        ReceiptItemDraft(name: 'Roti Cokelat', quantity: 2, unitPrice: 10000, totalPrice: 20000),
        ReceiptItemDraft(name: 'Kopi Susu', quantity: 1, unitPrice: 25000, totalPrice: 25000),
      ],
      suggestedCategoryId: 'cat-exp-food',
      imageBytes: dummyBytes,
      imagePath: '/tmp/receipt_sample.png',
      rawText: 'INDOMARET SUDIRMAN\nTOTAL: 45.000\nTERIMA KASIH',
      isMerchantCertain: true,
      isDateCertain: true,
      isTotalCertain: true,
    );
  }

  Widget buildTestWidget(ReceiptDraft draft, {Brightness brightness = Brightness.light}) {
    final now = DateTime.now().toUtc().toIso8601String();
    final sampleWallet = Wallet(
      id: 'w-cash',
      name: 'Dompet Tunai',
      type: WalletType.cash,
      openingBalance: 500000,
      openingDate: now,
      createdAt: now,
      updatedAt: now,
    );
    const sampleCategory = Category(
      id: 'cat-exp-food',
      name: 'Makanan & Minuman',
      type: CategoryType.expense,
      iconKey: 'restaurant',
      colorHex: '#FF9500',
    );

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(inMemoryDb),
        walletsWithBalanceStreamProvider.overrideWith(
          (ref) => Stream.value([WalletWithBalance(wallet: sampleWallet, currentBalance: 500000)]),
        ),
        activeCategoriesStreamProvider(CategoryType.expense).overrideWith(
          (ref) => Stream.value([sampleCategory]),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: ReceiptReviewScreen(draft: draft),
      ),
    );
  }

  group('ReceiptReviewScreen Widget & UI Redesign Tests', () {
    testWidgets('Renders all minimal sections: Preview, Total, Merchant, Date, Wallet, Category, Items', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final draft = createSampleDraft();
      await tester.pumpWidget(buildTestWidget(draft));
      await tester.pumpAndSettle();

      // 1. Header Minimalis
      expect(find.text('Review Struk'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // 2. Receipt Preview Capsule
      expect(find.text('Lampiran Struk'), findsOneWidget);
      expect(find.text('Perbesar'), findsOneWidget);

      // 3. Total Transaksi (Typography-First)
      expect(find.text('TOTAL TRANSAKSI'), findsOneWidget);
      expect(find.text('Rp 45.000'), findsOneWidget);

      // 4. Detail Transaksi (Grouped Flat List)
      expect(find.text('Merchant / Toko'), findsOneWidget);
      expect(find.text('Indomaret Sudirman'), findsOneWidget);
      expect(find.text('Tanggal & Waktu'), findsOneWidget);
      expect(find.text('Dompet Sumber'), findsOneWidget);
      expect(find.text('Kategori'), findsOneWidget);
      expect(find.text('Catatan'), findsOneWidget);

      // 5. Rincian Struk & Item (Collapsible)
      expect(find.text('Rincian Struk & Item'), findsOneWidget);
      // Buka accordion rincian item
      await tester.tap(find.text('Rincian Struk & Item'));
      await tester.pumpAndSettle();

      expect(find.text('Rincian Biaya Struk'), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Pajak (PPN/PB1)'), findsOneWidget);
      expect(find.text('Roti Cokelat'), findsOneWidget);
      expect(find.text('Kopi Susu'), findsOneWidget);

      // 6. Sticky Action Button
      expect(find.text('Konfirmasi & Simpan Transaksi'), findsOneWidget);
    });

    testWidgets('Tapping Receipt Preview opens fullscreen zoomable dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final draft = createSampleDraft();
      await tester.pumpWidget(buildTestWidget(draft));
      await tester.pumpAndSettle();

      // Tap preview button
      await tester.tap(find.text('Perbesar'));
      await tester.pumpAndSettle();

      // Verify fullscreen zoomable viewer is displayed
      expect(find.text('Pratinjau Struk'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Pratinjau Struk'), findsNothing);
    });

    testWidgets('Can edit merchant name, amount, and notes cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final draft = createSampleDraft();
      await tester.pumpWidget(buildTestWidget(draft));
      await tester.pumpAndSettle();

      // 1. Edit Merchant
      final merchantField = find.widgetWithText(TextField, 'Indomaret Sudirman');
      expect(merchantField, findsOneWidget);
      await tester.enterText(merchantField, 'Alfamart Gatsu');
      await tester.pumpAndSettle();
      expect(find.text('Alfamart Gatsu'), findsOneWidget);

      // 2. Edit Amount: change to 55000
      final amountField = find.widgetWithText(TextField, 'Rp 45.000');
      expect(amountField, findsOneWidget);
      await tester.enterText(amountField, '55000');
      await tester.pumpAndSettle();
      expect(find.text('Rp 55.000'), findsOneWidget);
    });

    testWidgets('Displays fallback manual button when totalAmount is 0', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final draftZero = createSampleDraft(totalAmount: 0);
      await tester.pumpWidget(buildTestWidget(draftZero));
      await tester.pumpAndSettle();

      // Inline hint status appears
      expect(find.text('Nominal belum terdeteksi otomatis. Ketuk untuk mengisi.'), findsOneWidget);
      // Secondary manual button appears
      expect(find.text('Beralih ke Input Manual'), findsOneWidget);
    });

    testWidgets('Validation prevents saving when nominal is cleared to 0', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final draftZero = createSampleDraft(totalAmount: 0);
      await tester.pumpWidget(buildTestWidget(draftZero));
      await tester.pumpAndSettle();

      // Tap confirm button while amount is 0
      await tester.tap(find.text('Konfirmasi & Simpan Transaksi'));
      await tester.pump();

      // SnackBar validation message
      expect(find.text('Nominal pengeluaran harus lebih dari Rp 0.'), findsOneWidget);
    });

    testWidgets('Modal sheet selectors open for Wallet and Category', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final draft = createSampleDraft();
      await tester.pumpWidget(buildTestWidget(draft));
      await tester.pumpAndSettle();

      // Tap Dompet selector row
      await tester.tap(find.text('Dompet Sumber'));
      await tester.pumpAndSettle();

      // Verify Wallet bottom sheet opened
      expect(find.text('Pilih Dompet Sumber Dana'), findsOneWidget);
      // Dismiss sheet
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      // Tap Kategori selector row
      await tester.tap(find.text('Kategori'));
      await tester.pumpAndSettle();

      // Verify Category bottom sheet opened
      expect(find.text('Pilih Kategori Pengeluaran'), findsOneWidget);
      // Dismiss sheet
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
    });

    testWidgets('Renders consistently in Dark Mode and small screens without overflow', (tester) async {
      // iPhone SE screen size (320 x 568 pt)
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final draft = createSampleDraft();
      await tester.pumpWidget(buildTestWidget(draft, brightness: Brightness.dark));
      await tester.pumpAndSettle();

      expect(find.text('Review Struk'), findsOneWidget);
      expect(find.text('TOTAL TRANSAKSI'), findsOneWidget);
      expect(find.text('Konfirmasi & Simpan Transaksi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Does not display Perlu Diperiksa badge on merchant input even if isMerchantCertain is false', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final draft = createSampleDraft().copyWith(isMerchantCertain: false);
      await tester.pumpWidget(buildTestWidget(draft));
      await tester.pumpAndSettle();

      // Merchant input is rendered cleanly
      expect(find.text('Merchant / Toko'), findsOneWidget);
      expect(find.text('Indomaret Sudirman'), findsOneWidget);

      // Verify no 'Perlu Diperiksa' badge is shown
      expect(find.text('Perlu Diperiksa'), findsNothing);
    });
  });
}
