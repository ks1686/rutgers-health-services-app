import 'dart:convert';

import 'package:http/http.dart' as http;

import '../nearby_resource.dart';
import 'geo_point.dart';
import 'nominatim_geocode.dart' show kNearbyOsmUserAgent;

/// Failure talking to or parsing Overpass.
class OsmOverpassException implements Exception {
  OsmOverpassException(this.message);

  final String message;

  @override
  String toString() => 'OsmOverpassException: $message';
}

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
    this.endpoint = 'https://overpass-api.de/api/interpreter',
  });

  final http.Client _client;
  final String userAgent;
  final String endpoint;

  Future<List<NearbyResource>> fetch(
    GeoPoint area, {
    DateTime? fetchedAt,
  }) async {
    final when = fetchedAt ?? DateTime.now().toUtc();
    final query = _buildQuery(area);

    final response = await _client.post(
      Uri.parse(endpoint),
      headers: {
        'User-Agent': userAgent,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {'data': query},
    );

    if (response.statusCode != 200) {
      throw OsmOverpassException(
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
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
    final hours = tagMap['opening_hours'];
    final status = (hours != null && hours.trim().isNotEmpty)
        ? hours.trim()
        : 'Hours not listed';

    return NearbyResource(
      id: id,
      name: name,
      category: category.label,
      address: _addressFrom(tagMap),
      phone: phone,
      lat: coords.$1,
      lng: coords.$2,
      status: status,
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
