import 'dart:convert';

import 'health_models.dart';
import 'health_store.dart';
import 'secure_string_store.dart';

/// Parses a saved My Health record. Returns null for anything this build
/// cannot read: bad JSON, a wrong shape, or a field of the wrong type.
HealthSnapshot? decodeHealthSnapshot(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return HealthSnapshot.fromJson(Map<String, dynamic>.from(decoded));
  } catch (_) {
    return null;
  }
}

/// Thrown by [SecureHealthStore.read] when a saved record exists but this
/// build cannot read it. The controller then treats My Health as
/// unavailable: it keeps the PIN wall up and never writes over the record.
class UnreadableHealthRecord implements Exception {
  const UnreadableHealthRecord();

  @override
  String toString() => 'The saved My Health record could not be read.';
}

/// Encrypted-at-rest My Health snapshot (PRIV-4) via [SecureStringStore].
class SecureHealthStore implements HealthStore {
  SecureHealthStore(this._secure);

  final SecureStringStore _secure;

  static const dataKey = 'health.v1.snapshot';

  /// The first saved record this build could not read is copied here. A
  /// later bad read never replaces it. Erase removes it.
  static const unreadableKey = 'health.v1.snapshot.unreadable';

  @override
  Future<HealthSnapshot> read() async {
    final raw = await _secure.read(dataKey);
    if (raw == null || raw.isEmpty) return const HealthSnapshot();
    final snapshot = decodeHealthSnapshot(raw);
    if (snapshot == null) {
      final kept = await _secure.read(unreadableKey);
      if (kept == null || kept.isEmpty) {
        await _secure.write(unreadableKey, raw);
      }
      throw const UnreadableHealthRecord();
    }
    return snapshot;
  }

  @override
  Future<void> write(HealthSnapshot snapshot) async {
    await _secure.write(dataKey, jsonEncode(snapshot.toJson()));
  }

  @override
  Future<void> erase() async {
    // Backup first. If that fails the live record is still untouched, so
    // the controller never keeps records on screen that were already wiped.
    await _secure.delete(unreadableKey);
    await write(const HealthSnapshot(initialized: true));
  }
}
