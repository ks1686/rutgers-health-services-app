import 'dart:async';

import 'package:cwc_health_app/features/my_health/data/biometric_unlock.dart';

/// Test double. Does not touch the platform channel.
class FakeBiometricAuthenticator implements BiometricAuthenticator {
  FakeBiometricAuthenticator({
    this.available = false,
    this.result = BiometricResult.success,
  });

  bool available;
  BiometricResult result;

  /// When set, [authenticate] waits on this instead of [result].
  Future<BiometricResult>? pending;

  int calls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricResult> authenticate() {
    calls += 1;
    final waiting = pending;
    if (waiting != null) return waiting;
    return Future<BiometricResult>.value(result);
  }
}
