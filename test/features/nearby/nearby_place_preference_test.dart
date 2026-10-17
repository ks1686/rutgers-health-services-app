import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/nearby/data/nj_places.dart';
import 'package:cwc_health_app/features/settings/app_preferences.dart';

void main() {
  test('blank saved town falls back to New Brunswick', () {
    expect(NearbyPlacePreference.resolve(), NearbyPlacePreference.fallback);
    final place = NearbyPlacePreference.resolve(regionName: 'north', town: ' ');
    expect(place.region, NjRegion.central);
    expect(place.town, 'New Brunswick');
  });

  test('a listed town takes its own region over the saved one', () {
    final place = NearbyPlacePreference.resolve(
      regionName: 'north',
      town: 'Camden',
    );
    expect(place.region, NjRegion.south);
    expect(place.town, 'Camden');
  });

  test('a typed town not on the list is still the lookup', () {
    final place = NearbyPlacePreference.resolve(
      regionName: 'north',
      town: ' Frenchtown ',
    );
    expect(place.region, NjRegion.north);
    expect(place.town, 'Frenchtown');

    final noRegion = NearbyPlacePreference.resolve(town: 'Frenchtown');
    expect(noRegion.region, NjRegion.central);
  });

  test(
    'region and town survive a new preferences object on the same store',
    () async {
      final store = MemoryPreferenceStore();
      await AppPreferences.fromStore(store).setNearbyPlace(
        const NearbyPlacePreference(region: NjRegion.north, town: 'Newark'),
      );

      final place = AppPreferences.fromStore(store).nearbyPlace;
      expect(place.region, NjRegion.north);
      expect(place.town, 'Newark');
    },
  );

  test('saving a place notifies once with both values written', () async {
    final prefs = AppPreferences.fromStore(MemoryPreferenceStore());
    final seen = <NearbyPlacePreference>[];
    prefs.addListener(() => seen.add(prefs.nearbyPlace));
    await prefs.setNearbyPlace(
      const NearbyPlacePreference(region: NjRegion.south, town: 'Camden'),
    );
    expect(seen, hasLength(1));
    expect(seen.single.region, NjRegion.south);
    expect(seen.single.town, 'Camden');
  });
}
