import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/core/services/app_lock_service.dart';
import 'package:myfinance/features/security/presentation/controllers/app_lock_controller.dart';

class FakeAppLockService extends AppLockService {
  bool shouldSucceed;
  bool biometricsAvailable;
  int authCallCount = 0;

  FakeAppLockService({
    this.shouldSucceed = true,
    this.biometricsAvailable = true,
  });

  @override
  Future<bool> isBiometricsAvailable() async => biometricsAvailable;

  @override
  Future<bool> authenticate({String reason = ''}) async {
    authCallCount++;
    return shouldSucceed;
  }
}

void main() {
  group('Phase 5 - App Lock & Biometrics Controller Tests', () {
    test('Initial state: lock is disabled and app is unlocked', () {
      final fakeService = FakeAppLockService();
      final controller = AppLockController(lockService: fakeService);

      expect(controller.state.isAppLockEnabled, false);
      expect(controller.state.isUnlocked, true);
      expect(controller.state.errorMessage, isNull);
    });

    test('Setup 6-digit PIN enables App Lock and sets hasPinSet to true', () async {
      final fakeService = FakeAppLockService(shouldSucceed: true);
      final controller = AppLockController(lockService: fakeService);

      final result = await controller.setupPin('123456');

      expect(result, true);
      expect(controller.state.isAppLockEnabled, true);
      expect(controller.state.isUnlocked, true);
      expect(controller.state.hasPinSet, true);
      expect(controller.state.errorMessage, isNull);
    });

    test('Setup PIN fails if PIN is not 6 digits', () async {
      final fakeService = FakeAppLockService(shouldSucceed: true);
      final controller = AppLockController(lockService: fakeService);

      final result = await controller.setupPin('123');

      expect(result, false);
      expect(controller.state.isAppLockEnabled, false);
      expect(controller.state.errorMessage, contains('6 digit'));
    });

    test('Locking app manually sets isUnlocked to false', () async {
      final fakeService = FakeAppLockService(shouldSucceed: true);
      final controller = AppLockController(
        lockService: fakeService,
        initialLockEnabled: true,
      );

      controller.lock();
      expect(controller.state.isUnlocked, false);

      // Unlock with PIN
      final unlockResult = await controller.unlockWithPin('123456');
      expect(unlockResult, true);
      expect(controller.state.isUnlocked, true);
    });

    test('Unlock with biometrics succeeds when biometric challenge passes', () async {
      final fakeService = FakeAppLockService(shouldSucceed: true, biometricsAvailable: true);
      final controller = AppLockController(
        lockService: fakeService,
        initialLockEnabled: true,
      );

      // Force enable biometrics state
      await controller.init();
      await controller.setBiometricsEnabled(true);
      controller.lock();
      expect(controller.state.isUnlocked, false);

      final bioResult = await controller.unlockWithBiometrics();
      expect(bioResult, true);
      expect(fakeService.authCallCount, 1);
      expect(controller.state.isUnlocked, true);
    });

    test('Unlock fails with error message when biometric challenge fails', () async {
      final fakeService = FakeAppLockService(shouldSucceed: false, biometricsAvailable: true);
      final controller = AppLockController(
        lockService: fakeService,
        initialLockEnabled: true,
      );

      await controller.init();
      await controller.setBiometricsEnabled(true);
      controller.lock();
      expect(controller.state.isUnlocked, false);

      final unlockResult = await controller.unlockWithBiometrics();
      expect(unlockResult, false);
      expect(controller.state.isUnlocked, false);
      expect(controller.state.errorMessage, contains('tidak berhasil'));
    });

    test('PIN hashing and verification utility works correctly', () {
      const pin = '582910';
      final hash = AppLockService.hashPin(pin);

      expect(hash, isNotEmpty);
      expect(AppLockService.verifyPin('582910', hash), true);
      expect(AppLockService.verifyPin('000000', hash), false);
    });
  });
}
