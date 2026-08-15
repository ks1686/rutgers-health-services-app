import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/nearby/data/nearby_launchers.dart';

void main() {
  test('sms and tel strip decoration', () {
    expect(nearbyTelUri('(732) 555-0142').toString(), 'tel:7325550142');
    expect(nearbySmsUri('+1-732-555-0142').scheme, 'sms');
    expect(nearbySmsUri('+1-732-555-0142').path, '17325550142');
  });

  test('web directions use OSM, not Google', () {
    final uri = nearbyDirectionsUri(
      lat: 40.4862,
      lng: -74.4518,
      name: 'Highland Pharmacy',
      isWeb: true,
    );
    expect(uri.host, 'www.openstreetmap.org');
    expect(uri.toString(), isNot(contains('google.com')));
  });

  test('io directions use geo:', () {
    expect(
      nearbyDirectionsUri(
        lat: 40.4862,
        lng: -74.4518,
        name: 'Highland Pharmacy',
        isWeb: false,
      ).scheme,
      'geo',
    );
  });
}
