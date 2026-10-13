import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'biometric_unlock.dart';
import 'health_models.dart';
import 'health_store.dart';
import 'reminder_scheduler.dart';

/// Owns My Health state for the shell. Local-only; never syncs to a server.
class HealthController extends ChangeNotifier {
  HealthController(
    this._store, {
    ReminderScheduler? reminders,
    BiometricAuthenticator? biometrics,
  }) : _reminders = reminders ?? const NoopReminderScheduler(),
       _biometrics = biometrics ?? const UnavailableBiometricAuthenticator();

  final HealthStore _store;
  final ReminderScheduler _reminders;
  final BiometricAuthenticator _biometrics;

  HealthSnapshot _snapshot = const HealthSnapshot();
  bool _ready = false;
  bool _unlocked = false;
  bool _biometricAvailable = false;
  bool _suppressReminders = false;
  String? _error;

  HealthSnapshot get snapshot => _snapshot;
  bool get ready => _ready;
  bool get hasPin => _snapshot.hasPin;
  bool get isUnlocked => !_snapshot.hasPin || _unlocked;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => _snapshot.biometricEnabled;
  String? get error => _error;

  List<HealthAppointment> get appointments => _snapshot.appointments;
  List<HealthMedication> get medications => _snapshot.medications;
  List<HealthProvider> get providers => _snapshot.providers;
  List<HealthDocument> get documents => _snapshot.documents;
  HealthWallet get wallet => _snapshot.wallet;
  EmergencyCardChoices get emergencyCard => _snapshot.emergencyCard;

  /// App-local salt, not a secret. Slows casual plaintext prefs snooping.
  static const _pinSalt = 'cwc-health-pin-v1';

  /// Study-build PIN fingerprint (not keystore encryption, PRIV-4 follow-on).
  /// Uses 32-bit FNV-1a so dart2js / web compile stays valid (no >53-bit ints).
  static String hashPin(String pin) {
    final bytes = utf8.encode('$_pinSalt:$pin');
    var hash = 0x811c9dc5;
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String newId() =>
      DateTime.now().toUtc().microsecondsSinceEpoch.toString();

  Future<void> load() async {
    _error = null;
    try {
      var snap = await _store.read();
      if (!snap.initialized) {
        snap = _emptySeed();
        await _store.write(snap);
      }
      _snapshot = snap;
      _unlocked = !snap.hasPin;
      _biometricAvailable = await _biometrics.isAvailable();
      _ready = true;
      notifyListeners();
      await _syncReminders();
      return;
    } catch (e) {
      _error = 'Could not load My Health.';
      _ready = true;
    }
    notifyListeners();
  }

  /// First launch starts empty. There is no bundled sample record: a seeded
  /// appointment or medication would look like the person's real health
  /// history, and a seeded phone number would ring a stranger or nobody.
  /// Everything here is typed in by the person on their own phone.
  HealthSnapshot _emptySeed() {
    return const HealthSnapshot(initialized: true);
  }

  Future<void> _persist(HealthSnapshot next) async {
    _snapshot = next;
    await _store.write(next);
    notifyListeners();
    await _syncReminders();
  }

  /// Cancels pending My Health alerts while Helper Mode is on, then restores
  /// them from the saved records when it is turned off.
  Future<void> setRemindersSuppressed(bool value) async {
    if (_suppressReminders == value) return;
    _suppressReminders = value;
    if (_ready) await _syncReminders();
  }

  Future<void> _syncReminders() async {
    try {
      await _reminders.sync(_snapshot, suppress: _suppressReminders);
    } catch (_) {
      // The saved record stays. The next launch tries the phone alert again.
    }
  }

  /// Asks this phone for permission to show My Health alerts.
  Future<bool> requestReminderPermission({bool precise = false}) async {
    try {
      return await _reminders.requestPermission(precise: precise);
    } catch (_) {
      return false;
    }
  }

  Future<bool> remindersAllowed() async {
    try {
      return await _reminders.notificationsAllowed();
    } catch (_) {
      return false;
    }
  }

  Future<void> upsertAppointment(HealthAppointment appointment) async {
    final list = [..._snapshot.appointments];
    final i = list.indexWhere((a) => a.id == appointment.id);
    if (i >= 0) {
      list[i] = appointment;
    } else {
      list.add(appointment);
    }
    await _persist(_snapshot.copyWith(appointments: list));
  }

  Future<void> deleteAppointment(String id) async {
    await _persist(
      _snapshot.copyWith(
        appointments: [
          for (final a in _snapshot.appointments)
            if (a.id != id) a,
        ],
      ),
    );
  }

  Future<void> upsertMedication(HealthMedication medication) async {
    final list = [..._snapshot.medications];
    final i = list.indexWhere((m) => m.id == medication.id);
    if (i >= 0) {
      list[i] = medication;
    } else {
      list.add(medication);
    }
    await _persist(_snapshot.copyWith(medications: list));
  }

  Future<void> deleteMedication(String id) async {
    await _persist(
      _snapshot.copyWith(
        medications: [
          for (final m in _snapshot.medications)
            if (m.id != id) m,
        ],
      ),
    );
  }

  Future<void> upsertProvider(HealthProvider provider) async {
    final list = [..._snapshot.providers];
    final i = list.indexWhere((p) => p.id == provider.id);
    if (i >= 0) {
      list[i] = provider;
    } else {
      list.add(provider);
    }
    await _persist(_snapshot.copyWith(providers: list));
  }

  Future<void> deleteProvider(String id) async {
    await _persist(
      _snapshot.copyWith(
        providers: [
          for (final p in _snapshot.providers)
            if (p.id != id) p,
        ],
      ),
    );
  }

  Future<void> upsertDocument(HealthDocument document) async {
    final list = [..._snapshot.documents];
    final i = list.indexWhere((d) => d.id == document.id);
    if (i >= 0) {
      list[i] = document;
    } else {
      list.add(document);
    }
    await _persist(_snapshot.copyWith(documents: list));
  }

  Future<void> deleteDocument(String id) async {
    await _persist(
      _snapshot.copyWith(
        documents: [
          for (final d in _snapshot.documents)
            if (d.id != id) d,
        ],
      ),
    );
  }

  Future<void> updateWallet(HealthWallet wallet) async {
    await _persist(_snapshot.copyWith(wallet: wallet));
  }

  Future<void> updateEmergencyCard(EmergencyCardChoices choices) async {
    await _persist(_snapshot.copyWith(emergencyCard: choices));
  }

  /// Sets or replaces the optional My Health PIN (ONB-3). Digits only, 4–8.
  Future<bool> setPin(String pin) async {
    if (!_validPin(pin)) return false;
    await _persist(_snapshot.copyWith(pinHash: hashPin(pin)));
    _unlocked = true;
    notifyListeners();
    return true;
  }

  Future<bool> unlock(String pin) async {
    if (!_snapshot.hasPin) {
      _unlocked = true;
      notifyListeners();
      return true;
    }
    if (hashPin(pin) != _snapshot.pinHash) return false;
    _unlocked = true;
    notifyListeners();
    return true;
  }

  void lock() {
    if (!_snapshot.hasPin) return;
    _unlocked = false;
    notifyListeners();
  }

  Future<void> clearPin() async {
    await _persist(_snapshot.copyWith(clearPinHash: true));
    _unlocked = true;
    notifyListeners();
  }

  /// Turns fingerprint unlock on only after one successful check.
  ///
  /// Failure, cancel, and lockout leave the toggle off. The PIN stays.
  Future<bool> enableBiometricUnlock() async {
    if (!hasPin) return false;
    _biometricAvailable = await _biometrics.isAvailable();
    if (!_biometricAvailable) {
      notifyListeners();
      return false;
    }
    final result = await _biometrics.authenticate();
    if (result != BiometricResult.success) return false;
    await _persist(_snapshot.copyWith(biometricEnabled: true));
    return true;
  }

  Future<void> disableBiometricUnlock() async {
    if (!_snapshot.biometricEnabled) return;
    await _persist(_snapshot.copyWith(biometricEnabled: false));
  }

  /// Unlocks My Health when fingerprint is already enabled and the check works.
  ///
  /// Any other result leaves the tab locked so the PIN can still open it.
  Future<BiometricResult> unlockWithBiometric() async {
    if (!hasPin || !_snapshot.biometricEnabled) {
      return BiometricResult.unavailable;
    }
    final result = await _biometrics.authenticate();
    if (result == BiometricResult.success) {
      _unlocked = true;
      notifyListeners();
    }
    return result;
  }

  /// PRIV-5. Clears personal My Health data (and PIN). Does not re-seed.
  Future<void> eraseAll() async {
    await _store.erase();
    _snapshot = const HealthSnapshot(initialized: true);
    _unlocked = true;
    notifyListeners();
    await _syncReminders();
  }

  static bool _validPin(String pin) {
    if (pin.length < 4 || pin.length > 8) return false;
    return RegExp(r'^\d+$').hasMatch(pin);
  }
}
