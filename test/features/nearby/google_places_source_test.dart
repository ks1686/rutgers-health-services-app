import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cwc_health_app/features/nearby/data/sources/geo_point.dart';
import 'package:cwc_health_app/features/nearby/data/sources/google_places_source.dart';

void main() {
  const area = GeoPoint(lat: 40.4862, lng: -74.4518);
  final fetchedAt = DateTime.utc(2026, 8, 12, 18);

  test('empty key soft-fails without calling HTTP', () async {
    var called = false;
    final client = MockClient((_) async {
      called = true;
      return http.Response('should not be hit', 500);
    });

    final source = GooglePlacesSource(client, apiKey: '');
    final outcome = await source.fetch(area, fetchedAt: fetchedAt);

    expect(called, isFalse);
    expect(outcome, isA<GooglePlacesSoftFail>());
    expect((outcome as GooglePlacesSoftFail).reason, 'missing_key');
  });

  test('403 soft-fails', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.host, 'places.googleapis.com');
      expect(request.headers['X-Goog-Api-Key'], 'test-key');
      return http.Response(
        jsonEncode({
          'error': {
            'code': 403,
            'message': 'Requests to this API are blocked.',
            'status': 'PERMISSION_DENIED',
          },
        }),
        403,
        headers: {'content-type': 'application/json'},
      );
    });

    final source = GooglePlacesSource(client, apiKey: 'test-key');
    final outcome = await source.fetch(area, fetchedAt: fetchedAt);

    expect(outcome, isA<GooglePlacesSoftFail>());
    final fail = outcome as GooglePlacesSoftFail;
    expect(fail.reason, contains('403'));
  });

  test('200 maps places to NearbyResource', () async {
    final client = MockClient((request) async {
      expect(request.headers['X-Goog-FieldMask'], contains('places.id'));
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['includedTypes'], contains('pharmacy'));
      return http.Response(
        jsonEncode({
          'places': [
            {
              'id': 'places/ChIJpharmacy',
              'displayName': {'text': 'Highland Pharmacy'},
              'formattedAddress': '100 George St, New Brunswick, NJ',
              'location': {'latitude': 40.49, 'longitude': -74.45},
              'nationalPhoneNumber': '+1 732-555-0100',
              'types': ['pharmacy', 'health', 'point_of_interest'],
            },
            {
              'id': 'places/ChIJclinic',
              'displayName': {'text': 'Riverside Clinic'},
              'formattedAddress': '200 Somerset St, New Brunswick, NJ',
              'location': {'latitude': 40.48, 'longitude': -74.44},
              'types': ['doctor', 'health'],
            },
            {
              'id': 'places/ChIJurgent',
              'displayName': {'text': 'Quick Care Urgent'},
              'formattedAddress': '300 Jersey Ave, New Brunswick, NJ',
              'location': {'latitude': 40.47, 'longitude': -74.43},
              'nationalPhoneNumber': '+1 732-555-0199',
              'types': ['urgent_care_center', 'health'],
            },
            {
              'id': 'places/ChIJcafe',
              'displayName': {'text': 'Coffee Spot'},
              'formattedAddress': '1 College Ave, New Brunswick, NJ',
              'location': {'latitude': 40.50, 'longitude': -74.45},
              'types': ['cafe', 'food'],
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final source = GooglePlacesSource(client, apiKey: 'test-key');
    final outcome = await source.fetch(area, fetchedAt: fetchedAt);

    expect(outcome, isA<GooglePlacesOk>());
    final resources = (outcome as GooglePlacesOk).resources;
    expect(resources, hasLength(3));
    expect(
      resources.map((r) => r.category),
      containsAll(['Pharmacy', 'Clinic', 'Urgent care']),
    );
    expect(resources.map((r) => r.source), everyElement('google'));
    expect(resources.map((r) => r.name), isNot(contains('Coffee Spot')));

    final pharmacy = resources.firstWhere((r) => r.name == 'Highland Pharmacy');
    expect(pharmacy.phone, '+1 732-555-0100');
    expect(pharmacy.address, contains('George St'));
    expect(pharmacy.fetchedAt, fetchedAt);
  });

  test('200 with zero places returns empty ok', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'places': <Object>[]}),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );

    final source = GooglePlacesSource(client, apiKey: 'test-key');
    final outcome = await source.fetch(area, fetchedAt: fetchedAt);

    expect(outcome, isA<GooglePlacesOk>());
    expect((outcome as GooglePlacesOk).resources, isEmpty);
  });

  test('billing-style error body soft-fails', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'error': {
            'code': 400,
            'message': 'API key not valid. Please pass a valid API key.',
            'status': 'INVALID_ARGUMENT',
          },
        }),
        400,
      ),
    );

    final source = GooglePlacesSource(client, apiKey: 'bad-key');
    final outcome = await source.fetch(area, fetchedAt: fetchedAt);

    expect(outcome, isA<GooglePlacesSoftFail>());
  });
}
