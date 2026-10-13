import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cwc_health_app/features/my_health/data/biometric_unlock.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_models.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:cwc_health_app/features/my_health/data/prefs_health_store.dart';

import '../../support/fake_biometric.dart';

void main() {
  test('exception codes fall back instead of blocking', () {
    expect(
      biometricResultForException(LocalAuthExceptionCode.noBiometricHardware),
      BiometricResult.unavailable,
    );
    expect(
      biometricResultForException(LocalAuthExceptionCode.noBiometricsEnrolled),
      BiometricResult.notEnrolled,
    );
    expect(
      biometricResultForException(LocalAuthExceptionCode.userCanceled),
      BiometricResult.cancelled,
    );
    expect(
      biometricResultForException(LocalAuthExceptionCode.systemCanceled),
      BiometricResult.cancelled,
    );
    expect(
      biometricResultForException(LocalAuthExceptionCode.temporaryLockout),
      BiometricResult.lockout,
    );
    expect(
      biometricResultForException(LocalAuthExceptionCode.biometricLockout),
      BiometricResult.lockout,
    );
    expect(
      biometricResultForException(LocalAuthExceptionCode.unknownError),
      BiometricResult.failed,
    );
  });

  test('fingerprint toggle stays hidden when the phone has none', () async {
    final fake = FakeBiometricAuthenticator(available: false);
    final health = HealthController(InMemoryHealthStore(), biometrics: fake);
    await health.load();
    expect(await health.setPin('1234'), isTrue);
    expect(health.biometricAvailable, isFalse);
    expect(await health.enableBiometricUnlock(), isFalse);
    expect(health.biometricEnabled, isFalse);
    expect(fake.calls, 0);
  });

  test('success unlocks, and failure cancel or lockout keep the PIN', () async {
    final fake = FakeBiometricAuthenticator(available: true);
    final health = HealthController(InMemoryHealthStore(), biometrics: fake);
    await health.load();
    expect(await health.setPin('1234'), isTrue);
    expect(await health.enableBiometricUnlock(), isTrue);
    expect(health.biometricEnabled, isTrue);

    health.lock();
    expect(await health.unlockWithBiometric(), BiometricResult.success);
    expect(health.isUnlocked, isTrue);

    for (final result in [
      BiometricResult.failed,
      BiometricResult.cancelled,
      BiometricResult.lockout,
    ]) {
      health.lock();
      fake.result = result;
      expect(await health.unlockWithBiometric(), result);
      expect(health.isUnlocked, isFalse);
      expect(await health.unlock('1234'), isTrue);
    }
  });

  test('toggle survives reload and clearing the PIN clears it', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeBiometricAuthenticator(available: true);
    final first = HealthController(PrefsHealthStore(prefs), biometrics: fake);
    await first.load();
    expect(await first.setPin('1234'), isTrue);
    expect(await first.enableBiometricUnlock(), isTrue);

    final again = HealthController(PrefsHealthStore(prefs), biometrics: fake);
    await again.load();
    expect(again.hasPin, isTrue);
    expect(again.biometricEnabled, isTrue);
    expect(again.isUnlocked, isFalse);

    await again.clearPin();
    expect(again.biometricEnabled, isFalse);
    expect(again.hasPin, isFalse);

    final third = HealthController(PrefsHealthStore(prefs), biometrics: fake);
    await third.load();
    expect(third.biometricEnabled, isFalse);
    expect(third.hasPin, isFalse);
  });

  test('erase clears the fingerprint toggle with the PIN', () async {
    final store = InMemoryHealthStore();
    final fake = FakeBiometricAuthenticator(available: true);
    final health = HealthController(store, biometrics: fake);
    await health.load();
    await health.setPin('1234');
    expect(await health.enableBiometricUnlock(), isTrue);
    await health.eraseAll();
    expect(health.biometricEnabled, isFalse);
    expect(health.hasPin, isFalse);

    final again = HealthController(store, biometrics: fake);
    await again.load();
    expect(again.biometricEnabled, isFalse);
  });

  test('older JSON without the fingerprint flag stays off', () {
    final snap = HealthSnapshot.fromJson({
      'appointments': [
        {
          'id': 'a1',
          'provider': 'Dr. Lee',
          'whenLabel': 'Mon',
          'location': 'Clinic',
          'phone': '555',
        },
      ],
      'pinHash': 'abc123',
      'initialized': true,
    });
    expect(snap.biometricEnabled, isFalse);
    expect(snap.pinHash, 'abc123');
    expect(snap.appointments.single.provider, 'Dr. Lee');
  });
}
