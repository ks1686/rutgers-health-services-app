import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/nearby/data/nearby_cache.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_config.dart';
import 'package:cwc_health_app/features/nearby/data/device_location.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_errors.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_fetch_result.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_query.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_repository.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_resource.dart';
import 'package:cwc_health_app/features/nearby/data/sources/geo_point.dart';
import 'package:cwc_health_app/features/nearby/data/sources/google_places_source.dart';
import 'package:cwc_health_app/features/nearby/data/sources/nominatim_geocode.dart';
import 'package:cwc_health_app/features/nearby/data/sources/osm_overpass_source.dart';
import 'package:cwc_health_app/features/nearby/nearby_screen.dart';
import 'package:cwc_health_app/features/nearby/widgets/nearby_live_disclaimer.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';

const _demoConfig = NearbyConfig(liveNearby: false, googlePlacesApiKey: '');
const _liveConfig = NearbyConfig(liveNearby: true, googlePlacesApiKey: '');

class _StubRepository implements NearbyRepository {
  _StubRepository(this.result, {this.deviceLocation, this.nearDeviceResult});

  final NearbyFetchResult result;

  /// Response for [fetchNearDevice]; defaults to [result].
  final NearbyFetchResult? nearDeviceResult;
  int calls = 0;
  int nearDeviceCalls = 0;

  @override
  final DeviceLocationSource? deviceLocation;

  @override
  NearbyConfig get config => _liveConfig;

  @override
  NearbyCache? get cache => null;

  @override
  NominatimGeocode get geocoder => throw UnimplementedError();

  @override
  GooglePlacesSource get googlePlaces => throw UnimplementedError();

  @override
  OsmOverpassSource get overpass => throw UnimplementedError();

  @override
  Future<NearbyFetchResult> fetch(NearbyQuery query) async {
    calls++;
    return result;
  }

  @override
  Future<NearbyFetchResult> fetchNearDevice(NearbyQuery query) async {
    nearDeviceCalls++;
    return nearDeviceResult ?? result;
  }
}

class _ScriptedDeviceLocation implements DeviceLocationSource {
  _ScriptedDeviceLocation(this.outcome);

  final DeviceLocationOutcome outcome;

  @override
  Future<DeviceLocationOutcome> getCurrent() async => outcome;
}

class _DelayedStubRepository extends _StubRepository {
  _DelayedStubRepository(this.first, NearbyFetchResult later) : super(later);

  final Future<NearbyFetchResult> first;

  @override
  Future<NearbyFetchResult> fetch(NearbyQuery query) async {
    calls++;
    if (calls == 1) return first;
    return result;
  }
}

NearbyResource _resource({
  required String name,
  String category = 'Pharmacy',
  String? phone = '+1-732-555-0142',
  double lat = 40.4862,
  double lng = -74.4518,
  String? openingHoursRaw,
}) {
  return NearbyResource(
    id: name,
    name: name,
    category: category,
    address: '214 Main St, New Brunswick, NJ',
    phone: phone,
    lat: lat,
    lng: lng,
    openingHoursRaw: openingHoursRaw,
    source: 'osm',
    fetchedAt: DateTime(2026, 8, 12, 21, 5),
  );
}

NearbyFetchResult _result({
  required List<NearbyResource> resources,
  NearbySourceStatus status = NearbySourceStatus.osm,
  String? message,
  GeoPoint? origin,
}) {
  return NearbyFetchResult(
    resources: resources,
    status: status,
    fetchedAt: DateTime(2026, 8, 12, 21, 5),
    message: message,
    origin: origin,
  );
}

void main() {
  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: Scaffold(body: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('demo mode', () {
    testWidgets('shows the demo banner and sample pharmacy', (tester) async {
      await pumpScreen(tester, const NearbyScreen(config: _demoConfig));

      expect(find.text('Main Street Pharmacy'), findsOneWidget);
      expect(find.textContaining('Draft for co-design'), findsOneWidget);
      expect(find.text('Use my location?'), findsOneWidget);
      expect(find.byType(NearbyLiveDisclaimer), findsNothing);
    });

    testWidgets('keeps demo-only snackbars on actions', (tester) async {
      await pumpScreen(tester, const NearbyScreen(config: _demoConfig));

      await tester.tap(find.text('Call').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Demo only'), findsOneWidget);
    });

    testWidgets('demo cards keep Open until 7pm and have no Open now', (
      tester,
    ) async {
      await pumpScreen(tester, const NearbyScreen(config: _demoConfig));

      expect(find.text('Open until 7pm'), findsOneWidget);
      expect(find.text('Open now'), findsNothing);
      expect(find.text('Hours not listed'), findsNothing);
    });
  });

  group('live mode', () {
    testWidgets('shows the unvetted disclaimer and repository rows', (
      tester,
    ) async {
      final repository = _StubRepository(
        _result(
          resources: [
            _resource(name: 'Highland Pharmacy'),
            _resource(name: 'Riverside Clinic', category: 'Clinic'),
          ],
        ),
      );

      await pumpScreen(
        tester,
        NearbyScreen(
          config: _liveConfig,
          repository: repository,
          clock: () => DateTime.utc(2026, 8, 11, 14, 42),
        ),
      );

      expect(repository.calls, 1);
      expect(find.byType(NearbyLiveDisclaimer), findsOneWidget);
      expect(
        find.textContaining('They are not checked by our team.'),
        findsOneWidget,
      );
      expect(
        find.text('Updated as of Aug 12, 2026 at 9:05 PM.'),
        findsOneWidget,
      );
      expect(find.text('Highland Pharmacy'), findsOneWidget);
      expect(find.text('Riverside Clinic'), findsOneWidget);
    });

    testWidgets('never falls back to demo rows', (tester) async {
      final repository = _StubRepository(
        _result(
          resources: const [],
          status: NearbySourceStatus.unavailable,
          message: 'Could not load places right now.',
        ),
      );

      await pumpScreen(
        tester,
        NearbyScreen(
          config: _liveConfig,
          repository: repository,
          clock: () => DateTime.utc(2026, 8, 11, 14, 42),
        ),
      );

      expect(find.text('Main Street Pharmacy'), findsNothing);
      expect(find.textContaining('Draft for co-design'), findsNothing);
      expect(find.text('Could not load places right now.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('empty OSM does not blame the connection', (tester) async {
      final repository = _StubRepository(
        _result(
          resources: const [],
          status: NearbySourceStatus.osm,
          message: 'No pharmacies or clinics found near New Brunswick.',
        ),
      );

      await pumpScreen(
        tester,
        NearbyScreen(
          config: _liveConfig,
          repository: repository,
          clock: () => DateTime.utc(2026, 8, 11, 14, 42),
        ),
      );

      expect(
        find.text('No pharmacies or clinics found near New Brunswick.'),
        findsOneWidget,
      );
      expect(find.text('Check your connection, then try again.'), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('unavailable still asks to check the connection', (
      tester,
    ) async {
      final repository = _StubRepository(
        _result(
          resources: const [],
          status: NearbySourceStatus.unavailable,
          message: kNearbyMemberLoadFailed,
        ),
      );

      await pumpScreen(
        tester,
        NearbyScreen(
          config: _liveConfig,
          repository: repository,
          clock: () => DateTime.utc(2026, 8, 11, 14, 42),
        ),
      );

      expect(find.text(kNearbyMemberLoadFailed), findsOneWidget);
      expect(
        find.text('Check your connection, then try again.'),
        findsOneWidget,
      );
    });

    testWidgets('try again refetches', (tester) async {
      final repository = _StubRepository(
        _result(resources: const [], status: NearbySourceStatus.unavailable),
      );

      await pumpScreen(
        tester,
        NearbyScreen(
          config: _liveConfig,
          repository: repository,
          clock: () => DateTime.utc(2026, 8, 11, 14, 42),
        ),
      );
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(repository.calls, 2);
    });

    testWidgets('try again is ignored while a fetch is in flight', (
      tester,
    ) async {
      final first = Completer<NearbyFetchResult>();
      final later = _result(
        resources: const [],
        status: NearbySourceStatus.unavailable,
      );
      final repository = _DelayedStubRepository(first.future, later);

      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildCwcTheme(),
          home: Scaffold(
            body: NearbyScreen(
              config: _liveConfig,
              repository: repository,
              clock: () => DateTime.utc(2026, 8, 11, 14, 42),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      first.complete(
        _result(resources: const [], status: NearbySourceStatus.unavailable),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(repository.calls, 2);
    });

    testWidgets('cache results say the copy is saved', (tester) async {
      final repository = _StubRepository(
        _result(
          resources: [_resource(name: 'Highland Pharmacy')],
          status: NearbySourceStatus.cache,
        ),
      );

      await pumpScreen(
        tester,
        NearbyScreen(
          config: _liveConfig,
          repository: repository,
          clock: () => DateTime.utc(2026, 8, 11, 14, 42),
        ),
      );

      expect(find.textContaining('This is a saved copy'), findsOneWidget);
    });

    testWidgets('category chips filter the live list', (tester) async {
      final repository = _StubRepository(
        _result(
          resources: [
            _resource(name: 'Highland Pharmacy'),
            _resource(name: 'Riverside Clinic', category: 'Clinic'),
          ],
        ),
      );

      await pumpScreen(
        tester,
        NearbyScreen(
          config: _liveConfig,
          repository: repository,
          clock: () => DateTime.utc(2026, 8, 11, 14, 42),
        ),
      );

      await tester.tap(find.widgetWithText(FilterChip, 'Clinic'));
      await tester.pumpAndSettle();

      expect(find.text('Riverside Clinic'), findsOneWidget);
      expect(find.text('Highland Pharmacy'), findsNothing);
    });

    testWidgets('Call and Directions open real links', (tester) async {
      final opened = <Uri>[];
      final repository = _StubRepository(
        _result(resources: [_resource(name: 'Highland Pharmacy')]),
      );

      await pumpScreen(
        tester,
        NearbyScreen(
          config: _liveConfig,
          repository: repository,
          launcher: (uri) async {
            opened.add(uri);
            return true;
          },
          clock: () => DateTime.utc(2026, 8, 11, 14, 42),
        ),
      );

      await tester.tap(find.text('Call'));
      await tester.pumpAndSettle();
      expect(opened.single.scheme, 'tel');
      expect(opened.single.path, '17325550142');

      await tester.tap(find.text('Directions'));
      await tester.pumpAndSettle();
      expect(opened.last.scheme, 'geo');
      expect(opened.last.toString(), contains('40.4862,-74.4518'));
    });

    testWidgets('every source category has a filter chip', (tester) async {
      final repository = _StubRepository(
        _result(
          resources: [
            for (final category in NearbyCategory.values)
              _resource(
                name: 'Place ${category.label}',
                category: category.label,
              ),
          ],
        ),
      );

      await pumpScreen(
        tester,
        NearbyScreen(
          config: _liveConfig,
          repository: repository,
          clock: () => DateTime.utc(2026, 8, 11, 14, 42),
        ),
      );

      for (final category in NearbyCategory.values) {
        expect(
          find.widgetWithText(FilterChip, category.label),
          findsOneWidget,
          reason: 'no chip filters ${category.label}',
        );
      }
    });

    testWidgets('live map toggle is hidden', (tester) async {
      final repository = _StubRepository(
        _result(resources: [_resource(name: 'Highland Pharmacy')]),
      );

      await pumpScreen(
        tester,
        NearbyScreen(
          config: _liveConfig,
          repository: repository,
          clock: () => DateTime.utc(2026, 8, 11, 14, 42),
        ),
      );

      expect(find.text('See these on a map'), findsNothing);
      expect(find.text('Map view is not ready yet'), findsNothing);
    });

    testWidgets(
      'missing phone shows Phone not listed and still has Directions',
      (tester) async {
        final repository = _StubRepository(
          _result(resources: [_resource(name: 'No Phone Shop', phone: null)]),
        );

        await pumpScreen(
          tester,
          NearbyScreen(
            config: _liveConfig,
            repository: repository,
            clock: () => DateTime.utc(2026, 8, 11, 14, 42),
          ),
        );

        expect(find.text('Phone not listed'), findsOneWidget);
        expect(find.text('Call'), findsNothing);
        expect(find.text('Directions'), findsOneWidget);
      },
    );

    testWidgets('rows without a phone hide Call and Text', (tester) async {
      final repository = _StubRepository(
        _result(resources: [_resource(name: 'No Phone Clinic', phone: null)]),
      );

      await pumpScreen(
        tester,
        NearbyScreen(
          config: _liveConfig,
          repository: repository,
          clock: () => DateTime.utc(2026, 8, 11, 14, 42),
        ),
      );

      expect(find.text('Call'), findsNothing);
      expect(find.text('Text'), findsNothing);
      expect(find.text('Directions'), findsOneWidget);
    });

    testWidgets('live card with OSM hours shows Open now and expands', (
      tester,
    ) async {
      final repository = _StubRepository(
        _result(
          resources: [
            _resource(
              name: 'University Pharmacy',
              openingHoursRaw:
                  'Mo-Fr 09:00-19:00; Sa 09:00-17:00; Su 10:00-16:00',
            ),
          ],
        ),
      );

      await pumpScreen(
        tester,
        NearbyScreen(
          config: _liveConfig,
          repository: repository,
          clock: () => DateTime.utc(2026, 8, 11, 14, 42),
        ),
      );

      expect(find.text('Hours not listed'), findsNothing);
      expect(find.text('Open now'), findsOneWidget);
      expect(find.text('Monday 9:00 AM – 7:00 PM'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Open now, show hours'));
      await tester.pumpAndSettle();
      expect(find.text('Monday 9:00 AM – 7:00 PM'), findsOneWidget);
    });

    testWidgets(
      'filtering after expand does not leak hours onto the remaining card',
      (tester) async {
        const hours = 'Mo-Fr 09:00-19:00; Sa 09:00-17:00; Su 10:00-16:00';
        final repository = _StubRepository(
          _result(
            resources: [
              _resource(name: 'Highland Pharmacy', openingHoursRaw: hours),
              _resource(
                name: 'Riverside Clinic',
                category: 'Clinic',
                openingHoursRaw: hours,
              ),
            ],
          ),
        );

        await pumpScreen(
          tester,
          NearbyScreen(
            config: _liveConfig,
            repository: repository,
            clock: () => DateTime.utc(2026, 8, 11, 14, 42),
          ),
        );

        await tester.tap(find.bySemanticsLabel('Open now, show hours').first);
        await tester.pumpAndSettle();
        expect(find.text('Monday 9:00 AM – 7:00 PM'), findsOneWidget);

        await tester.tap(find.widgetWithText(FilterChip, 'Clinic'));
        await tester.pumpAndSettle();

        expect(find.text('Highland Pharmacy'), findsNothing);
        expect(find.text('Riverside Clinic'), findsOneWidget);
        expect(find.text('Monday 9:00 AM – 7:00 PM'), findsNothing);
        expect(find.bySemanticsLabel('Open now, show hours'), findsOneWidget);
        expect(find.bySemanticsLabel('Open now, hide hours'), findsNothing);
      },
    );

    testWidgets('live card without hours stays Hours not listed', (
      tester,
    ) async {
      final repository = _StubRepository(
        _result(resources: [_resource(name: 'Highland Pharmacy')]),
      );

      await pumpScreen(
        tester,
        NearbyScreen(
          config: _liveConfig,
          repository: repository,
          clock: () => DateTime.utc(2026, 8, 11, 14, 42),
        ),
      );

      expect(find.text('Hours not listed'), findsOneWidget);
      expect(find.text('Open now'), findsNothing);
    });
  });

  group('device location mode', () {
    NearbyScreen screen(_StubRepository repository) {
      return NearbyScreen(
        config: _liveConfig,
        repository: repository,
        clock: () => DateTime.utc(2026, 8, 11, 14, 42),
      );
    }

    testWidgets('button hidden when no device source is wired', (tester) async {
      await pumpScreen(
        tester,
        screen(
          _StubRepository(
            _result(resources: [_resource(name: 'Highland Pharmacy')]),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('nearby-use-my-location')),
        findsNothing,
      );
      expect(find.text('New Brunswick'), findsOneWidget);
    });

    testWidgets(
      'with a device source, live tab asks for location on load and '
      'shows walk times + origin chip',
      (tester) async {
        final repository = _StubRepository(
          _result(resources: [_resource(name: 'Town Pharmacy')]),
          deviceLocation: _ScriptedDeviceLocation(
            DeviceLocationOk(const GeoPoint(lat: 40.4874, lng: -74.4518)),
          ),
          nearDeviceResult: _result(
            resources: [_resource(name: 'Corner Pharmacy')],
            // ~134 m from the default resource coords → ~2 min at 80 m/min.
            origin: const GeoPoint(lat: 40.4874, lng: -74.4518),
          ),
        );

        await pumpScreen(tester, screen(repository));

        expect(repository.nearDeviceCalls, 1);
        expect(repository.calls, 0);
        expect(find.text('Using your location'), findsOneWidget);
        expect(find.text('~2 min walk'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('nearby-use-my-location')),
          findsNothing,
        );
      },
    );

    testWidgets('denied permission falls back to town list and says why', (
      tester,
    ) async {
      final repository = _StubRepository(
        _result(
          resources: [_resource(name: 'Town Pharmacy')],
          message: kNearbyLocationDenied,
        ),
        deviceLocation: _ScriptedDeviceLocation(
          DeviceLocationSoftFail(DeviceLocationFailure.permissionDenied),
        ),
        nearDeviceResult: _result(
          resources: [_resource(name: 'Town Pharmacy')],
          message: kNearbyLocationDenied,
        ),
      );

      await pumpScreen(tester, screen(repository));

      // Back on the town list — honestly labeled. No second tap needed.
      expect(repository.nearDeviceCalls, 1);
      expect(find.text(kNearbyLocationDenied), findsOneWidget);
      expect(find.text('New Brunswick'), findsOneWidget);
      expect(find.text('Using your location'), findsNothing);
      expect(find.textContaining('min walk'), findsNothing);
      expect(
        find.byKey(const ValueKey('nearby-use-my-location')),
        findsOneWidget,
      );
    });

    testWidgets('location off falls back with its own sentence', (
      tester,
    ) async {
      final repository = _StubRepository(
        _result(resources: [_resource(name: 'Town Pharmacy')]),
        deviceLocation: _ScriptedDeviceLocation(
          DeviceLocationSoftFail(DeviceLocationFailure.serviceDisabled),
        ),
        nearDeviceResult: _result(
          resources: [_resource(name: 'Town Pharmacy')],
          message: kNearbyLocationOff,
        ),
      );

      await pumpScreen(tester, screen(repository));

      expect(find.text(kNearbyLocationOff), findsOneWidget);
      expect(find.text('Using your location'), findsNothing);
    });

    testWidgets('empty device result uses the near-you sentence', (
      tester,
    ) async {
      final repository = _StubRepository(
        _result(resources: [_resource(name: 'Town Pharmacy')]),
        deviceLocation: _ScriptedDeviceLocation(
          DeviceLocationOk(const GeoPoint(lat: 40.5, lng: -74.45)),
        ),
        nearDeviceResult: _result(
          resources: const [],
          status: NearbySourceStatus.osm,
          message: kNearbyNoPlacesNearYou,
          origin: const GeoPoint(lat: 40.5, lng: -74.45),
        ),
      );

      await pumpScreen(tester, screen(repository));

      expect(find.text(kNearbyNoPlacesNearYou), findsOneWidget);
      expect(find.text('Using your location'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('town list never shows walk-time badges', (tester) async {
      await pumpScreen(
        tester,
        screen(
          _StubRepository(_result(resources: [_resource(name: 'Highland')])),
        ),
      );

      expect(find.textContaining('min walk'), findsNothing);
    });
  });

  group('formatNearbyTimestamp', () {
    test('renders a plain local date and time', () {
      expect(
        formatNearbyTimestamp(DateTime(2026, 8, 12, 21, 5)),
        'Aug 12, 2026 at 9:05 PM',
      );
      expect(
        formatNearbyTimestamp(DateTime(2026, 1, 3, 0, 7)),
        'Jan 3, 2026 at 12:07 AM',
      );
      expect(
        formatNearbyTimestamp(DateTime(2026, 12, 31, 12, 0)),
        'Dec 31, 2026 at 12:00 PM',
      );
    });
  });
}
