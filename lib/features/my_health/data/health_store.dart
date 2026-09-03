import 'health_models.dart';

/// Local-only My Health persistence (PRIV-3). No cloud.
abstract class HealthStore {
  Future<HealthSnapshot> read();
  Future<void> write(HealthSnapshot snapshot);
  Future<void> erase();
}

/// In-memory store for unit / widget tests.
class InMemoryHealthStore implements HealthStore {
  HealthSnapshot _snapshot = const HealthSnapshot();

  @override
  Future<HealthSnapshot> read() async => _snapshot;

  @override
  Future<void> write(HealthSnapshot snapshot) async {
    _snapshot = snapshot;
  }

  @override
  Future<void> erase() async {
    _snapshot = const HealthSnapshot(initialized: true);
  }
}
