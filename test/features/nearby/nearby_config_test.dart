import 'package:flutter_test/flutter_test.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_config.dart';

void main() {
  test('fromEnvironment defaults live off and empty key', () {
    final config = NearbyConfig.fromEnvironment();
    expect(config.liveNearby, isFalse);
    expect(config.googlePlacesApiKey, isEmpty);
  });
}
