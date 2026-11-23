import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:myfinance/app/app_providers.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/features/wallets/domain/entities/wallet.dart';
import 'package:myfinance/features/wallets/presentation/screens/wallets_screen.dart';
import 'package:myfinance/shared/widgets/wallet_card.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase inMemoryDb;

  setUp(() async {
    inMemoryDb = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await inMemoryDb.close();
  });

  Widget buildTestWidget({
    required List<WalletWithBalance> activeWallets,
    List<WalletWithBalance> archivedWallets = const [],
    Brightness brightness = Brightness.light,
  }) {
    final activeTotal = activeWallets.fold<int>(0, (sum, w) => sum + w.currentBalance);
    final archivedTotal = archivedWallets.fold<int>(0, (sum, w) => sum + w.currentBalance);
    final totalAll = activeTotal + archivedTotal;

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(inMemoryDb),
        totalAllAssetBalanceProvider.overrideWith((ref) => totalAll),
        walletsWithBalanceStreamProvider.overrideWith(
          (ref) => Stream.value(activeWallets),
        ),
        archivedWalletsWithBalanceStreamProvider.overrideWith(
          (ref) => Stream.value(archivedWallets),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: const WalletsScreen(),
      ),
    );
  }

  group('WalletsScreen Dedicated Asset Balance Card & Individual Wallet Cards Tests', () {
    testWidgets('Renders Dedicated Asset Balance Card and individual WalletCards across all wallet types (Bank, Cash, E-Wallet, Other)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now().toUtc().toIso8601String();
      final sampleBank = Wallet(
        id: 'w-bank',
        name: 'Bank BCA',
        type: WalletType.bank,
        openingBalance: 30000000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final sampleCash = Wallet(
        id: 'w-cash',
        name: 'Dompet Tunai',
        type: WalletType.cash,
        openingBalance: 5000000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final sampleEWallet = Wallet(
        id: 'w-gopay',
        name: 'GoPay',
        type: WalletType.eWallet,
        openingBalance: 2500000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final sampleOther = Wallet(
        id: 'w-crypto',
        name: 'Bibit Reksadana',
        type: WalletType.other,
        openingBalance: 15000000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(buildTestWidget(
        activeWallets: [
          WalletWithBalance(wallet: sampleBank, currentBalance: 30000000),
          WalletWithBalance(wallet: sampleCash, currentBalance: 5000000),
          WalletWithBalance(wallet: sampleEWallet, currentBalance: 2500000),
          WalletWithBalance(wallet: sampleOther, currentBalance: 15000000),
        ],
      ));
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(const Key('dedicated_asset_balance_card'));
      expect(cardFinder, findsOneWidget);

      // Card Header
      expect(find.descendant(of: cardFinder, matching: find.text('TOTAL SALDO ASET')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.byIcon(Icons.visibility_outlined)), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('4 Dompet Aktif')), findsOneWidget);

      // Hero Total Balance (30M + 5M + 2.5M + 15M = 52.5M)
      expect(find.descendant(of: cardFinder, matching: find.text('Rp 52.500.000')), findsOneWidget);

      // Compact Asset Breakdown
      // Kas & Bank (30M + 5M = 35M)
      expect(find.descendant(of: cardFinder, matching: find.text('Kas & Bank')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('Rp 35.000.000')), findsOneWidget);

      // E-Wallet & Lainnya (2.5M + 15M = 17.5M)
      expect(find.descendant(of: cardFinder, matching: find.text('E-Wallet & Lainnya')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('Rp 17.500.000')), findsOneWidget);

      // Verify all 4 individual WalletCards are rendered
      expect(find.byType(WalletCard), findsNWidgets(4));
      expect(find.text('Bank BCA'), findsOneWidget);
      expect(find.text('Dompet Tunai'), findsOneWidget);
      expect(find.text('GoPay'), findsOneWidget);
      expect(find.text('Bibit Reksadana'), findsOneWidget);

      // Saldo labels inside cards
      expect(find.text('SALDO'), findsNWidgets(4));
    });

    testWidgets('Tapping a WalletCard opens wallet detail bottom sheet with Edit, Transfer, and Mutasi actions', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now().toUtc().toIso8601String();
      final sampleBank = Wallet(
        id: 'w-bank',
        name: 'Bank BCA',
        type: WalletType.bank,
        openingBalance: 30000000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(buildTestWidget(
        activeWallets: [
          WalletWithBalance(wallet: sampleBank, currentBalance: 30000000),
        ],
      ));
      await tester.pumpAndSettle();

      // Tap the BCA card
      await tester.tap(find.text('Bank BCA'));
      await tester.pumpAndSettle();

      // Detail sheet is opened
      expect(find.text('Riwayat Mutasi Transaksi'), findsOneWidget);
      expect(find.text('Transfer dari Dompet Ini'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Arsipkan'), findsOneWidget);
    });

    testWidgets('Toggling visibility hides and reveals asset nominals on both Asset Card and individual WalletCards', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now().toUtc().toIso8601String();
      final sampleBank = Wallet(
        id: 'w-bank',
        name: 'Bank Mandiri',
        type: WalletType.bank,
        openingBalance: 10000000,
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(buildTestWidget(
        activeWallets: [
          WalletWithBalance(wallet: sampleBank, currentBalance: 10000000),
        ],
      ));
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(const Key('dedicated_asset_balance_card'));

      // Initially visible
      expect(find.descendant(of: cardFinder, matching: find.text('Rp 10.000.000')), findsNWidgets(2)); // Hero + Kas & Bank
      expect(find.descendant(of: cardFinder, matching: find.byIcon(Icons.visibility_outlined)), findsOneWidget);

      // Tap toggle button to hide balance
      await tester.tap(find.descendant(of: cardFinder, matching: find.byIcon(Icons.visibility_outlined)));
      await tester.pumpAndSettle();

      // Masked dots shown on both Dedicated Card and WalletCard
      expect(find.descendant(of: cardFinder, matching: find.byIcon(Icons.visibility_off_outlined)), findsOneWidget);
      expect(find.text('Rp ••••••••'), findsNWidgets(2)); // 1 on dedicated card, 1 on WalletCard
      expect(find.descendant(of: cardFinder, matching: find.text('Rp ••••••')), findsNWidgets(2)); // Kas & Bank + E-Wallet
      expect(find.text('Rp 10.000.000'), findsNothing);

      // Tap toggle button to restore balance
      await tester.tap(find.descendant(of: cardFinder, matching: find.byIcon(Icons.visibility_off_outlined)));
      await tester.pumpAndSettle();

      // Visible again
      expect(find.descendant(of: cardFinder, matching: find.byIcon(Icons.visibility_outlined)), findsOneWidget);
      expect(find.text('Rp 10.000.000'), findsNWidgets(3)); // Hero + Kas & Bank + WalletCard
    });

    testWidgets('Renders properly in Dark Mode and on narrow screens (320x568) without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now().toUtc().toIso8601String();
      final sampleBank = Wallet(
        id: 'w-bank',
        name: 'Bank Central Asia',
        type: WalletType.bank,
        openingBalance: 2500000000, // 2.5 Milyar
        openingDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final sampleArchived = Wallet(
        id: 'w-old',
        name: 'Rekening Lama',
        type: WalletType.bank,
        openingBalance: 500000000, // 500 Juta
        openingDate: now,
        createdAt: now,
        updatedAt: now,
        isArchived: true,
      );

      await tester.pumpWidget(buildTestWidget(
        activeWallets: [
          WalletWithBalance(wallet: sampleBank, currentBalance: 2500000000),
        ],
        archivedWallets: [
          WalletWithBalance(wallet: sampleArchived, currentBalance: 500000000),
        ],
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(const Key('dedicated_asset_balance_card'));
      expect(cardFinder, findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('TOTAL SALDO ASET')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.byIcon(Icons.visibility_outlined)), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('1 Aktif • 1 Arsip')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('Rp 3.000.000.000')), findsOneWidget);
      expect(find.byType(WalletCard), findsAtLeastNWidgets(1));
      expect(find.text('Bank Central Asia'), findsOneWidget);

      // Scroll down to view the archived wallet card
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Rekening Lama'), findsOneWidget);
      expect(find.text('Rp 500.000.000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
