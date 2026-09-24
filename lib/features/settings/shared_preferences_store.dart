import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences.dart';

class SharedPreferencesStore implements PreferenceStore {
  SharedPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  Map<String, Object> get values => {
    for (final key in _prefs.getKeys())
      if (_prefs.get(key) case final Object value) key: value,
  };

  @override
  Future<void> write(String key, Object value) async {
    switch (value) {
      case final bool flag:
        await _prefs.setBool(key, flag);
      case final String text:
        await _prefs.setString(key, text);
      case final int number:
        await _prefs.setInt(key, number);
      case final double number:
        await _prefs.setDouble(key, number);
      default:
        await _prefs.setString(key, value.toString());
    }
  }
}

Future<AppPreferences> loadAppPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  return AppPreferences.fromStore(SharedPreferencesStore(prefs));
}
