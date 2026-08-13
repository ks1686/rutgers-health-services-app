import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/nearby/data/nearby_cache.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_config.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_fetch_result.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_query.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_repository.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_resource.dart';
import 'package:cwc_health_app/features/nearby/data/sources/google_places_source.dart';
import 'package:cwc_health_app/features/nearby/data/sources/nominatim_geocode.dart';
import 'package:cwc_health_app/features/nearby/data/sources/osm_overpass_source.dart';
import 'package:cwc_health_app/features/nearby/nearby_screen.dart';
import 'package:cwc_health_app/features/nearby/widgets/nearby_live_disclaimer.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';

const _demoConfig = NearbyConfig(liveNearby: false, googlePlacesApiKey: '');
const _liveConfig = NearbyConfig(liveNearby: true, googlePlacesApiKey: '');

class _StubRepository implements NearbyRepository {
  _StubRepository(this.result);

  final NearbyFetchResult result;
  int calls = 0;

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
}

NearbyResource _resource({
  required String name,
  String category = 'Pharmacy',
  String? phone = '+1-732-555-0142',
  double lat = 40.4862,
  double lng = -74.4518,
}) {
  return NearbyResource(
    id: name,
    name: name,
    category: category,
    address: '214 Main St, New Brunswick, NJ',
    phone: phone,
    lat: lat,
    lng: lng,
    status: 'Hours not listed',
    source: 'osm',
    fetchedAt: DateTime(2026, 8, 12, 21, 5),
  );
}

NearbyFetchResult _result({
  required List<NearbyResource> resources,
  NearbySourceStatus status = NearbySourceStatus.osm,
  String? message,
}) {
  return NearbyFetchResult(
    resources: resources,
    status: status,
    fetchedAt: DateTime(2026, 8, 12, 21, 5),
    message: message,
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
        NearbyScreen(config: _liveConfig, repository: repository),
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
        NearbyScreen(config: _liveConfig, repository: repository),
      );

      expect(find.text('Main Street Pharmacy'), findsNothing);
      expect(find.textContaining('Draft for co-design'), findsNothing);
      expect(find.text('Could not load places right now.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('try again refetches', (tester) async {
      final repository = _StubRepository(
        _result(resources: const [], status: NearbySourceStatus.unavailable),
      );

      await pumpScreen(
        tester,
        NearbyScreen(config: _liveConfig, repository: repository),
      );
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

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
        NearbyScreen(config: _liveConfig, repository: repository),
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
        NearbyScreen(config: _liveConfig, repository: repository),
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
        ),
      );

      await tester.tap(find.text('Call'));
      await tester.pumpAndSettle();
      expect(opened.single.scheme, 'tel');
      expect(opened.single.path, '+1-732-555-0142');

      await tester.tap(find.text('Directions'));
      await tester.pumpAndSettle();
      expect(opened.last.host, 'www.google.com');
      expect(opened.last.query, contains('40.4862,-74.4518'));
    });

    testWidgets('rows without a phone hide Call and Text', (tester) async {
      final repository = _StubRepository(
        _result(resources: [_resource(name: 'No Phone Clinic', phone: null)]),
      );

      await pumpScreen(
        tester,
        NearbyScreen(config: _liveConfig, repository: repository),
      );

      expect(find.text('Call'), findsNothing);
      expect(find.text('Text'), findsNothing);
      expect(find.text('Directions'), findsOneWidget);
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
