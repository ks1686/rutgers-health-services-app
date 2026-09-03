import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/nearby/data/nearby_cache.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_config.dart';
import 'package:cwc_health_app/features/nearby/data/device_location.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_errors.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_fetch_result.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_query.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_repository.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_resource.dart';
import 'package:cwc_health_app/features/nearby/data/sources/geo_point.dart';
import 'package:cwc_health_app/features/nearby/data/sources/google_places_source.dart';
import 'package:cwc_health_app/features/nearby/data/sources/nominatim_geocode.dart';
import 'package:cwc_health_app/features/nearby/data/sources/osm_overpass_source.dart';

class _FakeGeocode implements NominatimGeocode {
  _FakeGeocode({this.result, this.error});

  final GeoPoint? result;
  final Object? error;
  int calls = 0;

  @override
  String get userAgent => 'fake';

  @override
  String get baseUrl => 'https://example.invalid';

  @override
  Duration get requestTimeout => const Duration(seconds: 1);

  @override
  Duration get retryBackoff => Duration.zero;

  @override
  Future<GeoPoint> geocode(NearbyQuery query) async {
    calls++;
    if (error != null) throw error!;
    return result!;
  }
}

class _FakeGoogle implements GooglePlacesSource {
  _FakeGoogle(this.outcome);

  final GooglePlacesOutcome outcome;
  int calls = 0;

  @override
  String get apiKey => 'fake';

  @override
  String get endpoint => 'https://example.invalid';

  @override
  int get radiusMeters => 4000;

  @override
  Duration get requestTimeout => const Duration(seconds: 1);

  @override
  Future<GooglePlacesOutcome> fetch(
    GeoPoint area, {
    DateTime? fetchedAt,
  }) async {
    calls++;
    return outcome;
  }
}

class _FakeOverpass implements OsmOverpassSource {
  _FakeOverpass({this.result, this.error});

  final List<NearbyResource>? result;
  final Object? error;
  int calls = 0;
  int aroundCalls = 0;
  bool? lastAroundGuard;

  @override
  String get userAgent => 'fake';

  @override
  List<String> get endpoints => const ['https://example.invalid'];

  @override
  int get attemptsPerEndpoint => 1;

  @override
  Duration get retryBackoff => Duration.zero;

  @override
  Duration get requestTimeout => const Duration(seconds: 1);

  @override
  Future<List<NearbyResource>> fetch(
    GeoPoint area, {
    DateTime? fetchedAt,
  }) async {
    calls++;
    if (error != null) throw error!;
    return result!;
  }

  @override
  Future<List<NearbyResource>> fetchAround(
    GeoPoint origin, {
    DateTime? fetchedAt,
    bool applyRegionGuard = true,
  }) async {
    aroundCalls++;
    lastAroundGuard = applyRegionGuard;
    if (error != null) throw error!;
    return result!;
  }
}

NearbyResource _resource({
  required String id,
  required String name,
  String category = 'Pharmacy',
  String source = 'osm',
  double lat = 40.4862,
  double lng = -74.4518,
  DateTime? fetchedAt,
}) {
  return NearbyResource(
    id: id,
    name: name,
    category: category,
    address: '1 Test St, New Brunswick, NJ',
    lat: lat,
    lng: lng,
    openingHoursRaw: null,
    source: source,
    fetchedAt: fetchedAt ?? DateTime.utc(2026, 8, 12),
  );
}

void main() {
  const query = NearbyQuery();
  const area = GeoPoint(lat: 40.4862, lng: -74.4518);
  final now = DateTime.utc(2026, 8, 12, 20);

  const liveConfig = NearbyConfig(liveNearby: true, googlePlacesApiKey: 'k');

  NearbyRepository build({
    required _FakeGeocode geocode,
    required _FakeGoogle google,
    required _FakeOverpass overpass,
    DeviceLocationSource? deviceLocation,
    NearbyCache? cache,
  }) {
    return NearbyRepository(
      config: liveConfig,
      geocoder: geocode,
      googlePlaces: google,
      overpass: overpass,
      deviceLocation: deviceLocation,
      cache: cache,
      clock: () => now,
    );
  }

  test('google results win and skip OSM', () async {
    final overpass = _FakeOverpass(result: const []);
    final repo = build(
      geocode: _FakeGeocode(result: area),
      google: _FakeGoogle(
        GooglePlacesOk([
          _resource(id: 'g1', name: 'Google Pharmacy', source: 'google'),
        ]),
      ),
      overpass: overpass,
    );

    final result = await repo.fetch(query);

    expect(result.status, NearbySourceStatus.google);
    expect(result.resources.single.name, 'Google Pharmacy');
    expect(overpass.calls, 0);
  });

  test('google soft-fail uses OSM results', () async {
    final google = _FakeGoogle(GooglePlacesSoftFail('missing_key'));
    final repo = build(
      geocode: _FakeGeocode(result: area),
      google: google,
      overpass: _FakeOverpass(
        result: [_resource(id: 'o1', name: 'Main Street Pharmacy')],
      ),
    );

    final result = await repo.fetch(query);

    expect(google.calls, 1);
    expect(result.status, NearbySourceStatus.osm);
    expect(result.resources.single.name, 'Main Street Pharmacy');
  });

  test('google ok but empty still falls through to OSM', () async {
    final overpass = _FakeOverpass(
      result: [_resource(id: 'o1', name: 'Community Health Clinic')],
    );
    final repo = build(
      geocode: _FakeGeocode(result: area),
      google: _FakeGoogle(GooglePlacesOk(const [])),
      overpass: overpass,
    );

    final result = await repo.fetch(query);

    expect(overpass.calls, 1);
    expect(result.status, NearbySourceStatus.osm);
  });

  test(
    'both fail with cache returns cache status and original timestamp',
    () async {
      final cache = InMemoryNearbyCache();
      final cachedAt = DateTime.utc(2026, 8, 11, 9);
      await cache.write(
        query,
        NearbyFetchResult(
          resources: [
            _resource(id: 'c1', name: 'Cached Pharmacy', fetchedAt: cachedAt),
          ],
          status: NearbySourceStatus.osm,
          fetchedAt: cachedAt,
        ),
      );

      final repo = build(
        geocode: _FakeGeocode(result: area),
        google: _FakeGoogle(GooglePlacesSoftFail('403')),
        overpass: _FakeOverpass(error: OsmOverpassException('HTTP 503')),
        cache: cache,
      );

      final result = await repo.fetch(query);

      expect(result.status, NearbySourceStatus.cache);
      expect(result.resources.single.name, 'Cached Pharmacy');
      expect(result.fetchedAt, cachedAt);
    },
  );

  test('both fail without cache returns unavailable', () async {
    final repo = build(
      geocode: _FakeGeocode(result: area),
      google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
      overpass: _FakeOverpass(error: OsmOverpassException('HTTP 503')),
      cache: InMemoryNearbyCache(),
    );

    final result = await repo.fetch(query);

    expect(result.status, NearbySourceStatus.unavailable);
    expect(result.resources, isEmpty);
    expect(result.message, isNotNull);
  });

  test('never returns demo rows when live sources fail', () async {
    final repo = build(
      geocode: _FakeGeocode(error: NominatimException('no results')),
      google: _FakeGoogle(GooglePlacesOk(const [])),
      overpass: _FakeOverpass(result: const []),
    );

    final result = await repo.fetch(query);

    expect(result.status, NearbySourceStatus.unavailable);
    expect(result.resources, isEmpty);
  });

  test('geocode failure uses the member-safe lookup sentence', () async {
    final repo = build(
      geocode: _FakeGeocode(error: Exception('HTTP 502: <html>overpass')),
      google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
      overpass: _FakeOverpass(result: const []),
    );

    final result = await repo.fetch(query);

    expect(result.status, NearbySourceStatus.unavailable);
    expect(result.message, kNearbyMemberLookupFailed);
    expect(result.message, isNot(contains('HTTP')));
    expect(result.message, isNot(contains('html')));
  });

  test('overpass failure uses the member-safe load sentence', () async {
    final repo = build(
      geocode: _FakeGeocode(result: area),
      google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
      overpass: _FakeOverpass(
        error: Exception('All 3 Overpass endpoints failed'),
      ),
    );

    final result = await repo.fetch(query);

    expect(result.status, NearbySourceStatus.unavailable);
    expect(result.message, kNearbyMemberLoadFailed);
    expect(result.message, isNot(contains('Overpass')));
  });

  test('geocode failure with cached point still queries Overpass', () async {
    final cache = InMemoryNearbyCache();
    await cache.writePoint(query, area);
    final overpass = _FakeOverpass(
      result: [_resource(id: 'o1', name: 'From cache point')],
    );
    final repo = build(
      geocode: _FakeGeocode(error: Exception('down')),
      google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
      overpass: overpass,
      cache: cache,
    );
    final result = await repo.fetch(query);
    expect(overpass.calls, 1);
    expect(result.status, NearbySourceStatus.osm);
    expect(result.resources.single.name, 'From cache point');
  });

  test('geocode failure falls back to cache when available', () async {
    final cache = InMemoryNearbyCache();
    final cachedAt = DateTime.utc(2026, 8, 10, 12);
    await cache.write(
      query,
      NearbyFetchResult(
        resources: [_resource(id: 'c1', name: 'Cached Clinic')],
        status: NearbySourceStatus.osm,
        fetchedAt: cachedAt,
      ),
    );

    final google = _FakeGoogle(GooglePlacesOk(const []));
    final repo = build(
      geocode: _FakeGeocode(error: NominatimException('no results')),
      google: google,
      overpass: _FakeOverpass(result: const []),
      cache: cache,
    );

    final result = await repo.fetch(query);

    expect(google.calls, 0);
    expect(result.status, NearbySourceStatus.cache);
    expect(result.resources.single.name, 'Cached Clinic');
  });

  test('dedupes same name within 50 m and keeps the first row', () async {
    final repo = build(
      geocode: _FakeGeocode(result: area),
      google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
      overpass: _FakeOverpass(
        result: [
          _resource(
            id: 'node-1',
            name: 'Main Street Pharmacy',
            lat: 40.4862,
            lng: -74.4518,
          ),
          _resource(
            id: 'way-1',
            name: 'main street pharmacy',
            lat: 40.48622,
            lng: -74.45182,
          ),
          _resource(
            id: 'node-2',
            name: 'Main Street Pharmacy',
            lat: 40.4990,
            lng: -74.4600,
          ),
        ],
      ),
    );

    final result = await repo.fetch(query);

    expect(result.resources, hasLength(2));
    expect(result.resources.first.id, 'node-1');
    expect(result.resources.last.id, 'node-2');
  });

  test('stamps a single fetch timestamp on every row', () async {
    final repo = build(
      geocode: _FakeGeocode(result: area),
      google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
      overpass: _FakeOverpass(
        result: [
          _resource(
            id: 'o1',
            name: 'A Pharmacy',
            fetchedAt: DateTime.utc(2020),
          ),
          _resource(id: 'o2', name: 'B Clinic', fetchedAt: DateTime.utc(2021)),
        ],
      ),
    );

    final result = await repo.fetch(query);

    expect(result.fetchedAt, now);
    expect(result.resources.map((r) => r.fetchedAt), everyElement(now));
  });

  test('successful fetch writes through to cache', () async {
    final cache = InMemoryNearbyCache();
    final repo = build(
      geocode: _FakeGeocode(result: area),
      google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
      overpass: _FakeOverpass(
        result: [_resource(id: 'o1', name: 'Main Street Pharmacy')],
      ),
      cache: cache,
    );

    await repo.fetch(query);
    final cached = await cache.read(query);

    expect(cached, isNotNull);
    expect(cached!.resources.single.name, 'Main Street Pharmacy');
  });

  test('cache is scoped per town', () async {
    final cache = InMemoryNearbyCache();
    await cache.write(
      const NearbyQuery(town: 'Trenton'),
      NearbyFetchResult(
        resources: [_resource(id: 't1', name: 'Trenton Pharmacy')],
        status: NearbySourceStatus.osm,
        fetchedAt: now,
      ),
    );

    expect(await cache.read(const NearbyQuery(town: 'New Brunswick')), isNull);
    expect(await cache.read(const NearbyQuery(town: 'trenton')), isNotNull);
  });

  test('device fix centers an around-search and skips the NJ guard', () async {
    const devicePoint = GeoPoint(lat: 40.52, lng: -74.47);
    final overpass = _FakeOverpass(
      result: [_resource(id: 'o1', name: 'Corner Pharmacy')],
    );
    final repo = build(
      geocode: _FakeGeocode(result: area),
      google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
      overpass: overpass,
      deviceLocation: _ScriptedLocation(DeviceLocationOk(devicePoint)),
    );

    final result = await repo.fetchNearDevice(query);

    expect(overpass.calls, 0);
    expect(overpass.aroundCalls, 1);
    // A member can travel out of state; the device path must not drop rows.
    expect(overpass.lastAroundGuard, isFalse);
    expect(result.status, NearbySourceStatus.osm);
    expect(result.resources.single.name, 'Corner Pharmacy');
    expect(result.origin, devicePoint);
  });

  test('device results are sorted nearest-first by straight-line distance', () async {
    const devicePoint = GeoPoint(lat: 40.4862, lng: -74.4518);
    final overpass = _FakeOverpass(
      result: [
        _resource(
          id: 'far',
          name: 'Far Clinic',
          lat: 40.52,
          lng: -74.47,
        ),
        _resource(
          id: 'near',
          name: 'Near Pharmacy',
          lat: 40.4870,
          lng: -74.4518,
        ),
        _resource(
          id: 'mid',
          name: 'Mid Urgent Care',
          lat: 40.50,
          lng: -74.46,
        ),
      ],
    );
    final repo = build(
      geocode: _FakeGeocode(result: area),
      google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
      overpass: overpass,
      deviceLocation: _ScriptedLocation(DeviceLocationOk(devicePoint)),
    );

    final result = await repo.fetchNearDevice(query);

    expect(
      result.resources.map((r) => r.name).toList(),
      ['Near Pharmacy', 'Mid Urgent Care', 'Far Clinic'],
    );
  });

  test('device lookup never writes coordinates or results to cache', () async {
    final cache = InMemoryNearbyCache();
    final repo = build(
      geocode: _FakeGeocode(result: area, error: null),
      google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
      overpass: _FakeOverpass(
        result: [_resource(id: 'o1', name: 'Corner Pharmacy')],
      ),
      deviceLocation: _ScriptedLocation(
        DeviceLocationOk(const GeoPoint(lat: 40.52, lng: -74.47)),
      ),
      cache: cache,
    );

    await repo.fetchNearDevice(query);

    expect(await cache.read(query), isNull);
    expect(await cache.readPoint(query), isNull);
  });

  test('permission denial falls back to the town list with a reason', () async {
    final geocode = _FakeGeocode(result: area);
    final overpass = _FakeOverpass(
      result: [_resource(id: 'o1', name: 'Town Pharmacy')],
    );
    final repo = build(
      geocode: geocode,
      google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
      overpass: overpass,
      deviceLocation: _ScriptedLocation(
        DeviceLocationSoftFail(DeviceLocationFailure.permissionDenied),
      ),
    );

    final result = await repo.fetchNearDevice(query);

    expect(overpass.aroundCalls, 0);
    expect(geocode.calls, 1);
    expect(result.status, NearbySourceStatus.osm);
    expect(result.resources.single.name, 'Town Pharmacy');
    expect(result.message, kNearbyLocationDenied);
    expect(result.origin, isNull);
  });

  test('service disabled falls back with the location-off sentence', () async {
    final repo = build(
      geocode: _FakeGeocode(result: area),
      google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
      overpass: _FakeOverpass(
        result: [_resource(id: 'o1', name: 'Town Pharmacy')],
      ),
      deviceLocation: _ScriptedLocation(
        DeviceLocationSoftFail(DeviceLocationFailure.serviceDisabled),
      ),
    );

    final result = await repo.fetchNearDevice(query);

    expect(result.status, NearbySourceStatus.osm);
    expect(result.message, kNearbyLocationOff);
  });

  test('location timeout falls back instead of erroring the tab', () async {
    final repo = build(
      geocode: _FakeGeocode(result: area),
      google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
      overpass: _FakeOverpass(
        result: [_resource(id: 'o1', name: 'Town Pharmacy')],
      ),
      deviceLocation: _ScriptedLocation(
        DeviceLocationSoftFail(DeviceLocationFailure.unavailable),
      ),
    );

    final result = await repo.fetchNearDevice(query);

    expect(result.status, NearbySourceStatus.osm);
    expect(result.message, kNearbyLocationUnavailable);
  });

  test(
    'no injected device source returns unavailable without crashing',
    () async {
      final repo = build(
        geocode: _FakeGeocode(result: area),
        google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
        overpass: _FakeOverpass(result: const []),
        deviceLocation: null,
      );

      final result = await repo.fetchNearDevice(query);

      expect(result.status, NearbySourceStatus.unavailable);
      expect(result.resources, isEmpty);
    },
  );
}

/// Minimal scripted device-location source for repository tests.
class _ScriptedLocation implements DeviceLocationSource {
  _ScriptedLocation(this.outcome);

  final DeviceLocationOutcome outcome;

  @override
  Future<DeviceLocationOutcome> getCurrent() async => outcome;
}
