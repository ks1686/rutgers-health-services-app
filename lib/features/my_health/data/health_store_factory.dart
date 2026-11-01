import 'package:shared_preferences/shared_preferences.dart';

import 'health_models.dart';
import 'health_store.dart';
import 'platform_secure_string_store.dart';
import 'prefs_health_store.dart';
import 'secure_health_store.dart';
import 'secure_string_store.dart';

/// Builds the on-device My Health store: Keystore/Keychain first, one-time
/// migration off plaintext SharedPreferences, then wipe the legacy key.
class HealthStoreFactory {
  /// Production path (Android / iOS).
  static Future<HealthStore> openSecure({
    SecureStringStore? secureStrings,
    SharedPreferences? prefs,
  }) async {
    final secure = SecureHealthStore(
      secureStrings ?? PlatformSecureStringStore(),
    );
    final shared = prefs ?? await _tryPrefs();
    // Without app settings there is nothing to migrate. The secure record
    // still opens.
    if (shared != null) {
      await migrateLegacyPrefsIfNeeded(secure: secure, prefs: shared);
    }
    return secure;
  }

  static Future<SharedPreferences?> _tryPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  /// Copies plaintext prefs into the secure store once, then deletes the
  /// prefs key. The plaintext copy is deleted only after the secure store
  /// holds it, or already holds personal data of its own.
  static Future<void> migrateLegacyPrefsIfNeeded({
    required HealthStore secure,
    required SharedPreferences prefs,
  }) async {
    final legacyRaw = prefs.getString(PrefsHealthStore.dataKey);
    if (legacyRaw == null) return;

    final legacy = PrefsHealthStore(prefs);
    final legacySnap = await legacy.read();
    final HealthSnapshot secureSnap;
    try {
      secureSnap = await secure.read();
    } on UnreadableHealthRecord {
      // Keep the plaintext copy. It may be the only readable one left.
      return;
    }

    final legacyHasPersonal = _hasPersonal(legacySnap);
    // An empty secure record can be one that load() made on a launch when
    // the app settings would not open, so the legacy copy still wins.
    final secureIsEmpty = !secureSnap.initialized || !_hasPersonal(secureSnap);
    final copy =
        (!secureSnap.initialized &&
            (legacySnap.initialized || legacyHasPersonal)) ||
        (secureIsEmpty && legacyHasPersonal);
    if (copy) {
      // A failed write throws here, so the plaintext copy is kept.
      await secure.write(legacySnap.copyWith(initialized: true));
    }

    await prefs.remove(PrefsHealthStore.dataKey);
  }

  static bool _hasPersonal(HealthSnapshot snap) =>
      snap.appointments.isNotEmpty ||
      snap.medications.isNotEmpty ||
      snap.providers.isNotEmpty ||
      snap.documents.isNotEmpty ||
      snap.wallet.emergencyContact.isNotEmpty ||
      snap.wallet.conditions.isNotEmpty ||
      snap.wallet.serviceAnimal.isNotEmpty ||
      snap.hasPin;
}
