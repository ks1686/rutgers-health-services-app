import 'package:shared_preferences/shared_preferences.dart';

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
    final shared = prefs ?? await SharedPreferences.getInstance();
    await migrateLegacyPrefsIfNeeded(secure: secure, prefs: shared);
    return secure;
  }

  /// Copies plaintext prefs → secure store once, then deletes the prefs key.
  static Future<void> migrateLegacyPrefsIfNeeded({
    required HealthStore secure,
    required SharedPreferences prefs,
  }) async {
    final legacyRaw = prefs.getString(PrefsHealthStore.dataKey);
    if (legacyRaw == null) return;

    final legacy = PrefsHealthStore(prefs);
    final legacySnap = await legacy.read();
    final secureSnap = await secure.read();

    final legacyHasPersonal =
        legacySnap.appointments.isNotEmpty ||
        legacySnap.medications.isNotEmpty ||
        legacySnap.providers.isNotEmpty ||
        legacySnap.wallet.emergencyContact.isNotEmpty ||
        legacySnap.wallet.conditions.isNotEmpty ||
        legacySnap.hasPin;

    if (!secureSnap.initialized &&
        (legacySnap.initialized || legacyHasPersonal)) {
      await secure.write(legacySnap.copyWith(initialized: true));
    }

    // Always remove plaintext after we have had a chance to migrate.
    await prefs.remove(PrefsHealthStore.dataKey);
  }
}
