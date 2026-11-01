import '../help_now/help_now_screen.dart' show helpNowEmergencyCardPref;
import '../my_health/data/prefs_health_store.dart';
import '../my_health/data/secure_health_store.dart';
import '../nearby/data/nearby_favorites.dart' show nearbyFavoritesPref;
import '../onboarding/disclaimer_prefs.dart' show disclaimerAckPref;
import 'app_preferences.dart';

/// Where a value lives on the phone.
enum LocalDataPlace {
  /// Plain app settings storage (SharedPreferences).
  preferences,

  /// The phone's secure storage (Keystore or Keychain).
  secureStorage,
}

/// One thing this app keeps on the phone, and whether Erase removes it.
class LocalDataEntry {
  const LocalDataEntry(
    this.key, {
    required this.what,
    required this.erase,
    this.place = LocalDataPlace.preferences,
    this.isPrefix = false,
  });

  final String key;

  /// Plain words for what this holds.
  final String what;

  /// True for anything about the person. False for app settings such as
  /// text size, which Erase leaves alone.
  final bool erase;

  final LocalDataPlace place;

  /// True when [key] starts a family of keys, such as one per town.
  final bool isPrefix;

  bool matches(String storedKey) =>
      isPrefix ? storedKey.startsWith(key) : storedKey == key;
}

/// M1. Every key this app writes, in one place. Erase my information uses
/// this list, and a test fails if code adds a key that is not listed here.
const kLocalDataRegistry = <LocalDataEntry>[
  // My Health. HealthController.eraseAll removes the secure copies.
  LocalDataEntry(
    SecureHealthStore.dataKey,
    what: 'My Health records, PIN, and reminders',
    erase: true,
    place: LocalDataPlace.secureStorage,
  ),
  LocalDataEntry(
    SecureHealthStore.unreadableKey,
    what: 'A My Health record the app could not read',
    erase: true,
    place: LocalDataPlace.secureStorage,
  ),
  LocalDataEntry(
    PrefsHealthStore.dataKey,
    what: 'My Health from an older build, before secure storage',
    erase: true,
  ),
  LocalDataEntry(
    kPeerContactsPref,
    what: 'People saved under Ask a Peer',
    erase: true,
  ),
  LocalDataEntry(
    kSessionAnswersPref,
    what: 'Session question answers',
    erase: true,
  ),
  LocalDataEntry(
    kRememberedTownPref,
    what: 'The town picked for Nearby',
    erase: true,
  ),
  LocalDataEntry(
    kRememberedRegionPref,
    what: 'The region picked for Nearby',
    erase: true,
  ),
  LocalDataEntry(nearbyFavoritesPref, what: 'Saved nearby places', erase: true),
  LocalDataEntry(
    'nearby.v1.result.',
    what: 'Nearby results saved for each town searched',
    erase: true,
    isPrefix: true,
  ),
  LocalDataEntry(
    'nearby.v1.point.',
    what: 'Map points for each town searched',
    erase: true,
    isPrefix: true,
  ),
  LocalDataEntry(
    helpNowEmergencyCardPref,
    what: 'Whether Help Now shows the emergency card',
    erase: true,
  ),
  // App settings. Kept so the app still reads the way the person set it.
  LocalDataEntry(kTextSizePref, what: 'Text size', erase: false),
  LocalDataEntry(
    kHelperHidingPref,
    what: 'Hide details when someone is helping',
    erase: false,
  ),
  LocalDataEntry(
    disclaimerAckPref,
    what: 'The first-screen agreement was read',
    erase: false,
  ),
];

/// True when Erase my information should remove the settings key
/// [storedKey]. Keys not in the registry are kept, and the registry test
/// keeps that list complete.
bool erasedOnRequest(String storedKey) => kLocalDataRegistry.any(
  (entry) =>
      entry.erase &&
      entry.place == LocalDataPlace.preferences &&
      entry.matches(storedKey),
);
