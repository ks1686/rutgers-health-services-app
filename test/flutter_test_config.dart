import 'dart:async';

import 'package:cwc_health_app/features/my_health/data/pin_hasher.dart';

/// Runs before every test file. Real PIN hashing takes 100,000 rounds on a
/// background isolate, which widget tests cannot wait for. Tests use a few
/// rounds on the same thread. pin_hasher_test.dart checks the real settings.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PinHasher.standard = const PinHasher(
    iterations: 1000,
    runInBackground: false,
  );
  await testMain();
}
