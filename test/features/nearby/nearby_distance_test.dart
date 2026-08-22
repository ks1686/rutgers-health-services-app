import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/nearby/data/nearby_distance.dart';

void main() {
  group('nearbyDistanceMeters', () {
    test('same point is zero', () {
      expect(
        nearbyDistanceMeters(
          fromLat: 40.5,
          fromLng: -74.4,
          toLat: 40.5,
          toLng: -74.4,
        ),
        0,
      );
    });

    test('one degree of latitude is about 111 km', () {
      final meters = nearbyDistanceMeters(
        fromLat: 40.0,
        fromLng: -74.0,
        toLat: 41.0,
        toLng: -74.0,
      );
      expect(meters, closeTo(111195, 200));
    });

    test('symmetric for swapped points', () {
      final a = nearbyDistanceMeters(
        fromLat: 40.4862,
        fromLng: -74.4518,
        toLat: 40.52,
        toLng: -74.47,
      );
      final b = nearbyDistanceMeters(
        fromLat: 40.52,
        fromLng: -74.47,
        toLat: 40.4862,
        toLng: -74.4518,
      );
      expect(a, closeTo(b, 1));
    });
  });

  group('nearbyWalkMinutes', () {
    test('rounds meters at 80 m per minute', () {
      expect(nearbyWalkMinutes(134), 2);
      expect(nearbyWalkMinutes(400), 5);
      expect(nearbyWalkMinutes(1600), 20);
    });

    test('never shows zero minutes', () {
      expect(nearbyWalkMinutes(10), 1);
      expect(nearbyWalkMinutes(0), 1);
    });
  });
}
