import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:myfinance/app/app_providers.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/features/backup_restore/presentation/screens/backup_restore_screen.dart';

void main() {
  late AppDatabase inMemoryDb;

  setUp(() {
    inMemoryDb = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await inMemoryDb.close();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(inMemoryDb),
      ],
      child: const MaterialApp(
        home: BackupRestoreScreen(),
      ),
    );
  }

  group('BackupRestoreScreen Widget Tests', () {
    testWidgets('Displays all sections: Header, Privacy, Backup, Restore, and Danger Zone', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 1. Header
      expect(find.text('Cadangkan & Pulihkan'), findsOneWidget);

      // 2. Privacy
      expect(find.text('Penyimpanan Lokal & Privat'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

      // 3. Backup Section
      expect(find.text('Cadangkan Data'), findsOneWidget);
      expect(find.text('Buat & Bagikan Cadangan (JSON)'), findsOneWidget);

      // 4. Restore Section
      expect(find.text('Pulihkan Data'), findsOneWidget);
      expect(find.text('Pilih Berkas Cadangan (.json)'), findsOneWidget);
      expect(find.text('atau Tempel / Masukkan Teks Cadangan'), findsOneWidget);

      // 5. Danger Zone
      expect(find.text('ZONA BERBAHAYA'), findsOneWidget);
      expect(find.text('Reset Seluruh Data Aplikasi'), findsNWidgets(2)); // Title and Button
    });

    testWidgets('Tapping Paste button opens manual paste modal sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Mock empty clipboard so fallback manual paste modal is opened
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (methodCall) async {
          if (methodCall.method == 'Clipboard.getData') {
            return {'text': ''};
          }
          return null;
        },
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final pasteBtn = find.text('atau Tempel / Masukkan Teks Cadangan');
      await tester.tap(pasteBtn);
      await tester.pumpAndSettle();

      // Verify modal sheet is shown
      expect(find.text('Tempel Teks Cadangan'), findsOneWidget);
      expect(find.text('Periksa & Muat'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Tempel Teks Cadangan'), findsNothing);
    });

    testWidgets('Danger Zone: Reset confirmation modal requires typing RESET before execution', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Reset button
      final resetBtn = find.widgetWithText(OutlinedButton, 'Reset Seluruh Data Aplikasi');
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Verify dialog is opened
      expect(find.text('Hapus Seluruh Data?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      final confirmBtn = find.widgetWithText(ElevatedButton, 'Hapus Semua Data');
      expect(confirmBtn, findsOneWidget);

      // Confirm button should initially be disabled because text is empty
      final elevatedButtonBefore = tester.widget<ElevatedButton>(confirmBtn);
      expect(elevatedButtonBefore.onPressed, isNull);

      // Enter wrong text
      await tester.enterText(find.byType(TextField), 'SALAH');
      await tester.pumpAndSettle();
      final elevatedButtonWrong = tester.widget<ElevatedButton>(confirmBtn);
      expect(elevatedButtonWrong.onPressed, isNull);

      // Enter correct confirmation text "RESET"
      await tester.enterText(find.byType(TextField), 'RESET');
      await tester.pumpAndSettle();
      final elevatedButtonCorrect = tester.widget<ElevatedButton>(confirmBtn);
      expect(elevatedButtonCorrect.onPressed, isNotNull);

      // Tap Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus Seluruh Data?'), findsNothing);
    });
  });
}
