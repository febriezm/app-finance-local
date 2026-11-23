import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:myfinance/app/app_providers.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/core/utils/greeting_helper.dart';
import 'package:myfinance/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase inMemoryDb;

  setUp(() async {
    inMemoryDb = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    // In-memory db garbage collected
  });

  testWidgets('DashboardScreen displays dynamic greeting matching GreetingHelper.getGreeting()', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final expectedGreeting = GreetingHelper.getGreeting();
    expect(find.text('$expectedGreeting,'), findsOneWidget);
    expect(find.text('Ringkasan Finansial'), findsOneWidget);

    // Unmount and pump out any closing stream timers
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
