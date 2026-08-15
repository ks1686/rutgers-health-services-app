import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'nearby_cache.dart';
import 'nearby_fetch_result.dart';
import 'nearby_query.dart';
import 'sources/geo_point.dart';

/// On-device last-success list + geocode point. No identity, no GPS.
class PrefsNearbyCache implements NearbyCache {
  PrefsNearbyCache(this._prefs);

  final SharedPreferences _prefs;

  static String resultKey(NearbyQuery query) =>
      'nearby.v1.result.${InMemoryNearbyCache.keyFor(query)}';

  static String pointKey(NearbyQuery query) =>
      'nearby.v1.point.${InMemoryNearbyCache.keyFor(query)}';

  @override
  Future<NearbyFetchResult?> read(NearbyQuery query) async {
    final raw = _prefs.getString(resultKey(query));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return NearbyFetchResult.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(NearbyQuery query, NearbyFetchResult result) async {
    await _prefs.setString(resultKey(query), jsonEncode(result.toJson()));
  }

  @override
  Future<GeoPoint?> readPoint(NearbyQuery query) async {
    final raw = _prefs.getString(pointKey(query));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return GeoPoint.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> writePoint(NearbyQuery query, GeoPoint point) async {
    await _prefs.setString(pointKey(query), jsonEncode(point.toJson()));
  }
}
