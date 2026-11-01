import 'package:flutter/widgets.dart';

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

/// Counts Erase my information runs. A lookup that started before an erase
/// must not save its town point or results afterward, or the erased data
/// would come back after Erase said it was gone.
///
/// The app makes one and shares it through [NearbyEraseEpochScope]; the
/// Nearby repository reads it and Erase bumps it.
class NearbyEraseEpoch {
  int _value = 0;

  int get value => _value;

  /// Call before removing saved keys, so lookups already running stop saving.
  void bump() => _value++;
}

/// Shares the app's [NearbyEraseEpoch] with Nearby and More.
class NearbyEraseEpochScope extends InheritedWidget {
  const NearbyEraseEpochScope({
    super.key,
    required this.epoch,
    required super.child,
  });

  final NearbyEraseEpoch epoch;

  /// Reads without listening, so it is safe from initState and callbacks.
  static NearbyEraseEpoch? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<NearbyEraseEpochScope>()?.epoch;

  @override
  bool updateShouldNotify(NearbyEraseEpochScope oldWidget) =>
      epoch != oldWidget.epoch;
}

/// Shared cache key. Prefs and the in-memory cache must stay on the same shape.
String nearbyCacheKey(NearbyQuery query) =>
    '${query.town.trim().toLowerCase()}|${query.stateCode.trim().toUpperCase()}';

/// Process-lifetime cache. Survives tab switches, not app restarts.
///
/// App code uses [PrefsNearbyCache]; this class stays for tests and as a
/// process-lifetime fallback.
class InMemoryNearbyCache implements NearbyCache {
  final Map<String, NearbyFetchResult> _entries = {};
  final Map<String, GeoPoint> _points = {};

  @override
  Future<NearbyFetchResult?> read(NearbyQuery query) async {
    return _entries[nearbyCacheKey(query)];
  }

  @override
  Future<void> write(NearbyQuery query, NearbyFetchResult result) async {
    _entries[nearbyCacheKey(query)] = result;
  }

  @override
  Future<GeoPoint?> readPoint(NearbyQuery query) async {
    return _points[nearbyCacheKey(query)];
  }

  @override
  Future<void> writePoint(NearbyQuery query, GeoPoint point) async {
    _points[nearbyCacheKey(query)] = point;
  }
}
