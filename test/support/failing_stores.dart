import 'package:cwc_health_app/features/my_health/data/health_models.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';

/// A store that can be told to fail writes, like a full disk or a Keystore
/// error on a real phone.
class FlakyHealthStore implements HealthStore {
  FlakyHealthStore([HealthSnapshot? initial])
    : saved = initial ?? const HealthSnapshot(initialized: true);

  HealthSnapshot saved;
  bool failWrites = false;
  int writes = 0;

  @override
  Future<HealthSnapshot> read() async => saved;

  @override
  Future<void> write(HealthSnapshot snapshot) async {
    writes++;
    if (failWrites) throw StateError('disk full');
    saved = snapshot;
  }

  @override
  Future<void> erase() async {
    if (failWrites) throw StateError('disk full');
    saved = const HealthSnapshot(initialized: true);
  }
}

/// A store whose read fails, like a Keystore that cannot be opened.
class BrokenHealthStore implements HealthStore {
  int writes = 0;

  @override
  Future<HealthSnapshot> read() async => throw StateError('keystore broken');

  @override
  Future<void> write(HealthSnapshot snapshot) async {
    writes++;
  }

  @override
  Future<void> erase() async {}
}
