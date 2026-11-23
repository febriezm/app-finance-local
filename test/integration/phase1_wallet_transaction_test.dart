import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/app/app.dart';
import 'package:myfinance/app/app_providers.dart';
import 'package:myfinance/core/database/app_database.dart';

void main() {
  testWidgets('Phase 1 Integration: Add Wallets, Record Expense & verify ledger balance updates',
      (tester) async {
    final inMemoryDb = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
        ],
        child: const MyFinanceApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Initial State: Total Saldo = Rp 0
    expect(find.text('Rp 0'), findsWidgets);

    // 2. Navigate to "Dompet" tab
    await tester.tap(find.text('Dompet'));
    await tester.pumpAndSettle();

    expect(find.text('Belum Ada Dompet'), findsOneWidget);

    // 3. Tap "Tambah Dompet" from empty state button
    await tester.tap(find.text('Tambah Dompet'));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Dompet Baru'), findsOneWidget);

    // Fill Name & Opening Balance
    await tester.enterText(
        find.widgetWithText(TextField, 'Contoh: BCA Utama, GoPay, Dompet Tunai'), 'BCA Tabungan');
    await tester.enterText(find.widgetWithText(TextField, 'Rp 0'), '1000000');
    await tester.pumpAndSettle();

    // Tap "Simpan"
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    // 4. Verify BCA Tabungan appears with Rp 1.000.000
    expect(find.byWidgetPredicate((w) => w is Text && w.data == 'BCA Tabungan'), findsOneWidget);
    expect(find.text('Rp 1.000.000'), findsWidgets);

    // 5. Navigate to "Home" tab
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    // Total balance is now Rp 1.000.000
    expect(find.text('Rp 1.000.000'), findsWidgets);

    // 6. Tap quick action "Pengeluaran"
    await tester.tap(find.widgetWithText(InkWell, 'Pengeluaran'));
    await tester.pumpAndSettle();

    expect(find.text('Catat Transaksi'), findsOneWidget);

    // Enter amount 50000
    await tester.enterText(find.widgetWithText(TextField, 'Rp 0'), '50000');
    await tester.pumpAndSettle();

    // Tap "Simpan"
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    // 7. Verify balance updated to Rp 950.000 (1.000.000 - 50.000)
    expect(find.text('Rp 950.000'), findsWidgets);

    // 8. Go to "Transaksi" tab
    await tester.tap(find.text('Transaksi'));
    await tester.pumpAndSettle();

    // Verify transaction listed with - Rp 50.000
    expect(find.text('- Rp 50.000'), findsOneWidget);

    await inMemoryDb.close();
  });
}
