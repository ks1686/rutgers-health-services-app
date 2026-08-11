import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cwc_health_app/features/nearby/data/nearby_query.dart';
import 'package:cwc_health_app/features/nearby/data/sources/nominatim_geocode.dart';

void main() {
  test('geocodes New Brunswick from Nominatim JSON', () async {
    final payload = jsonEncode([
      {
        'lat': '40.4862167',
        'lon': '-74.4518188',
        'boundingbox': ['40.45', '40.52', '-74.49', '-74.40'],
        'display_name': 'New Brunswick, Middlesex County, New Jersey, USA',
      },
    ]);

    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.host, 'nominatim.openstreetmap.org');
      expect(request.url.queryParameters['city'], 'New Brunswick');
      expect(request.url.queryParameters['state'], 'New Jersey');
      expect(request.url.queryParameters['country'], 'USA');
      expect(request.headers['User-Agent'], contains('CWCHealthApp'));
      return http.Response(
        payload,
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final geocoder = NominatimGeocode(client);
    final point = await geocoder.geocode(const NearbyQuery());

    expect(point.lat, closeTo(40.4862167, 0.0001));
    expect(point.lng, closeTo(-74.4518188, 0.0001));
    expect(point.bboxSouth, closeTo(40.45, 0.001));
    expect(point.bboxNorth, closeTo(40.52, 0.001));
    expect(point.bboxWest, closeTo(-74.49, 0.001));
    expect(point.bboxEast, closeTo(-74.40, 0.001));
  });

  test('throws when Nominatim returns no results', () async {
    final client = MockClient((_) async => http.Response('[]', 200));
    final geocoder = NominatimGeocode(client);

    expect(
      () => geocoder.geocode(const NearbyQuery(town: 'Nowhereville')),
      throwsA(isA<NominatimException>()),
    );
  });

  test('maps NJ state code to New Jersey', () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters['state'], 'New Jersey');
      return http.Response(
        jsonEncode([
          {
            'lat': '40.0',
            'lon': '-74.5',
            'boundingbox': ['39.9', '40.1', '-74.6', '-74.4'],
          },
        ]),
        200,
      );
    });

    final geocoder = NominatimGeocode(client);
    await geocoder.geocode(const NearbyQuery(stateCode: 'NJ'));
  });
}
