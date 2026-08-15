import 'nearby_fetch_result.dart';
import 'nearby_query.dart';
import 'sources/geo_point.dart';

/// Last-successful live payload per town, so a dropped connection shows stale
/// results instead of an empty screen.
///
/// On-device only: no identity, no query history, nothing leaves the phone.
abstract class NearbyCache {
  Future<NearbyFetchResult?> read(NearbyQuery query);

  Future<void> write(NearbyQuery query, NearbyFetchResult result);

  Future<GeoPoint?> readPoint(NearbyQuery query);

  Future<void> writePoint(NearbyQuery query, GeoPoint point);
}

/// Process-lifetime cache. Survives tab switches, not app restarts.
///
/// A `shared_preferences` implementation can replace this behind [NearbyCache]
/// without touching the repository.
class InMemoryNearbyCache implements NearbyCache {
  final Map<String, NearbyFetchResult> _entries = {};
  final Map<String, GeoPoint> _points = {};

  static String keyFor(NearbyQuery query) =>
      '${query.town.trim().toLowerCase()}|${query.stateCode.trim().toUpperCase()}';

  @override
  Future<NearbyFetchResult?> read(NearbyQuery query) async {
    return _entries[keyFor(query)];
  }

  @override
  Future<void> write(NearbyQuery query, NearbyFetchResult result) async {
    _entries[keyFor(query)] = result;
  }

  @override
  Future<GeoPoint?> readPoint(NearbyQuery query) async {
    return _points[keyFor(query)];
  }

  @override
  Future<void> writePoint(NearbyQuery query, GeoPoint point) async {
    _points[keyFor(query)] = point;
  }
}
