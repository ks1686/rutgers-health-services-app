import 'package:flutter_test/flutter_test.dart';
import 'package:cwc_health_app/data/demo_resources.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_config.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_fetch_result.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_query.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_resource.dart';

void main() {
  group('NearbyConfig', () {
    test('fromEnvironment defaults live off and empty key', () {
      final config = NearbyConfig.fromEnvironment();
      expect(config.liveNearby, isFalse);
      expect(config.googlePlacesApiKey, isEmpty);
    });
  });

  group('NearbyCategory', () {
    test('labels match overlapping demo filter chips', () {
      expect(NearbyCategory.pharmacy.label, 'Pharmacy');
      expect(NearbyCategory.clinic.label, 'Clinic');
      expect(NearbyCategory.urgentCare.label, 'Urgent care');

      for (final category in NearbyCategory.values) {
        expect(
          demoCategories,
          contains(category.label),
          reason: '${category.label} must appear in demoCategories',
        );
      }
    });
  });

  group('NearbyQuery', () {
    test('defaults to New Brunswick, NJ', () {
      const query = NearbyQuery();
      expect(query.town, 'New Brunswick');
      expect(query.stateCode, 'NJ');
    });
  });

  group('NearbyFetchResult', () {
    test('carries resources, status, and timestamp', () {
      final fetchedAt = DateTime.utc(2026, 8, 11, 12);
      final resource = NearbyResource(
        id: 'osm-1',
        name: 'Sample Pharmacy',
        category: NearbyCategory.pharmacy.label,
        address: '1 College Ave, New Brunswick, NJ',
        lat: 40.4862,
        lng: -74.4518,
        openingHoursRaw: null,
        source: 'osm',
        fetchedAt: fetchedAt,
        phone: '(732) 555-0100',
      );

      final result = NearbyFetchResult(
        resources: [resource],
        status: NearbySourceStatus.osm,
        fetchedAt: fetchedAt,
        message: null,
      );

      expect(result.resources, hasLength(1));
      expect(result.resources.single.name, 'Sample Pharmacy');
      expect(result.status, NearbySourceStatus.osm);
      expect(result.fetchedAt, fetchedAt);
      expect(result.message, isNull);
    });
  });
}
