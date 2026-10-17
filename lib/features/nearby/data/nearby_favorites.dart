import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nearby_resource.dart';

/// Place ids the person marked on this phone. No GPS and no account.
const nearbyFavoritesPref = 'nearby.v1.favoriteIds';

/// Notifies after [toggle] and [clear], so a Nearby tab kept alive behind
/// another tab redraws its stars when Erase runs.
abstract class NearbyFavoriteStore extends ChangeNotifier {
  Future<Set<String>> read();
  Future<Set<String>> toggle(String id);
  Future<void> clear();
}

class PrefsNearbyFavoriteStore extends NearbyFavoriteStore {
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
    notifyListeners();
    return next;
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(nearbyFavoritesPref);
    notifyListeners();
  }
}

class MemoryNearbyFavoriteStore extends NearbyFavoriteStore {
  MemoryNearbyFavoriteStore([Iterable<String> ids = const []])
    : _ids = {...ids};

  final Set<String> _ids;

  @override
  Future<Set<String>> read() async => {..._ids};

  @override
  Future<Set<String>> toggle(String id) async {
    if (!_ids.add(id)) _ids.remove(id);
    notifyListeners();
    return {..._ids};
  }

  @override
  Future<void> clear() async {
    _ids.clear();
    notifyListeners();
  }
}

/// The app's one favorite store. The Nearby tab and Erase both use it, so
/// nothing else opens [nearbyFavoritesPref].
class NearbyFavoritesScope extends InheritedWidget {
  const NearbyFavoritesScope({
    super.key,
    required this.store,
    required super.child,
  });

  final NearbyFavoriteStore store;

  static NearbyFavoriteStore? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NearbyFavoritesScope>()
        ?.store;
  }

  @override
  bool updateShouldNotify(NearbyFavoritesScope oldWidget) {
    return store != oldWidget.store;
  }
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
