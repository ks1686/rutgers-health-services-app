import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/nearby/data/nearby_resource.dart';
import 'package:cwc_health_app/features/nearby/data/sources/geo_point.dart';
import 'package:cwc_health_app/features/nearby/widgets/nearby_map_view.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';

NearbyResource _resource({
  required String id,
  required String name,
  double lat = 40.4862,
  double lng = -74.4518,
}) {
  return NearbyResource(
    id: id,
    name: name,
    category: 'Pharmacy',
    address: '1 Test St',
    lat: lat,
    lng: lng,
    openingHoursRaw: null,
    source: 'osm',
    fetchedAt: DateTime.utc(2026, 9, 3),
  );
}

void main() {
  testWidgets('empty Maps key uses OSM flutter_map with attribution', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: Scaffold(
          body: NearbyMapView(
            preferGoogleMaps: false,
            origin: const GeoPoint(lat: 40.4862, lng: -74.4518),
            resources: [_resource(id: 'p1', name: 'Corner Pharmacy')],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.textContaining('OpenStreetMap'), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
  });

  testWidgets('marker tap reports resource id', (tester) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: Scaffold(
          body: NearbyMapView(
            preferGoogleMaps: false,
            resources: [_resource(id: 'p1', name: 'Corner Pharmacy')],
            onMarkerTap: (id) => tapped = id,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.location_on));
    expect(tapped, 'p1');
  });
}
