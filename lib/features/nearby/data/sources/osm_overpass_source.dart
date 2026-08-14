import 'dart:convert';

import 'package:http/http.dart' as http;

import '../nearby_resource.dart';
import 'geo_point.dart';
import 'nominatim_geocode.dart' show kNearbyOsmUserAgent;

/// Failure talking to or parsing Overpass.
///
/// [retryable] marks the "server is busy / you are rate limited" family, which
/// is worth another attempt; everything else fails over or gives up.
class OsmOverpassException implements Exception {
  OsmOverpassException(this.message, {this.retryable = false});

  final String message;
  final bool retryable;

  @override
  String toString() => 'OsmOverpassException: $message';
}

/// Public Overpass mirrors, tried in order.
///
/// The main instance rate limits per IP, and a room of phones on one Wi-Fi
/// network shares an IP — so a single endpoint is not enough for field use.
///
/// Before adding a mirror, confirm it serves **planet-wide** data by querying a
/// New Jersey bounding box. Regional instances (`overpass.osm.ch`, for one)
/// answer HTTP 200 with zero elements, which would make the app tell a member
/// there is no pharmacy near them. An outright failure is safer than that.
/// Mirrors were last verified against New Brunswick on 2026-08-12.
const kOverpassEndpoints = <String>[
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
];

/// Statuses where the server is asking us to back off rather than refusing.
const _retryableStatuses = <int>{429, 500, 502, 503, 504};

/// Coarse New Jersey guardrail (reject out-of-state POIs).
const double kNjLatMin = 38.8;
const double kNjLatMax = 41.4;
const double kNjLngMin = -75.6;
const double kNjLngMax = -73.8;

/// Default search radius when Nominatim bbox is missing (~4 km).
const int kDefaultOverpassRadiusMeters = 4000;

/// Live POIs from OpenStreetMap Overpass → [NearbyResource].
class OsmOverpassSource {
  OsmOverpassSource(
    this._client, {
    this.userAgent = kNearbyOsmUserAgent,
    this.endpoints = kOverpassEndpoints,
    this.attemptsPerEndpoint = 2,
    this.retryBackoff = const Duration(milliseconds: 600),
    this.requestTimeout = const Duration(seconds: 20),
  }) : assert(endpoints.isNotEmpty, 'At least one endpoint is required');

  final http.Client _client;
  final String userAgent;
  final List<String> endpoints;
  final int attemptsPerEndpoint;
  final Duration retryBackoff;
  final Duration requestTimeout;

  /// Tries each mirror in turn, retrying only when the server asks us to wait.
  Future<List<NearbyResource>> fetch(
    GeoPoint area, {
    DateTime? fetchedAt,
  }) async {
    final when = fetchedAt ?? DateTime.now().toUtc();
    final query = _buildQuery(area);

    Object? lastFailure;
    for (final endpoint in endpoints) {
      for (var attempt = 1; attempt <= attemptsPerEndpoint; attempt++) {
        String body;
        try {
          body = await _post(endpoint, query);
        } on OsmOverpassException catch (failure) {
          lastFailure = failure;
          if (failure.retryable && attempt < attemptsPerEndpoint) {
            await Future<void>.delayed(retryBackoff * attempt);
            continue;
          }
          break;
        } catch (failure) {
          lastFailure = failure;
          break;
        }
        return _parse(body, when);
      }
    }

    throw OsmOverpassException(
      'All ${endpoints.length} Overpass endpoints failed. '
      'Last error: $lastFailure',
    );
  }

  Future<String> _post(String endpoint, String query) async {
    final response = await _client
        .post(
          Uri.parse(endpoint),
          headers: {
            'User-Agent': userAgent,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: {'data': query},
        )
        .timeout(requestTimeout);

    if (response.statusCode == 200) return response.body;

    throw OsmOverpassException(
      'HTTP ${response.statusCode}: ${response.body}',
      retryable: _retryableStatuses.contains(response.statusCode),
    );
  }

  List<NearbyResource> _parse(String body, DateTime when) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw OsmOverpassException('Unexpected Overpass payload shape');
    }

    final elements = decoded['elements'];
    if (elements is! List) {
      return const [];
    }

    final results = <NearbyResource>[];
    for (final element in elements) {
      if (element is! Map<String, dynamic>) continue;
      final resource = _mapElement(element, when);
      if (resource == null) continue;
      if (!_inNewJersey(resource.lat, resource.lng)) continue;
      results.add(resource);
    }
    return results;
  }

  String _buildQuery(GeoPoint area) {
    final filter = '''
  node["amenity"="pharmacy"](AREA);
  way["amenity"="pharmacy"](AREA);
  node["amenity"="clinic"](AREA);
  way["amenity"="clinic"](AREA);
  node["healthcare"="clinic"](AREA);
  way["healthcare"="clinic"](AREA);
  node["healthcare"="urgent_care"](AREA);
  way["healthcare"="urgent_care"](AREA);
''';

    if (area.hasBbox) {
      final s = area.bboxSouth!;
      final n = area.bboxNorth!;
      final w = area.bboxWest!;
      final e = area.bboxEast!;
      final bbox = '$s,$w,$n,$e';
      return '''
[out:json][timeout:25];
(
${filter.replaceAll('(AREA)', '($bbox)')}
);
out center tags;
''';
    }

    final around =
        '(around:$kDefaultOverpassRadiusMeters,${area.lat},${area.lng})';
    return '''
[out:json][timeout:25];
(
${filter.replaceAll('(AREA)', around)}
);
out center tags;
''';
  }

  NearbyResource? _mapElement(Map<String, dynamic> element, DateTime when) {
    final tags = element['tags'];
    if (tags is! Map) return null;
    final tagMap = tags.map((key, value) => MapEntry('$key', '$value'));

    final category = _categoryFor(tagMap);
    if (category == null) return null;

    final name = tagMap['name']?.trim();
    if (name == null || name.isEmpty) return null;

    final coords = _coords(element);
    if (coords == null) return null;

    final type = element['type']?.toString() ?? 'node';
    final idNum = element['id'];
    final id = '$type-$idNum';

    final phone = tagMap['phone'] ?? tagMap['contact:phone'];
    final hours = tagMap['opening_hours']?.trim();
    return NearbyResource(
      id: id,
      name: name,
      category: category.label,
      address: _addressFrom(tagMap),
      phone: phone,
      lat: coords.$1,
      lng: coords.$2,
      openingHoursRaw: (hours == null || hours.isEmpty) ? null : hours,
      source: 'osm',
      fetchedAt: when,
    );
  }

  NearbyCategory? _categoryFor(Map<String, String> tags) {
    final amenity = tags['amenity'];
    final healthcare = tags['healthcare'];

    if (amenity == 'pharmacy') return NearbyCategory.pharmacy;
    if (amenity == 'clinic' || healthcare == 'clinic') {
      return NearbyCategory.clinic;
    }
    // Under-claim: only explicit urgent_care healthcare tag.
    if (healthcare == 'urgent_care') return NearbyCategory.urgentCare;
    return null;
  }

  (double, double)? _coords(Map<String, dynamic> element) {
    final lat = element['lat'];
    final lon = element['lon'];
    if (lat is num && lon is num) {
      return (lat.toDouble(), lon.toDouble());
    }
    final center = element['center'];
    if (center is Map) {
      final cLat = center['lat'];
      final cLon = center['lon'];
      if (cLat is num && cLon is num) {
        return (cLat.toDouble(), cLon.toDouble());
      }
    }
    return null;
  }

  String _addressFrom(Map<String, String> tags) {
    final full = tags['addr:full'];
    if (full != null && full.trim().isNotEmpty) return full.trim();

    final parts = <String>[
      if (tags['addr:housenumber'] != null && tags['addr:street'] != null)
        '${tags['addr:housenumber']} ${tags['addr:street']}'
      else if (tags['addr:street'] != null)
        tags['addr:street']!,
      if (tags['addr:city'] != null) tags['addr:city']!,
      if (tags['addr:state'] != null) tags['addr:state']!,
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    return 'Address not listed';
  }

  bool _inNewJersey(double lat, double lng) {
    return lat >= kNjLatMin &&
        lat <= kNjLatMax &&
        lng >= kNjLngMin &&
        lng <= kNjLngMax;
  }
}
