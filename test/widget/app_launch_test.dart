import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:myfinance/app/app.dart';
import 'package:myfinance/app/app_providers.dart';
import 'package:myfinance/core/database/app_database.dart';

void main() {
  testWidgets('MyFinanceApp launches and displays dashboard and navigation bar', (tester) async {
    final inMemoryDb = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
        ],
        child: const MyFinanceApp(),
      ),
    );

    // Initial pump and settle
    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text('MyFinance'), findsOneWidget);

    // Verify Dashboard card
    expect(find.text('Total Saldo Bersih'), findsOneWidget);
    expect(find.text('Rp 0'), findsWidgets);

    // Verify Bottom Navigation Bar items
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Transaksi'), findsOneWidget);
    expect(find.text('Dompet'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);

    await inMemoryDb.close();
  });
}
