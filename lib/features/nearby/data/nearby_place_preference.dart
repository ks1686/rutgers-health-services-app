import 'package:shared_preferences/shared_preferences.dart';

import 'nj_places.dart';

/// On-device region and town for Nearby. No GPS and no identity.
abstract class NearbyPlacePreferenceStore {
  Future<NearbyPlacePreference> read();
  Future<void> save(NearbyPlacePreference preference);
}

class PrefsNearbyPlacePreferenceStore implements NearbyPlacePreferenceStore {
  PrefsNearbyPlacePreferenceStore(this._prefs);

  final SharedPreferences _prefs;

  static const regionPref = 'nearby.v1.place.region';
  static const townPref = 'nearby.v1.place.town';

  @override
  Future<NearbyPlacePreference> read() async {
    final town = _prefs.getString(townPref)?.trim() ?? '';
    if (town.isEmpty) return NearbyPlacePreference.fallback;
    final listed = regionForTown(town);
    if (listed != null) {
      return NearbyPlacePreference(region: listed, town: town);
    }
    // A town typed in Settings is still the lookup, even if it is not on
    // the short picker list. [NearbyPlacePreference.resolve] stays strict.
    return NearbyPlacePreference(
      region:
          NjRegion.tryParse(_prefs.getString(regionPref)) ?? NjRegion.central,
      town: town,
    );
  }

  @override
  Future<void> save(NearbyPlacePreference preference) async {
    await _prefs.setString(regionPref, preference.region.name);
    await _prefs.setString(townPref, preference.town);
  }
}

Future<NearbyPlacePreferenceStore> nearbyPlacePreferenceStore({
  NearbyPlacePreferenceStore? injected,
}) async {
  if (injected != null) return injected;
  final prefs = await SharedPreferences.getInstance();
  return PrefsNearbyPlacePreferenceStore(prefs);
}
