import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cwc_health_app/features/nearby/data/sources/geo_point.dart';
import 'package:cwc_health_app/features/nearby/data/sources/osm_overpass_source.dart';

void main() {
  final fixture = File(
    'test/features/nearby/fixtures/overpass_new_brunswick_sample.json',
  ).readAsStringSync();

  const area = GeoPoint(lat: 40.4862, lng: -74.4518);

  test('parses pharmacy and clinic into NearbyResource', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.host, 'overpass-api.de');
      expect(request.headers['User-Agent'], contains('CWCHealthApp'));
      return http.Response(
        fixture,
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final source = OsmOverpassSource(client);
    final resources = await source.fetch(
      area,
      fetchedAt: DateTime.utc(2026, 8, 11, 15),
    );

    expect(
      resources.map((r) => r.category),
      containsAll(['Pharmacy', 'Clinic', 'Urgent care']),
    );
    expect(resources.map((r) => r.name), contains('Main Street Pharmacy'));
    expect(resources.map((r) => r.name), contains('Community Health Clinic'));
    expect(resources.map((r) => r.source), everyElement('osm'));

    final pharmacy = resources.firstWhere(
      (r) => r.name == 'Main Street Pharmacy',
    );
    expect(pharmacy.phone, '+1-732-555-0142');
    expect(pharmacy.address, contains('Main St'));
  });

  test('drops points outside the NJ guard bbox', () async {
    final client = MockClient((_) async => http.Response(fixture, 200));
    final source = OsmOverpassSource(client);
    final resources = await source.fetch(area);

    expect(
      resources.map((r) => r.name),
      isNot(contains('Boston Pharmacy Outside NJ')),
    );
  });

  test('throws on non-200 Overpass response', () async {
    final client = MockClient((_) async => http.Response('nope', 503));
    final source = OsmOverpassSource(client);

    expect(() => source.fetch(area), throwsA(isA<OsmOverpassException>()));
  });

  test('fixture itself is valid JSON with expected tags', () {
    final decoded = jsonDecode(fixture) as Map<String, dynamic>;
    final elements = decoded['elements'] as List<dynamic>;
    expect(elements, hasLength(4));
  });
}
