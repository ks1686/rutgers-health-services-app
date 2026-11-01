import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _Clock {
  DateTime now = DateTime.utc(2026, 11, 2, 9);
  DateTime call() => now;
}

void main() {
  const pastCap = Duration(minutes: 15, seconds: 1);

  test('reading the wait changes nothing; the next try pulls a backward '
      'clock deadline in to the cap', () async {
    final clock = _Clock();
    final health = HealthController(InMemoryHealthStore(), clock: clock.call);
    await health.load();
    await health.setPin('1234');
    health.lock();
    for (var i = 0; i < 5; i++) {
      await health.tryUnlock('0000');
    }
    clock.now = clock.now.subtract(const Duration(days: 365));
    var notified = 0;
    health.addListener(() => notified++);

    expect(health.pinLockoutRemaining, HealthController.maxPinLockout);
    clock.now = clock.now.add(pastCap);
    expect(
      health.pinLockoutRemaining,
      HealthController.maxPinLockout,
      reason: 'a getter does not move the deadline',
    );
    expect(notified, 0);

    expect(await health.tryUnlock('1234'), PinCheck.lockedOut);
    clock.now = clock.now.add(pastCap);
    expect(health.pinLockoutRemaining, Duration.zero);
    expect(await health.tryUnlock('1234'), PinCheck.unlocked);
  });

  test('load pulls a saved deadline past the cap in to the cap', () async {
    final clock = _Clock();
    final store = InMemoryHealthStore();
    final first = HealthController(store, clock: clock.call);
    await first.load();
    await first.setPin('1234');
    final saved = await store.read();
    await store.write(
      saved.copyWith(
        pinFailures: 5,
        pinLockedUntil: clock.now.add(const Duration(days: 365)),
      ),
    );

    final health = HealthController(store, clock: clock.call);
    await health.load();
    clock.now = clock.now.add(pastCap);

    expect(health.pinLockoutRemaining, Duration.zero);
    expect(await health.tryUnlock('1234'), PinCheck.unlocked);
  });
}
