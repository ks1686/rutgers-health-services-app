import 'package:flutter/widgets.dart';

import '../more/peer_contact.dart';
import '../nearby/data/nearby_place_preference.dart';
import '../nearby/data/nj_places.dart';

/// In-app text size on top of the phone's own text size (ACC-1).
enum TextSizeChoice { system, large, extraLarge }

const kTextSizePref = 'cwc_settings_text_scale';

/// Town Nearby uses when location is off. Same key as the Nearby town picker.
const kRememberedTownPref = PrefsNearbyPlacePreferenceStore.townPref;

const kHelperHidingPref = 'cwc_settings_helper_hiding';

/// People this member asks about the app. JSON list, on this phone only.
const kPeerContactsPref = 'cwc_peer_contacts';

TextSizeChoice textSizeFromStored(String? raw) {
  return switch (raw) {
    'large' => TextSizeChoice.large,
    'extraLarge' => TextSizeChoice.extraLarge,
    _ => TextSizeChoice.system,
  };
}

String textSizeToStored(TextSizeChoice choice) {
  return switch (choice) {
    TextSizeChoice.system => 'system',
    TextSizeChoice.large => 'large',
    TextSizeChoice.extraLarge => 'extraLarge',
  };
}

/// Multiplier applied on top of the operating-system text scaler.
double textScaleFactor(TextSizeChoice choice) {
  return switch (choice) {
    TextSizeChoice.system => 1,
    TextSizeChoice.large => 1.25,
    TextSizeChoice.extraLarge => 1.5,
  };
}

TextScaler combineTextScaler(TextScaler platform, TextSizeChoice choice) {
  return TextScaler.linear(platform.scale(1) * textScaleFactor(choice));
}

/// Empty or blank means Nearby keeps its default town.
String nearbyTownFromPreference(
  String? remembered, {
  String fallback = 'New Brunswick',
}) {
  final trimmed = remembered?.trim() ?? '';
  if (trimmed.isEmpty) return fallback;
  return trimmed;
}

/// On-device settings that are not My Health records.
class AppPreferences extends ChangeNotifier {
  AppPreferences(this._values);

  final Map<String, Object> _values;

  /// Test and app adapter. Production passes [SharedPreferences].
  factory AppPreferences.fromStore(PreferenceStore store) {
    return AppPreferences(store.values).._store = store;
  }

  PreferenceStore? _store;

  TextSizeChoice get textSize =>
      textSizeFromStored(_values[kTextSizePref] as String?);

  String get rememberedTown => (_values[kRememberedTownPref] as String?) ?? '';

  bool get helperHiding => (_values[kHelperHidingPref] as bool?) ?? false;

  List<PeerContact> get peerContacts =>
      peerContactsFromStored(_values[kPeerContactsPref] as String?);

  Future<void> setTextSize(TextSizeChoice choice) {
    return _set(kTextSizePref, textSizeToStored(choice));
  }

  Future<void> setRememberedTown(String town) async {
    final trimmed = town.trim();
    await _set(kRememberedTownPref, trimmed);
    final region = regionForTown(trimmed);
    if (region != null) {
      await _set(PrefsNearbyPlacePreferenceStore.regionPref, region.name);
    }
  }

  Future<void> setHelperHiding(bool value) {
    return _set(kHelperHidingPref, value);
  }

  Future<void> setPeerContacts(List<PeerContact> contacts) {
    return _set(kPeerContactsPref, peerContactsToStored(contacts));
  }

  Future<void> _set(String key, Object value) async {
    _values[key] = value;
    await _store?.write(key, value);
    notifyListeners();
  }
}

/// Small persistence seam so widget tests need no plugin channel.
abstract class PreferenceStore {
  Map<String, Object> get values;
  Future<void> write(String key, Object value);
}

class MemoryPreferenceStore implements PreferenceStore {
  MemoryPreferenceStore([Map<String, Object>? initial])
    : values = Map<String, Object>.from(initial ?? const {});

  @override
  final Map<String, Object> values;

  @override
  Future<void> write(String key, Object value) async {
    values[key] = value;
  }
}

class AppPreferencesScope extends InheritedNotifier<AppPreferences> {
  const AppPreferencesScope({
    super.key,
    required AppPreferences preferences,
    required super.child,
  }) : super(notifier: preferences);

  static AppPreferences of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppPreferencesScope>();
    assert(scope != null, 'AppPreferencesScope not found');
    return scope!.notifier!;
  }

  static AppPreferences? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppPreferencesScope>()
        ?.notifier;
  }
}
