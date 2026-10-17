import 'package:cwc_health_app/features/nearby/data/nearby_favorites.dart';
import 'package:cwc_health_app/features/nearby/data/nearby_resource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  NearbyResource place(String id) {
    return NearbyResource(
      id: id,
      name: id,
      category: 'Pharmacy',
      address: '1 Main St',
      lat: 40.4,
      lng: -74.4,
      source: 'osm',
      fetchedAt: DateTime.utc(2026, 10, 15),
    );
  }

  test('saved places keep their order and move ahead of the rest', () {
    final rows = [place('a'), place('b'), place('c')];
    expect(nearbyFavoritesFirst(rows, {'c', 'a'}).map((r) => r.id), [
      'a',
      'c',
      'b',
    ]);
    expect(nearbyFavoritesFirst(rows, {}), same(rows));
  });

  test('a favorite toggles and clears on this phone', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = PrefsNearbyFavoriteStore(prefs);
    var notified = 0;
    store.addListener(() => notified++);

    expect(await store.read(), isEmpty);
    expect(await store.toggle('osm-1'), {'osm-1'});
    expect(await store.toggle('osm-2'), {'osm-1', 'osm-2'});
    expect(await store.toggle('osm-1'), {'osm-2'});

    await store.clear();
    expect(prefs.getStringList(nearbyFavoritesPref), isNull);
    expect(await store.read(), isEmpty);
    expect(notified, 4);
  });
}
