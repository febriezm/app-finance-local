import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:myfinance/app/app_providers.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/core/formatting/date_formatter.dart';
import 'package:myfinance/features/budgets/domain/entities/budget.dart';
import 'package:myfinance/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:myfinance/features/wallets/domain/entities/wallet.dart';

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
    required int balance,
    required int income,
    required int expense,
    Brightness brightness = Brightness.light,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    final currentMonthKey = AppDateFormatter.toMonthKey(DateTime.now());

    final sampleWallet = Wallet(
      id: 'w-1',
      name: 'Bank Mandiri',
      type: WalletType.bank,
      openingBalance: balance,
      openingDate: now,
      createdAt: now,
      updatedAt: now,
    );

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(inMemoryDb),
        netOperationalBalanceProvider.overrideWith((ref) => balance),
        walletsWithBalanceStreamProvider.overrideWith(
          (ref) => Stream.value([WalletWithBalance(wallet: sampleWallet, currentBalance: balance)]),
        ),
        monthlyIncomeProvider(currentMonthKey).overrideWith(
          (ref) => Stream.value(income),
        ),
        monthlyExpenseProvider(currentMonthKey).overrideWith(
          (ref) => Stream.value(expense),
        ),
        budgetProgressStreamProvider(currentMonthKey).overrideWith(
          (ref) => Stream.value(BudgetProgress(
            monthKey: currentMonthKey,
            totalLimit: 0,
            totalSpent: 0,
            percentage: 0,
            remaining: 0,
            status: BudgetStatus.normal,
          )),
        ),
        recentTransactionsStreamProvider.overrideWith(
          (ref) => Stream.value([]),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: const DashboardScreen(),
      ),
    );
  }

  group('Dashboard Dedicated Balance Card Tests', () {
    testWidgets('Renders Dedicated Balance Card as prominent focal point with balance, income, expense, and wallet count', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(
        balance: 15750000,
        income: 20000000,
        expense: 4250000,
      ));
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(const Key('dedicated_balance_card'));
      expect(cardFinder, findsOneWidget);

      // Card Header
      expect(find.descendant(of: cardFinder, matching: find.text('TOTAL SALDO BERSIH')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.byIcon(Icons.visibility_outlined)), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('1 Dompet')), findsOneWidget);

      // Hero Balance
      expect(find.descendant(of: cardFinder, matching: find.text('Rp 15.750.000')), findsOneWidget);

      // Compact Arus Kas Bulanan
      expect(find.descendant(of: cardFinder, matching: find.text('Pemasukan')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('Rp 20.000.000')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('Pengeluaran')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('- Rp 4.250.000')), findsOneWidget);
    });

    testWidgets('Toggling visibility hides and reveals nominals with masked dots', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(
        balance: 15750000,
        income: 20000000,
        expense: 4250000,
      ));
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(const Key('dedicated_balance_card'));

      // Initially visible
      expect(find.descendant(of: cardFinder, matching: find.text('Rp 15.750.000')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.byIcon(Icons.visibility_outlined)), findsOneWidget);

      // Tap toggle button to hide balance
      await tester.tap(find.descendant(of: cardFinder, matching: find.byIcon(Icons.visibility_outlined)));
      await tester.pumpAndSettle();

      // Masked dots shown in card
      expect(find.descendant(of: cardFinder, matching: find.byIcon(Icons.visibility_off_outlined)), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('Rp ••••••••')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('Rp ••••••')), findsNWidgets(2)); // Pemasukan and Pengeluaran
      expect(find.descendant(of: cardFinder, matching: find.text('Rp 15.750.000')), findsNothing);

      // Tap toggle button to restore balance
      await tester.tap(find.descendant(of: cardFinder, matching: find.byIcon(Icons.visibility_off_outlined)));
      await tester.pumpAndSettle();

      // Visible again
      expect(find.descendant(of: cardFinder, matching: find.byIcon(Icons.visibility_outlined)), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('Rp 15.750.000')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('Rp 20.000.000')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('- Rp 4.250.000')), findsOneWidget);
    });

    testWidgets('Renders properly in Dark Mode and on narrow screens (320x568) without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(
        balance: 1500000000, // 1.5 Milyar
        income: 500000000,
        expense: 200000000,
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(const Key('dedicated_balance_card'));
      expect(cardFinder, findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('TOTAL SALDO BERSIH')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.byIcon(Icons.visibility_outlined)), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('Rp 1.500.000.000')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
