import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'health_models.dart';
import 'health_store.dart';

/// JSON blob in SharedPreferences. Study-build web demo path; not a cloud sync.
class PrefsHealthStore implements HealthStore {
  PrefsHealthStore(this._prefs);

  final SharedPreferences _prefs;

  static const dataKey = 'health.v1.snapshot';

  @override
  Future<HealthSnapshot> read() async {
    final raw = _prefs.getString(dataKey);
    if (raw == null) return const HealthSnapshot();
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
    await _prefs.setString(dataKey, jsonEncode(snapshot.toJson()));
  }

  @override
  Future<void> erase() async {
    await write(const HealthSnapshot(initialized: true));
  }
}
