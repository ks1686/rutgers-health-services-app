import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cwc_health_app/features/nearby/data/nearby_fetch_result.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_query.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_resource.dart';
import 'package:cwc_health_app/features/nearby/data/prefs_nearby_cache.dart';
import 'package:cwc_health_app/features/nearby/data/sources/geo_point.dart';

void main() {
  const query = NearbyQuery();
  const area = GeoPoint(lat: 40.4862, lng: -74.4518);
  final result = NearbyFetchResult(
    resources: [
      NearbyResource(
        id: 'highland',
        name: 'Highland Pharmacy',
        category: NearbyCategory.pharmacy,
        address: '214 Main St, New Brunswick, NJ',
        lat: 40.4862,
        lng: -74.4518,
        source: 'osm',
        fetchedAt: DateTime.utc(2026, 8, 12, 21, 5),
      ),
    ],
    status: NearbySourceStatus.osm,
    fetchedAt: DateTime.utc(2026, 8, 12, 21, 5),
  );

  test('prefs cache survives a new instance', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final a = PrefsNearbyCache(prefs);
    await a.write(query, result);
    await a.writePoint(query, area);
    final b = PrefsNearbyCache(prefs);
    expect((await b.read(query))!.resources.single.name, 'Highland Pharmacy');
    expect((await b.readPoint(query))!.lat, closeTo(40.4862, 0.0001));
  });

  test('cached category reads back as the enum, not the chip label', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = PrefsNearbyCache(prefs);
    final clinic = NearbyFetchResult(
      resources: [
        NearbyResource(
          id: 'c1',
          name: 'Urgent Place',
          category: NearbyCategory.urgentCare,
          address: '1 Main St',
          lat: 40.4,
          lng: -74.4,
          source: 'osm',
          fetchedAt: DateTime.utc(2026, 8, 12),
        ),
      ],
      status: NearbySourceStatus.osm,
      fetchedAt: DateTime.utc(2026, 8, 12),
    );
    await cache.write(query, clinic);
    final raw =
        jsonDecode(prefs.getString(PrefsNearbyCache.resultKey(query))!) as Map;
    expect((raw['resources'] as List).single['category'], 'Urgent care');
    expect(
      (await cache.read(query))!.resources.single.category,
      NearbyCategory.urgentCare,
    );
  });

  test('an unknown cached category drops the saved copy', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = PrefsNearbyCache(prefs);
    await cache.write(query, result);
    final key = PrefsNearbyCache.resultKey(query);
    await prefs.setString(
      key,
      prefs.getString(key)!.replaceFirst('"Pharmacy"', '"Bakery"'),
    );
    expect(await cache.read(query), isNull);
  });
}
