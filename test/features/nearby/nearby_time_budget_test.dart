import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cwc_health_app/features/nearby/data/sources/geo_point.dart';
import 'package:cwc_health_app/features/nearby/data/sources/google_places_source.dart';
import 'package:cwc_health_app/features/nearby/data/sources/nominatim_geocode.dart';
import 'package:cwc_health_app/features/nearby/data/sources/osm_overpass_source.dart';

/// M3. A member waiting on a spinner gives up long before two minutes.
void main() {
  const area = GeoPoint(lat: 40.4862, lng: -74.4518);
  final never = MockClient((_) => Completer<http.Response>().future);

  test('M3 the default lookups give up within about 30 seconds', () {
    final overpass = OsmOverpassSource(never);
    final nominatim = NominatimGeocode(never);
    final google = GooglePlacesSource(never, apiKey: 'k');

    expect(overpass.requestTimeout, lessThanOrEqualTo(Duration(seconds: 8)));
    expect(nominatim.requestTimeout, lessThanOrEqualTo(Duration(seconds: 8)));
    expect(google.requestTimeout, lessThanOrEqualTo(Duration(seconds: 8)));
    // Overpass has a budget across every mirror and retry, so the worst
    // case is that budget, not mirrors x tries x timeout.
    final worst =
        nominatim.requestTimeout * 2 +
        google.requestTimeout +
        overpass.totalBudget;
    expect(worst, lessThanOrEqualTo(const Duration(seconds: 50)));
  });

  test('M3 Overpass stops trying mirrors once its budget is spent', () async {
    final hosts = <String>[];
    final client = MockClient((request) {
      hosts.add(request.url.host);
      return Completer<http.Response>().future;
    });
    final source = OsmOverpassSource(
      client,
      endpoints: const [
        'https://a.example',
        'https://b.example',
        'https://c.example',
      ],
      requestTimeout: const Duration(milliseconds: 80),
      totalBudget: const Duration(milliseconds: 120),
      retryBackoff: Duration.zero,
    );
    final watch = Stopwatch()..start();
    await expectLater(source.fetch(area), throwsA(isA<OsmOverpassException>()));
    expect(watch.elapsed, lessThan(const Duration(milliseconds: 600)));
    expect(hosts, ['a.example', 'b.example']);
  });

  test('M3 a hung mirror moves on to a healthy one', () async {
    final fixture = File(
      'test/features/nearby/fixtures/overpass_new_brunswick_sample.json',
    ).readAsStringSync();
    final client = MockClient((request) async {
      if (request.url.host == 'a.example') {
        return Completer<http.Response>().future;
      }
      return http.Response(fixture, 200);
    });
    final source = OsmOverpassSource(
      client,
      endpoints: const ['https://a.example', 'https://b.example'],
      requestTimeout: const Duration(milliseconds: 50),
    );
    expect(await source.fetch(area), isNotEmpty);
  });
}
