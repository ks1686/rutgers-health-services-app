import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/settings/app_preferences.dart';
import 'package:cwc_health_app/features/settings/local_data_registry.dart';

/// Ids that look like storage keys but are not stored values.
const _notStorage = {
  // Android notification channel and iOS category id.
  'cwc_my_health_reminders',
};

Iterable<String> _libSources() sync* {
  for (final file in Directory('lib').listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      yield file.readAsStringSync();
    }
  }
}

void main() {
  test('M1 every storage key in lib is in the local data registry', () {
    final keyLike = RegExp(r"'((?:cwc_|nearby\.v1\.|health\.v1\.)[^'$]*)");
    final literalCall = RegExp(
      r"\.(?:get|set|remove|containsKey)\w*\(\s*'([^']+)'",
    );
    final found = <String>{};
    for (final source in _libSources()) {
      found.addAll(keyLike.allMatches(source).map((m) => m.group(1)!));
      found.addAll(literalCall.allMatches(source).map((m) => m.group(1)!));
    }
    found.removeAll(_notStorage);
    expect(found, isNotEmpty);

    final missing = [
      for (final key in found)
        if (!kLocalDataRegistry.any(
          (e) => e.matches(key) || (e.isPrefix && e.key == key),
        ))
          key,
    ];
    expect(missing, isEmpty, reason: 'add these to kLocalDataRegistry');
  });

  test('M1 Erase removes personal keys and keeps settings', () {
    expect(erasedOnRequest(kPeerContactsPref), isTrue);
    expect(erasedOnRequest('nearby.v1.result.camden|NJ'), isTrue);
    expect(erasedOnRequest('health.v1.snapshot'), isTrue);
    expect(erasedOnRequest(kTextSizePref), isFalse);
    expect(erasedOnRequest(kHelperHidingPref), isFalse);
    expect(erasedOnRequest('some.other.plugin.key'), isFalse);
  });

  test('M1 removeWhere also finds keys written after startup', () async {
    final store = MemoryPreferenceStore({kTextSizePref: 'large'});
    final prefs = AppPreferences.fromStore(store);
    await store.write('nearby.v1.point.camden|NJ', '{}');
    await prefs.setRememberedTown('Camden');
    var notified = 0;
    prefs.addListener(() => notified++);

    await prefs.removeWhere(erasedOnRequest);

    expect(store.values.keys, [kTextSizePref]);
    expect(prefs.rememberedTown, isEmpty);
    expect(notified, 1);
  });
}
