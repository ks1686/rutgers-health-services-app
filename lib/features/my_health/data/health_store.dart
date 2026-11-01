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

/// Stands in when the phone's secure storage cannot be opened. Every call
/// fails, so the controller shows My Health as unavailable and saves nothing.
class UnavailableHealthStore implements HealthStore {
  const UnavailableHealthStore();

  @override
  Future<HealthSnapshot> read() =>
      Future.error(StateError('My Health storage is unavailable.'));

  @override
  Future<void> write(HealthSnapshot snapshot) =>
      Future.error(StateError('My Health storage is unavailable.'));

  @override
  Future<void> erase() =>
      Future.error(StateError('My Health storage is unavailable.'));
}
