import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cwc_health_app/features/nearby/data/sources/geo_point.dart';
import 'package:cwc_health_app/features/nearby/data/sources/osm_overpass_source.dart';

const _endpoints = [
  'https://first.example/api/interpreter',
  'https://second.example/api/interpreter',
  'https://third.example/api/interpreter',
];

void main() {
  final fixture = File(
    'test/features/nearby/fixtures/overpass_new_brunswick_sample.json',
  ).readAsStringSync();

  const area = GeoPoint(lat: 40.4862, lng: -74.4518);

  OsmOverpassSource build(http.Client client, {int attemptsPerEndpoint = 2}) {
    return OsmOverpassSource(
      client,
      endpoints: _endpoints,
      attemptsPerEndpoint: attemptsPerEndpoint,
      retryBackoff: Duration.zero,
    );
  }

  test('stops at the first healthy endpoint', () async {
    final hosts = <String>[];
    final client = MockClient((request) async {
      hosts.add(request.url.host);
      return http.Response(fixture, 200);
    });

    final resources = await build(client).fetch(area);

    expect(hosts, ['first.example']);
    expect(resources, isNotEmpty);
  });

  test('fails over to the next mirror when rate limited', () async {
    final hosts = <String>[];
    final client = MockClient((request) async {
      hosts.add(request.url.host);
      if (request.url.host == 'first.example') {
        return http.Response('rate_limited', 429);
      }
      return http.Response(fixture, 200);
    });

    final resources = await build(client).fetch(area);

    expect(hosts, ['first.example', 'first.example', 'second.example']);
    expect(resources, isNotEmpty);
  });

  test('retries a busy endpoint before moving on', () async {
    var firstHostCalls = 0;
    final client = MockClient((request) async {
      if (request.url.host == 'first.example') {
        firstHostCalls++;
        if (firstHostCalls == 1) return http.Response('busy', 504);
        return http.Response(fixture, 200);
      }
      return http.Response('unexpected', 500);
    });

    final resources = await build(client).fetch(area);

    expect(firstHostCalls, 2);
    expect(resources, isNotEmpty);
  });

  test('does not retry a refusal, but still tries the next mirror', () async {
    final hosts = <String>[];
    final client = MockClient((request) async {
      hosts.add(request.url.host);
      if (request.url.host == 'first.example') {
        return http.Response('bad request', 400);
      }
      return http.Response(fixture, 200);
    });

    await build(client).fetch(area);

    expect(hosts, ['first.example', 'second.example']);
  });

  test('network errors fail over', () async {
    final hosts = <String>[];
    final client = MockClient((request) async {
      hosts.add(request.url.host);
      if (request.url.host == 'first.example') {
        throw const SocketException('no route to host');
      }
      return http.Response(fixture, 200);
    });

    final resources = await build(client).fetch(area);

    expect(hosts, ['first.example', 'second.example']);
    expect(resources, isNotEmpty);
  });

  test(
    'gives up once every endpoint fails and reports the last error',
    () async {
      final client = MockClient((_) async => http.Response('down', 503));
      final source = build(client, attemptsPerEndpoint: 1);

      await expectLater(
        source.fetch(area),
        throwsA(
          isA<OsmOverpassException>().having(
            (e) => e.message,
            'message',
            allOf(contains('3 Overpass endpoints failed'), contains('503')),
          ),
        ),
      );
    },
  );

  test(
    'malformed 200 responses fail over like any other endpoint failure',
    () async {
      // A captive portal or a mirror's maintenance HTML page arrives as
      // HTTP 200 + unparseable body. That is one dead server, not "no data":
      // the next mirror must still get its chance.
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        if (request.url.host == 'first.example') {
          return http.Response('<html>maintenance</html>', 200);
        }
        return http.Response(fixture, 200);
      });

      final resources = await build(client).fetch(area);

      expect(calls, greaterThanOrEqualTo(2));
      expect(resources, isNotEmpty);
    },
  );

  test('garbage from every mirror surfaces as an OverpassException', () async {
    final client = MockClient((_) async => http.Response('[]', 200));

    await expectLater(
      build(client).fetch(area),
      throwsA(isA<OsmOverpassException>()),
    );
  });

  test('the shipped endpoint list has real mirrors', () {
    expect(kOverpassEndpoints.length, greaterThan(1));
    expect(kOverpassEndpoints.first, contains('overpass-api.de'));
    expect(kOverpassEndpoints.toSet(), hasLength(kOverpassEndpoints.length));
  });
}
