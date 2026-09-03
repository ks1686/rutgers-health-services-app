import 'dart:convert';

import 'health_models.dart';
import 'health_store.dart';
import 'secure_string_store.dart';

/// Encrypted-at-rest My Health snapshot (PRIV-4) via [SecureStringStore].
class SecureHealthStore implements HealthStore {
  SecureHealthStore(this._secure);

  final SecureStringStore _secure;

  static const dataKey = 'health.v1.snapshot';

  @override
  Future<HealthSnapshot> read() async {
    final raw = await _secure.read(dataKey);
    if (raw == null || raw.isEmpty) return const HealthSnapshot();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const HealthSnapshot();
      return HealthSnapshot.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return const HealthSnapshot();
    }
  }

  @override
  Future<void> write(HealthSnapshot snapshot) async {
    await _secure.write(dataKey, jsonEncode(snapshot.toJson()));
  }

  @override
  Future<void> erase() async {
    await write(const HealthSnapshot(initialized: true));
  }
}
