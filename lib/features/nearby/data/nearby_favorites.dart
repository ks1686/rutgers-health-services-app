import 'package:shared_preferences/shared_preferences.dart';

import 'nearby_resource.dart';

/// Place ids the person marked on this phone. No GPS and no account.
const nearbyFavoritesPref = 'nearby.v1.favoriteIds';

abstract class NearbyFavoriteStore {
  Future<Set<String>> read();
  Future<Set<String>> toggle(String id);
  Future<void> clear();
}

class PrefsNearbyFavoriteStore implements NearbyFavoriteStore {
  PrefsNearbyFavoriteStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<Set<String>> read() async {
    return _prefs.getStringList(nearbyFavoritesPref)?.toSet() ?? {};
  }

  @override
  Future<Set<String>> toggle(String id) async {
    final next = await read();
    if (!next.add(id)) next.remove(id);
    await _prefs.setStringList(nearbyFavoritesPref, next.toList()..sort());
    return next;
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(nearbyFavoritesPref);
  }
}

class MemoryNearbyFavoriteStore implements NearbyFavoriteStore {
  MemoryNearbyFavoriteStore([Iterable<String> ids = const []])
    : _ids = {...ids};

  final Set<String> _ids;

  @override
  Future<Set<String>> read() async => {..._ids};

  @override
  Future<Set<String>> toggle(String id) async {
    if (!_ids.add(id)) _ids.remove(id);
    return {..._ids};
  }

  @override
  Future<void> clear() async => _ids.clear();
}

Future<NearbyFavoriteStore> nearbyFavoriteStore({
  NearbyFavoriteStore? injected,
}) async {
  if (injected != null) return injected;
  final prefs = await SharedPreferences.getInstance();
  return PrefsNearbyFavoriteStore(prefs);
}

Future<void> clearNearbyFavorites() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(nearbyFavoritesPref);
}

/// Saved places stay in their relative order and move ahead of the rest.
List<NearbyResource> nearbyFavoritesFirst(
  List<NearbyResource> resources,
  Set<String> favoriteIds,
) {
  if (favoriteIds.isEmpty) return resources;
  final saved = <NearbyResource>[];
  final rest = <NearbyResource>[];
  for (final resource in resources) {
    (favoriteIds.contains(resource.id) ? saved : rest).add(resource);
  }
  return [...saved, ...rest];
}
