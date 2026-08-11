import 'dart:convert';

import 'package:http/http.dart' as http;

import '../nearby_query.dart';
import 'geo_point.dart';

const kNearbyOsmUserAgent =
    'CWCHealthApp/0.1 (Rutgers CWC research; contact: via repo)';

/// Failure talking to or parsing Nominatim.
class NominatimException implements Exception {
  NominatimException(this.message);

  final String message;

  @override
  String toString() => 'NominatimException: $message';
}

/// Town → center/bbox via OpenStreetMap Nominatim (no Google billing).
class NominatimGeocode {
  NominatimGeocode(
    this._client, {
    this.userAgent = kNearbyOsmUserAgent,
    this.baseUrl = 'https://nominatim.openstreetmap.org',
  });

  final http.Client _client;
  final String userAgent;
  final String baseUrl;

  Future<GeoPoint> geocode(NearbyQuery query) async {
    final uri = Uri.parse('$baseUrl/search').replace(
      queryParameters: {
        'city': query.town,
        'state': _stateName(query.stateCode),
        'country': 'USA',
        'format': 'json',
        'limit': '1',
      },
    );

    final response = await _client.get(
      uri,
      headers: {'User-Agent': userAgent, 'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw NominatimException('HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      throw NominatimException(
        'No results for ${query.town}, ${query.stateCode}',
      );
    }

    final first = decoded.first;
    if (first is! Map<String, dynamic>) {
      throw NominatimException('Unexpected Nominatim payload shape');
    }

    final lat = double.tryParse('${first['lat']}');
    final lon = double.tryParse('${first['lon']}');
    if (lat == null || lon == null) {
      throw NominatimException('Missing lat/lon in Nominatim result');
    }

    double? south;
    double? north;
    double? west;
    double? east;
    final bbox = first['boundingbox'];
    if (bbox is List && bbox.length == 4) {
      // Nominatim order: south, north, west, east
      south = double.tryParse('${bbox[0]}');
      north = double.tryParse('${bbox[1]}');
      west = double.tryParse('${bbox[2]}');
      east = double.tryParse('${bbox[3]}');
    }

    return GeoPoint(
      lat: lat,
      lng: lon,
      bboxSouth: south,
      bboxNorth: north,
      bboxWest: west,
      bboxEast: east,
    );
  }

  static String _stateName(String stateCode) {
    switch (stateCode.toUpperCase()) {
      case 'NJ':
        return 'New Jersey';
      default:
        return stateCode;
    }
  }
}
