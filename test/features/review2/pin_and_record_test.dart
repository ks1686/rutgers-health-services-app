import 'dart:convert';

import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_models.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:cwc_health_app/features/my_health/data/health_store_factory.dart';
import 'package:cwc_health_app/features/my_health/data/pin_hasher.dart';
import 'package:cwc_health_app/features/my_health/data/prefs_health_store.dart';
import 'package:cwc_health_app/features/my_health/data/secure_health_store.dart';
import 'package:cwc_health_app/features/my_health/data/secure_string_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/failing_stores.dart';

/// Verifies slowly, like the real 100k-iteration hash on a phone, so tries
/// that start together are all in flight at once.
class _SlowHasher extends PinHasher {
  _SlowHasher() : super(iterations: 1000, runInBackground: false);

  @override
  Future<bool> verify(String pin, String stored) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return super.verify(pin, stored);
  }
}

/// A secure string store whose delete can be told to fail.
class _FlakyDeleteStrings extends MemorySecureStringStore {
  bool failDeletes = false;

  @override
  Future<void> delete(String key) async {
    if (failDeletes) throw StateError('keystore busy');
    await super.delete(key);
  }
}

void main() {
  group('N2 an unreadable saved record', () {
    const bad = '{"initialized": true, "pinHash": 42, "appointments": "x"}';

    test('keeps the PIN wall: nothing is shown, nothing is written', () async {
      final secure = MemorySecureStringStore();
      await secure.write(SecureHealthStore.dataKey, bad);
      final health = HealthController(SecureHealthStore(secure));
      await health.load();

      expect(health.storageUnavailable, isTrue);
      expect(await secure.read(SecureHealthStore.dataKey), bad);
      expect(await secure.read(SecureHealthStore.unreadableKey), bad);
      expect(await health.setPin('1234'), isFalse);
      expect(await secure.read(SecureHealthStore.dataKey), bad);
    });

    test('a second bad read never replaces the first backup', () async {
      final secure = MemorySecureStringStore();
      await secure.write(SecureHealthStore.dataKey, bad);
      await HealthController(SecureHealthStore(secure)).load();
      await secure.write(SecureHealthStore.dataKey, 'not json at all');
      await HealthController(SecureHealthStore(secure)).load();
      expect(await secure.read(SecureHealthStore.unreadableKey), bad);
    });

    test('Erase still starts over from an unreadable record', () async {
      final secure = MemorySecureStringStore();
      await secure.write(SecureHealthStore.dataKey, bad);
      final health = HealthController(SecureHealthStore(secure));
      await health.load();
      expect(await health.eraseAll(), isTrue);
      expect(health.storageUnavailable, isFalse);
      expect(await secure.read(SecureHealthStore.unreadableKey), isNull);
      expect(await health.setPin('1234'), isTrue);
    });

    test('a failed backup delete leaves the live record untouched', () async {
      final secure = _FlakyDeleteStrings();
      final store = SecureHealthStore(secure);
      final sample = HealthSnapshot(
        initialized: true,
        medications: [
          HealthMedication(id: 'm', name: 'Kept', purpose: '', schedule: ''),
        ],
      );
      await store.write(sample);
      secure.failDeletes = true;
      await expectLater(store.erase(), throwsA(isA<StateError>()));
      expect((await store.read()).medications.single.name, 'Kept');
    });
  });

  group('N3 PIN tries that run at the same time', () {
    late HealthController health;

    setUp(() async {
      health = HealthController(
        InMemoryHealthStore(),
        pinHasher: _SlowHasher(),
      );
      await health.load();
      await health.setPin('1234');
      health.lock();
    });

    test('ten wrong tries at once still stop at five', () async {
      final results = await Future.wait([
        for (var i = 0; i < 10; i++) health.tryUnlock('0000'),
      ]);
      expect(results.where((r) => r == PinCheck.wrong), hasLength(5));
      expect(results.where((r) => r == PinCheck.lockedOut), hasLength(5));
      expect(health.snapshot.pinFailures, 5);
    });

    test('a right PIN queued behind the fifth miss waits it out', () async {
      final misses = [for (var i = 0; i < 5; i++) health.tryUnlock('0000')];
      final right = health.tryUnlock('1234');
      await Future.wait(misses);
      expect(await right, PinCheck.lockedOut);
      expect(health.isUnlocked, isFalse);
    });

    test('pinCheckBusy is true only while a check runs', () async {
      expect(health.pinCheckBusy, isFalse);
      final check = health.tryUnlock('0000');
      expect(health.pinCheckBusy, isTrue);
      await check;
      expect(health.pinCheckBusy, isFalse);
    });
  });

  test('a miss that cannot be saved still counts (fails closed)', () async {
    final store = FlakyHealthStore();
    final health = HealthController(store);
    await health.load();
    await health.setPin('1234');
    health.lock();
    store.failWrites = true;
    expect(await health.tryUnlock('0000'), PinCheck.wrong);
    expect(health.pinLockoutRemaining, greaterThan(Duration.zero));
    expect(await health.tryUnlock('1234'), PinCheck.lockedOut);
    expect(health.isUnlocked, isFalse);
  });

  // The clock-set-back case is in test/features/review3/pin_lockout_test.dart.

  group('legacy plaintext migration', () {
    final legacy = HealthSnapshot(
      initialized: true,
      medications: [
        HealthMedication(id: 'm', name: 'Legacy', purpose: '', schedule: ''),
      ],
    );

    test('copies into an empty secure record made while prefs were down, '
        'then deletes', () async {
      SharedPreferences.setMockInitialValues({
        PrefsHealthStore.dataKey: jsonEncode(legacy.toJson()),
      });
      final prefs = await SharedPreferences.getInstance();
      final secure = SecureHealthStore(MemorySecureStringStore());
      // First launch: prefs failed, so load() created an empty record.
      await secure.write(const HealthSnapshot(initialized: true));

      await HealthStoreFactory.migrateLegacyPrefsIfNeeded(
        secure: secure,
        prefs: prefs,
      );
      expect((await secure.read()).medications.single.name, 'Legacy');
      expect(prefs.getString(PrefsHealthStore.dataKey), isNull);
    });

    test(
      'keeps the plaintext copy if the secure record is unreadable',
      () async {
        SharedPreferences.setMockInitialValues({
          PrefsHealthStore.dataKey: jsonEncode(legacy.toJson()),
        });
        final prefs = await SharedPreferences.getInstance();
        final strings = MemorySecureStringStore();
        await strings.write(SecureHealthStore.dataKey, '{broken');
        await HealthStoreFactory.migrateLegacyPrefsIfNeeded(
          secure: SecureHealthStore(strings),
          prefs: prefs,
        );
        expect(prefs.getString(PrefsHealthStore.dataKey), isNotNull);
      },
    );
  });
}
