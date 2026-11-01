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

/// Encrypted-at-rest My Health snapshot (PRIV-4) via [SecureStringStore].
class SecureHealthStore implements HealthStore {
  SecureHealthStore(this._secure);

  final SecureStringStore _secure;

  static const dataKey = 'health.v1.snapshot';

  /// A saved record this build could not read is copied here before the
  /// main key is reused, so a bad update never silently destroys it.
  /// Erase removes it too.
  static const unreadableKey = 'health.v1.snapshot.unreadable';

  @override
  Future<HealthSnapshot> read() async {
    final raw = await _secure.read(dataKey);
    if (raw == null || raw.isEmpty) return const HealthSnapshot();
    final snapshot = decodeHealthSnapshot(raw);
    if (snapshot == null) {
      await _secure.write(unreadableKey, raw);
      return const HealthSnapshot();
    }
    return snapshot;
  }

  @override
  Future<void> write(HealthSnapshot snapshot) async {
    await _secure.write(dataKey, jsonEncode(snapshot.toJson()));
  }

  @override
  Future<void> erase() async {
    await write(const HealthSnapshot(initialized: true));
    await _secure.delete(unreadableKey);
  }
}
