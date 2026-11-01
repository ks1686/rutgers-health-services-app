import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/my_health/data/biometric_unlock.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_models.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:cwc_health_app/features/my_health/data/pin_hasher.dart';
import 'package:cwc_health_app/features/my_health/health_auto_lock.dart';
import 'package:cwc_health_app/features/my_health/my_health_screen.dart';

class _Clock {
  DateTime now = DateTime.utc(2026, 11, 2, 9);
  DateTime call() => now;
}

class _YesBiometric implements BiometricAuthenticator {
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<BiometricResult> authenticate() async => BiometricResult.success;
}

void main() {
  group('H5 PIN at rest and wrong tries', () {
    test('a saved PIN is a salted slow hash, not a short fast one', () async {
      final store = InMemoryHealthStore();
      final a = HealthController(store);
      await a.load();
      expect(await a.setPin('1234'), isTrue);
      final first = (await store.read()).pinHash!;

      final other = InMemoryHealthStore();
      final b = HealthController(other);
      await b.load();
      await b.setPin('1234');
      final second = (await other.read()).pinHash!;

      expect(first, startsWith(r'pbkdf2-sha256$'));
      expect(first, isNot(second), reason: 'each PIN gets its own salt');
    });

    test('wrong tries stop being checked, even after a restart', () async {
      final store = InMemoryHealthStore();
      final a = HealthController(store);
      await a.load();
      await a.setPin('1234');
      a.lock();
      for (var i = 0; i < 5; i++) {
        expect(await a.unlock('0000'), isFalse);
      }

      final again = HealthController(store);
      await again.load();
      expect(
        await again.unlock('1234'),
        isFalse,
        reason: 'the right PIN waits out the lockout after 5 misses',
      );
      expect(again.isUnlocked, isFalse);
    });
  });

  group('H5 lockout timing', () {
    late _Clock clock;
    late InMemoryHealthStore store;
    late HealthController health;

    setUp(() async {
      clock = _Clock();
      store = InMemoryHealthStore();
      health = HealthController(store, clock: clock.call);
      await health.load();
      await health.setPin('1234');
      health.lock();
    });

    test('four misses are free, the fifth starts a 30 second wait', () async {
      for (var i = 0; i < 4; i++) {
        expect(await health.tryUnlock('0000'), PinCheck.wrong);
        expect(health.pinLockoutRemaining, Duration.zero);
      }
      expect(await health.tryUnlock('0000'), PinCheck.wrong);
      expect(health.pinLockoutRemaining, const Duration(seconds: 30));
      expect(await health.tryUnlock('1234'), PinCheck.lockedOut);

      clock.now = clock.now.add(const Duration(seconds: 30));
      expect(await health.tryUnlock('1234'), PinCheck.unlocked);
      final saved = await store.read();
      expect(saved.pinFailures, 0);
      expect(saved.pinLockedUntil, isNull);
    });

    test('each later miss doubles the wait, up to 15 minutes', () {
      expect(HealthController.lockoutAfter(4), Duration.zero);
      expect(HealthController.lockoutAfter(5), const Duration(seconds: 30));
      expect(HealthController.lockoutAfter(6), const Duration(minutes: 1));
      expect(HealthController.lockoutAfter(7), const Duration(minutes: 2));
      expect(HealthController.lockoutAfter(9), const Duration(minutes: 8));
      expect(HealthController.lockoutAfter(10), const Duration(minutes: 15));
      expect(HealthController.lockoutAfter(400), const Duration(minutes: 15));
    });

    test('a clock set backward cannot stretch the wait past the cap', () async {
      for (var i = 0; i < 5; i++) {
        await health.tryUnlock('0000');
      }
      clock.now = clock.now.subtract(const Duration(days: 365));
      expect(health.pinLockoutRemaining, HealthController.maxPinLockout);
    });

    test('a fingerprint unlock clears the miss count', () async {
      final bio = HealthController(
        store,
        clock: clock.call,
        biometrics: _YesBiometric(),
      );
      await bio.load();
      for (var i = 0; i < 3; i++) {
        await bio.tryUnlock('0000');
      }
      expect(await bio.enableBiometricUnlock(), isTrue);
      bio.lock();
      expect(await bio.unlockWithBiometric(), BiometricResult.success);
      expect((await store.read()).pinFailures, 0);
    });
  });

  test('H5 a PIN from an older build opens once and is re-saved', () async {
    final store = InMemoryHealthStore();
    await store.write(
      HealthSnapshot(initialized: true, pinHash: PinHasher.legacyHash('2580')),
    );
    final health = HealthController(store);
    await health.load();
    expect(health.isUnlocked, isFalse);
    expect(await health.unlock('1111'), isFalse);
    expect((await store.read()).pinHash, PinHasher.legacyHash('2580'));

    expect(await health.unlock('2580'), isTrue);
    final upgraded = (await store.read()).pinHash!;
    expect(upgraded, startsWith(r'pbkdf2-sha256$'));

    final again = HealthController(store);
    await again.load();
    expect(await again.unlock('2580'), isTrue);
  });

  group('H5 auto-lock after the app is in the background', () {
    late _Clock clock;
    late HealthController health;

    Future<void> pumpLock(WidgetTester tester) async {
      clock = _Clock();
      health = HealthController(InMemoryHealthStore());
      await health.load();
      await health.setPin('1234');
      expect(health.isUnlocked, isTrue);
      await tester.pumpWidget(
        HealthAutoLock(
          controller: health,
          clock: clock.call,
          child: const SizedBox(),
        ),
      );
    }

    void lifecycle(WidgetTester tester, List<AppLifecycleState> states) {
      for (final state in states) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
    }

    const away = [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ];
    const back = [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ];

    testWidgets('a quick trip away keeps My Health open', (tester) async {
      await pumpLock(tester);
      lifecycle(tester, away);
      clock.now = clock.now.add(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 10));
      lifecycle(tester, back);
      expect(health.isUnlocked, isTrue);
    });

    testWidgets('30 seconds away locks it, checked on return', (tester) async {
      await pumpLock(tester);
      lifecycle(tester, away);
      // The phone froze timers, so only the clock moved.
      clock.now = clock.now.add(const Duration(minutes: 5));
      lifecycle(tester, back);
      expect(health.isUnlocked, isFalse);
    });

    testWidgets('the timer locks it while still away', (tester) async {
      await pumpLock(tester);
      lifecycle(tester, away);
      await tester.pump(HealthAutoLock.defaultGrace);
      expect(health.isUnlocked, isFalse);
    });

    testWidgets('the app switcher alone does not lock', (tester) async {
      await pumpLock(tester);
      lifecycle(tester, const [AppLifecycleState.inactive]);
      await tester.pump(const Duration(minutes: 2));
      lifecycle(tester, const [AppLifecycleState.resumed]);
      expect(health.isUnlocked, isTrue);
    });
  });

  test('H5 wait wording rounds up and never says zero', () {
    expect(describePinWait(const Duration(milliseconds: 200)), '1 second');
    expect(describePinWait(const Duration(seconds: 30)), '30 seconds');
    expect(describePinWait(const Duration(seconds: 61)), '2 minutes');
    expect(describePinWait(const Duration(minutes: 15)), '15 minutes');
  });
}
