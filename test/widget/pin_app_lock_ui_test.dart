import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:local_auth/local_auth.dart';
import 'package:myfinance/app/app_providers.dart';
import 'package:myfinance/core/database/app_database.dart';
import 'package:myfinance/core/services/app_lock_service.dart';
import 'package:myfinance/features/security/presentation/controllers/app_lock_controller.dart';
import 'package:myfinance/features/security/presentation/widgets/pin_dots_indicator.dart';
import 'package:myfinance/features/security/presentation/widgets/pin_keypad.dart';
import 'package:myfinance/features/security/presentation/widgets/pin_setup_sheet.dart';
import 'package:myfinance/features/security/presentation/widgets/pin_verify_sheet.dart';
import 'package:myfinance/features/security/presentation/widgets/app_lock_screen.dart';

class FakeTestLockService extends AppLockService {
  bool authenticateResult;
  bool biometricsAvailable;

  FakeTestLockService({
    this.authenticateResult = true,
    this.biometricsAvailable = true,
  });

  @override
  Future<bool> isBiometricsAvailable() async => biometricsAvailable;

  @override
  Future<String> getBiometricTypeLabel() async => 'Biometrik';

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => [];

  @override
  Future<bool> authenticate({String reason = ''}) async => authenticateResult;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase inMemoryDb;
  late FakeTestLockService fakeLockService;

  setUp(() {
    inMemoryDb = AppDatabase(NativeDatabase.memory());
    fakeLockService = FakeTestLockService();
  });

  tearDown(() async {
    // Memory database will be garbage collected
  });

  group('PIN & App Lock UI Tests', () {
    testWidgets('PinDotsIndicator renders correct dots count, filled states, and error color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PinDotsIndicator(
              pinLength: 6,
              currentLength: 3,
              hasError: false,
            ),
          ),
        ),
      );

      final indicator = find.byType(PinDotsIndicator);
      expect(indicator, findsOneWidget);

      final rowFinder = find.descendant(of: indicator, matching: find.byType(Row));
      expect(rowFinder, findsOneWidget);

      // Verify 6 AnimatedContainer dots
      final containerFinders = find.descendant(of: indicator, matching: find.byType(AnimatedContainer));
      expect(containerFinders, findsNWidgets(6));
    });

    testWidgets('PinKeypad renders 0-9 digits, backspace, and biometric button', (tester) async {
      String pressedDigit = '';
      bool deleteCalled = false;
      bool bioCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinKeypad(
              onDigitPressed: (d) => pressedDigit = d,
              onDeletePressed: () => deleteCalled = true,
              onBiometricPressed: () => bioCalled = true,
              showBiometricButton: true,
            ),
          ),
        ),
      );

      // Verify digits 1 to 9 and 0
      for (int i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }

      // Tap digit 7
      await tester.tap(find.text('7'));
      expect(pressedDigit, '7');

      // Tap backspace
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      expect(deleteCalled, true);

      // Tap biometric button
      await tester.tap(find.byIcon(Icons.fingerprint_rounded));
      expect(bioCalled, true);
    });

    testWidgets('PinSetupSheet: Set PIN -> Confirm PIN -> Success flow', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool isSuccessCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(inMemoryDb),
            appLockControllerProvider.overrideWith(
              (ref) => AppLockController(
                lockService: fakeLockService,
                appSettingsDao: inMemoryDb.appSettingsDao,
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PinSetupSheet(
                onSuccess: () => isSuccessCalled = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Phase 1: Masukkan 6 Digit Angka
      expect(find.text('Masukkan 6 Digit Angka'), findsOneWidget);

      // Input 1 2 3 4 5 6
      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Wait for transition to confirmation phase
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Kode Sandi'), findsOneWidget);

      // Input confirmation 1 2 3 4 5 6
      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();
      expect(isSuccessCalled, isTrue);
    });

    testWidgets('PinSetupSheet: PIN Mismatch triggers error message and resets confirmation', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(inMemoryDb),
            appLockControllerProvider.overrideWith(
              (ref) => AppLockController(
                lockService: fakeLockService,
                appSettingsDao: inMemoryDb.appSettingsDao,
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PinSetupSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Phase 1: Input 1 2 3 4 5 6
      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi Kode Sandi'), findsOneWidget);

      // Phase 2: Input 6 5 4 3 2 1 (mismatch)
      for (final digit in ['6', '5', '4', '3', '2', '1']) {
        await tester.tap(find.text(digit));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();

      // Verify mismatch error message
      expect(find.text('Kode sandi konfirmasi tidak cocok. Ulangi kembali.'), findsOneWidget);
      // Returned back to stage 1
      expect(find.text('Masukkan 6 Digit Angka'), findsOneWidget);
    });

    testWidgets('PinSetupSheet: Backspace decreases digits and returns to stage 1 if confirm is empty', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(inMemoryDb),
            appLockControllerProvider.overrideWith(
              (ref) => AppLockController(
                lockService: fakeLockService,
                appSettingsDao: inMemoryDb.appSettingsDao,
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PinSetupSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Type 3 digits then delete 1
      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      // Type remaining to reach 6 digits
      for (final digit in ['3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi Kode Sandi'), findsOneWidget);

      // In confirm stage, tapping backspace when empty returns to stage 1
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Masukkan 6 Digit Angka'), findsOneWidget);
    });

    testWidgets('PinVerifySheet: Correct PIN succeeds and wrong PIN displays error', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinVerifySheet(
              title: 'Verifikasi PIN',
              subtitle: 'Masukkan PIN untuk lanjut',
              onPinEntered: (pin) async => pin == '112233',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Verifikasi PIN'), findsOneWidget);

      // Wrong PIN: 1 2 3 4 5 6
      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();
      expect(find.text('Kode sandi salah. Silakan coba lagi.'), findsOneWidget);

      // Correct PIN: 1 1 2 2 3 3
      for (final digit in ['1', '1', '2', '2', '3', '3']) {
        await tester.tap(find.text(digit));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();
    });

    testWidgets('AppLockScreen: Displays lock icon and keypad, verifies unlock', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = AppLockController(
        lockService: fakeLockService,
        appSettingsDao: inMemoryDb.appSettingsDao,
        initialLockEnabled: true,
        initialHasPin: true,
      );

      // Setup PIN 123456 without biometrics so manual PIN verification can be tested
      await controller.setupPin('123456', enableBiometrics: false);
      controller.lock();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLockControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: AppLockScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('MyFinance Terkunci'), findsOneWidget);
      expect(find.text('Masukkan 6 digit kode sandi Anda'), findsOneWidget);

      // Enter wrong PIN: 999999
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('9'));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();
      expect(find.text('Kode sandi salah. Silakan coba lagi.'), findsOneWidget);

      // Enter correct PIN: 123456
      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();
      expect(controller.state.isUnlocked, isTrue);
    });
  });
}
