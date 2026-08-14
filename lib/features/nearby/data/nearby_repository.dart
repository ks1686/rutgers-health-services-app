import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'nearby_cache.dart';
import 'nearby_config.dart';
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
      cache: cache,
    );
  }

  final NearbyConfig config;
  final NominatimGeocode geocoder;
  final GooglePlacesSource googlePlaces;
  final OsmOverpassSource overpass;
  final NearbyCache? cache;
  final Clock _clock;

  Future<NearbyFetchResult> fetch(NearbyQuery query) async {
    final when = _clock();

    final GeoPoint area;
    try {
      area = await geocoder.geocode(query);
    } catch (e) {
      return _cachedOr(query, 'Could not look up ${query.town}: $e');
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
      return _cachedOr(query, 'Could not load places right now: $e');
    }
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
