import 'package:cwc_health_app/features/settings/app_preferences.dart';
import 'package:cwc_health_app/features/settings/shared_preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences whose remove reports false, as the platform does when
/// the write to disk fails.
class _RefusingPrefs implements SharedPreferences {
  final Map<String, Object> data = {'cwc.nearby.cache': 'saved'};
  var reloads = 0;

  @override
  Set<String> getKeys() => data.keys.toSet();

  @override
  Object? get(String key) => data[key];

  @override
  Future<bool> remove(String key) async => false;

  @override
  Future<void> reload() async => reloads++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('a remove the platform refuses throws instead of passing', () async {
    final prefs = _RefusingPrefs();
    final store = SharedPreferencesStore(prefs);

    await expectLater(store.remove('cwc.nearby.cache'), throwsStateError);
    expect(prefs.reloads, 1, reason: 'the cache is re-read from disk');
  });

  test('Erase keeps a key it could not remove and still notifies', () async {
    final prefs = _RefusingPrefs();
    final app = AppPreferences.fromStore(SharedPreferencesStore(prefs));
    var notified = 0;
    app.addListener(() => notified++);

    await expectLater(
      app.removeWhere((key) => key == 'cwc.nearby.cache'),
      throwsStateError,
    );
    expect(prefs.data, contains('cwc.nearby.cache'));
    expect(notified, 1);
  });
}
