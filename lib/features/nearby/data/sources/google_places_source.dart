import 'dart:convert';

import 'package:http/http.dart' as http;

import '../nearby_resource.dart';
import 'geo_point.dart';
import 'osm_overpass_source.dart' show kDefaultOverpassRadiusMeters;

/// Result of an optional Google Places attempt (never throws for expected fail).
sealed class GooglePlacesOutcome {}

class GooglePlacesOk extends GooglePlacesOutcome {
  GooglePlacesOk(this.resources);

  final List<NearbyResource> resources;
}

class GooglePlacesSoftFail extends GooglePlacesOutcome {
  GooglePlacesSoftFail(this.reason);

  final String reason;
}

/// Places API (New) Nearby Search — soft-fails when key/billing blocks access.
///
/// Study default: empty key → [GooglePlacesSoftFail] with no HTTP. OSM remains
/// the supported live path (see Nearby live-data plan).
class GooglePlacesSource {
  GooglePlacesSource(
    this._client, {
    required this.apiKey,
    this.endpoint = 'https://places.googleapis.com/v1/places:searchNearby',
    this.radiusMeters = kDefaultOverpassRadiusMeters,
    this.requestTimeout = const Duration(seconds: 10),
  });

  final http.Client _client;
  final String apiKey;
  final String endpoint;
  final int radiusMeters;
  final Duration requestTimeout;

  static const _fieldMask =
      'places.id,places.displayName,places.formattedAddress,'
      'places.location,places.nationalPhoneNumber,places.types';

  /// Types we ask for; response rows are remapped / dropped in [_categoryFor].
  static const _includedTypes = <String>[
    'pharmacy',
    'doctor',
    'hospital',
    'urgent_care_center',
  ];

  Future<GooglePlacesOutcome> fetch(
    GeoPoint area, {
    DateTime? fetchedAt,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      return GooglePlacesSoftFail('missing_key');
    }

    final when = fetchedAt ?? DateTime.now().toUtc();

    try {
      final response = await _client
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': key,
              'X-Goog-FieldMask': _fieldMask,
            },
            body: jsonEncode({
              'includedTypes': _includedTypes,
              'maxResultCount': 20,
              'locationRestriction': {
                'circle': {
                  'center': {'latitude': area.lat, 'longitude': area.lng},
                  'radius': radiusMeters.toDouble(),
                },
              },
            }),
          )
          .timeout(requestTimeout);

      if (_isSoftFailStatus(response.statusCode)) {
        return GooglePlacesSoftFail(
          'HTTP ${response.statusCode}: ${_shortBody(response.body)}',
        );
      }

      if (response.statusCode != 200) {
        return GooglePlacesSoftFail(
          'HTTP ${response.statusCode}: ${_shortBody(response.body)}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return GooglePlacesSoftFail('unexpected_payload_shape');
      }

      if (decoded['error'] is Map) {
        final err = decoded['error'] as Map;
        final status = '${err['status'] ?? ''}';
        final message = '${err['message'] ?? ''}';
        return GooglePlacesSoftFail(
          'api_error:$status:${message.isEmpty ? 'unknown' : message}',
        );
      }

      final places = decoded['places'];
      if (places == null) {
        return GooglePlacesOk(const []);
      }
      if (places is! List) {
        return GooglePlacesSoftFail('unexpected_places_shape');
      }

      final results = <NearbyResource>[];
      for (final place in places) {
        if (place is! Map<String, dynamic>) continue;
        final resource = _mapPlace(place, when);
        if (resource != null) results.add(resource);
      }
      return GooglePlacesOk(results);
    } on FormatException catch (e) {
      return GooglePlacesSoftFail('parse_error:${e.message}');
    } catch (e) {
      return GooglePlacesSoftFail('network_error:$e');
    }
  }

  bool _isSoftFailStatus(int code) {
    return code == 401 || code == 403 || code == 429;
  }

  String _shortBody(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 160) return trimmed;
    return '${trimmed.substring(0, 160)}…';
  }

  NearbyResource? _mapPlace(Map<String, dynamic> place, DateTime when) {
    final types = place['types'];
    final typeList = <String>[];
    if (types is List) {
      for (final t in types) {
        typeList.add('$t');
      }
    }

    final category = _categoryFor(typeList);
    if (category == null) return null;

    final displayName = place['displayName'];
    String? name;
    if (displayName is Map) {
      final text = displayName['text'];
      if (text != null) name = '$text'.trim();
    }
    if (name == null || name.isEmpty) return null;

    final location = place['location'];
    if (location is! Map) return null;
    final lat = location['latitude'];
    final lng = location['longitude'];
    if (lat is! num || lng is! num) return null;

    final idRaw = place['id']?.toString() ?? name;
    final id = idRaw.startsWith('places/') ? idRaw : 'places/$idRaw';

    final address = place['formattedAddress']?.toString().trim();
    final phone = place['nationalPhoneNumber']?.toString().trim();

    return NearbyResource(
      id: id,
      name: name,
      category: category.label,
      address: (address == null || address.isEmpty)
          ? 'Address not listed'
          : address,
      phone: (phone == null || phone.isEmpty) ? null : phone,
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      openingHoursRaw: null,
      source: 'google',
      fetchedAt: when,
    );
  }

  NearbyCategory? _categoryFor(List<String> types) {
    final set = types.toSet();
    if (set.contains('pharmacy')) return NearbyCategory.pharmacy;
    if (set.contains('urgent_care_center') || set.contains('urgent_care')) {
      return NearbyCategory.urgentCare;
    }
    if (set.contains('doctor') ||
        set.contains('hospital') ||
        set.contains('medical_clinic') ||
        set.contains('dental_clinic')) {
      return NearbyCategory.clinic;
    }
    return null;
  }
}
