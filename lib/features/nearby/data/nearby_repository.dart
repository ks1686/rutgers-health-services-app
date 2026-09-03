import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'device_location.dart';
import 'nearby_cache.dart';
import 'nearby_config.dart';
import 'nearby_distance.dart';
import 'nearby_errors.dart';
import 'nearby_fetch_result.dart';
import 'nearby_query.dart';
import 'nearby_resource.dart';
import 'sources/geo_point.dart';
import 'sources/google_places_source.dart';
import 'sources/nominatim_geocode.dart';
import 'sources/osm_overpass_source.dart';

typedef Clock = DateTime Function();

/// Two rows closer than this with the same name are treated as one place.
const double kNearbyDedupeMeters = 50;

/// Orchestrates the live Nearby lookup: geocode → Google (optional) → OSM →
/// cache → unavailable.
///
/// Live mode never falls back to the static demo list; an empty or failed
/// lookup surfaces as an empty result so the UI can say so plainly.
class NearbyRepository {
  NearbyRepository({
    required this.config,
    required this.geocoder,
    required this.googlePlaces,
    required this.overpass,
    this.deviceLocation,
    this.cache,
    Clock? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  /// Wires the default source stack for app code.
  factory NearbyRepository.fromClient(
    http.Client client, {
    required NearbyConfig config,
    NearbyCache? cache,
  }) {
    return NearbyRepository(
      config: config,
      geocoder: NominatimGeocode(client),
      googlePlaces: GooglePlacesSource(
        client,
        apiKey: config.googlePlacesApiKey,
      ),
      overpass: OsmOverpassSource(client),
      deviceLocation: GeolocatorDeviceLocation(),
      cache: cache,
    );
  }

  final NearbyConfig config;
  final NominatimGeocode geocoder;
  final GooglePlacesSource googlePlaces;
  final OsmOverpassSource overpass;

  /// Null only in tests that exercise the town-only path. Production always
  /// wires a device source (mobile + web). Coordinates are used once, in
  /// memory, and never persisted or logged.
  final DeviceLocationSource? deviceLocation;
  final NearbyCache? cache;
  final Clock _clock;

  Future<NearbyFetchResult> fetch(NearbyQuery query) async {
    final when = _clock();

    GeoPoint area;
    try {
      area = await geocoder.geocode(query);
      await cache?.writePoint(query, area);
    } catch (e) {
      debugPrint('Nearby geocode failed: $e');
      final cachedPoint = await cache?.readPoint(query);
      if (cachedPoint == null) {
        return _cachedOr(query, kNearbyMemberLookupFailed);
      }
      area = cachedPoint;
    }

    final googleRows = await _tryGoogle(area, when);
    if (googleRows != null && googleRows.isNotEmpty) {
      return _store(
        query,
        NearbyFetchResult(
          resources: googleRows,
          status: NearbySourceStatus.google,
          fetchedAt: when,
        ),
      );
    }

    try {
      final osmRows = _prepare(
        await overpass.fetch(area, fetchedAt: when),
        when,
      );
      return _store(
        query,
        NearbyFetchResult(
          resources: osmRows,
          status: NearbySourceStatus.osm,
          fetchedAt: when,
          message: osmRows.isEmpty
              ? 'No pharmacies or clinics found near ${query.town}.'
              : null,
        ),
      );
    } catch (e) {
      debugPrint('Nearby Overpass failed: $e');
      return _cachedOr(query, kNearbyMemberLoadFailed);
    }
  }

  /// Live lookup centered on the member's own coordinates ("use my location").
  ///
  /// Differences from the town path, all deliberate:
  /// - the geocoder is skipped (the device is the origin);
  /// - Overpass always uses an `around` radius, never the town bounding box;
  /// - the New Jersey guardrail is bypassed — a member can travel out of
  ///   state, and a false "nothing near you" is worse than an out-of-state
  ///   row;
  /// - nothing is written to the on-device cache, so coordinates never touch
  ///   storage (IRB §7: GPS is transient, on-device only);
  /// - on failure it falls back honestly to the last saved town list, labeled
  ///   as a saved copy, rather than pretending it is device-based.
  Future<NearbyFetchResult> fetchNearDevice(NearbyQuery query) async {
    final source = deviceLocation;
    if (source == null) {
      return NearbyFetchResult(
        resources: const [],
        status: NearbySourceStatus.unavailable,
        fetchedAt: _clock(),
        message: kNearbyMemberLoadFailed,
      );
    }

    final when = _clock();
    final outcome = await source.getCurrent();

    final GeoPoint origin;
    switch (outcome) {
      case DeviceLocationOk(:final point):
        origin = point;
      case DeviceLocationSoftFail(:final reason):
        debugPrint('Nearby device location failed: ${reason.name}');
        // Every soft-fail lands the member back on the town lookup, with a
        // plain-language reason attached (rendered as an info line).
        switch (reason) {
          case DeviceLocationFailure.permissionDenied:
            return _townFallback(
              query,
              nearbyLocationDeniedMessage(query.town),
            );
          case DeviceLocationFailure.serviceDisabled:
            return _townFallback(query, nearbyLocationOffMessage(query.town));
          case DeviceLocationFailure.unavailable:
            return _townFallback(
              query,
              nearbyLocationUnavailableMessage(query.town),
            );
        }
    }

    final googleRows = await _tryGoogle(origin, when);
    if (googleRows != null && googleRows.isNotEmpty) {
      return NearbyFetchResult(
        resources: _sortedByProximity(googleRows, origin),
        status: NearbySourceStatus.google,
        fetchedAt: when,
        origin: origin,
      );
    }

    try {
      final osmRows = _prepare(
        await overpass.fetchAround(
          origin,
          fetchedAt: when,
          applyRegionGuard: false,
        ),
        when,
      );
      return NearbyFetchResult(
        resources: _sortedByProximity(osmRows, origin),
        status: NearbySourceStatus.osm,
        fetchedAt: when,
        message: osmRows.isEmpty ? kNearbyNoPlacesNearYou : null,
        origin: origin,
      );
    } catch (e) {
      debugPrint('Nearby Overpass failed (device origin): $e');
      // Same honest fallback as above — never show a device-based list that
      // is actually the saved town copy without saying so.
      return _townFallback(
        query,
        nearbyLocationUnavailableMessage(query.town),
      );
    }
  }

  /// Nearest places first so "Nearby" means proximity, not Overpass order.
  List<NearbyResource> _sortedByProximity(
    List<NearbyResource> rows,
    GeoPoint origin,
  ) {
    final sorted = List<NearbyResource>.of(rows);
    sorted.sort((a, b) {
      final da = nearbyDistanceMeters(
        fromLat: origin.lat,
        fromLng: origin.lng,
        toLat: a.lat,
        toLng: a.lng,
      );
      final db = nearbyDistanceMeters(
        fromLat: origin.lat,
        fromLng: origin.lng,
        toLat: b.lat,
        toLng: b.lng,
      );
      return da.compareTo(db);
    });
    return sorted;
  }

  /// Runs the town lookup and attaches a plain-language reason (from a failed
  /// device-location attempt) to whatever it produces. The timestamp stays the
  /// town lookup's own so "updated as of" never overstates freshness.
  Future<NearbyFetchResult> _townFallback(
    NearbyQuery query,
    String message,
  ) async {
    final result = await fetch(query);
    return NearbyFetchResult(
      resources: result.resources,
      status: result.status,
      fetchedAt: result.fetchedAt,
      message: message,
    );
  }

  /// Returns normalized rows, or null when Google was skipped or soft-failed.
  Future<List<NearbyResource>?> _tryGoogle(GeoPoint area, DateTime when) async {
    final outcome = await googlePlaces.fetch(area, fetchedAt: when);
    return switch (outcome) {
      GooglePlacesOk(:final resources) => _prepare(resources, when),
      GooglePlacesSoftFail() => null,
    };
  }

  /// Serves the last good payload for this town, keeping its original
  /// timestamp so "updated as of" never overstates how fresh the data is.
  Future<NearbyFetchResult> _cachedOr(NearbyQuery query, String message) async {
    final cached = await cache?.read(query);
    if (cached != null && cached.resources.isNotEmpty) {
      return NearbyFetchResult(
        resources: cached.resources,
        status: NearbySourceStatus.cache,
        fetchedAt: cached.fetchedAt,
        message: message,
      );
    }

    return NearbyFetchResult(
      resources: const [],
      status: NearbySourceStatus.unavailable,
      fetchedAt: _clock(),
      message: message,
    );
  }

  Future<NearbyFetchResult> _store(
    NearbyQuery query,
    NearbyFetchResult result,
  ) async {
    if (result.resources.isNotEmpty) {
      await cache?.write(query, result);
    }
    return result;
  }

  List<NearbyResource> _prepare(List<NearbyResource> rows, DateTime when) {
    final kept = <NearbyResource>[];
    for (final row in rows) {
      if (kept.any((seen) => _isSamePlace(seen, row))) continue;
      kept.add(_stamped(row, when));
    }
    return kept;
  }

  bool _isSamePlace(NearbyResource a, NearbyResource b) {
    if (a.name.trim().toLowerCase() != b.name.trim().toLowerCase()) {
      return false;
    }
    return _metersBetween(a.lat, a.lng, b.lat, b.lng) <= kNearbyDedupeMeters;
  }

  NearbyResource _stamped(NearbyResource row, DateTime when) {
    return NearbyResource(
      id: row.id,
      name: row.name,
      category: row.category,
      address: row.address,
      phone: row.phone,
      lat: row.lat,
      lng: row.lng,
      openingHoursRaw: row.openingHoursRaw,
      source: row.source,
      fetchedAt: when,
    );
  }

  double _metersBetween(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final meanLat = _toRadians((lat1 + lat2) / 2);

    // Equirectangular approximation: accurate well past the 50 m threshold.
    final x = dLng * math.cos(meanLat);
    return earthRadiusMeters * math.sqrt(x * x + dLat * dLat);
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}
