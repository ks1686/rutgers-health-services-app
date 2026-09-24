import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cwc_health_app/features/nearby/data/nearby_place_preference.dart';
import 'package:cwc_health_app/features/nearby/data/nj_places.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unknown saved town falls back to New Brunswick', () {
    final place = NearbyPlacePreference.resolve(
      regionName: 'north',
      town: 'Atlantis',
    );
    expect(place.region, NjRegion.central);
    expect(place.town, 'New Brunswick');
  });

  test('region and town survive a new store on the same prefs', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final first = PrefsNearbyPlacePreferenceStore(
      await SharedPreferences.getInstance(),
    );
    await first.save(
      const NearbyPlacePreference(region: NjRegion.north, town: 'Newark'),
    );

    final second = PrefsNearbyPlacePreferenceStore(
      await SharedPreferences.getInstance(),
    );
    final place = await second.read();
    expect(place.region, NjRegion.north);
    expect(place.town, 'Newark');
  });
}
