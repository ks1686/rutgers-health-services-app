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
  bool _storageUnavailable = false;
  String? _error;

  /// Saves run one at a time so a quick second change builds on the first.
  Future<void> _saveQueue = Future<void>.value();

  HealthSnapshot get snapshot => _snapshot;
  bool get ready => _ready;
  bool get hasPin => _snapshot.hasPin;
  bool get isUnlocked => !_snapshot.hasPin || _unlocked;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => _snapshot.biometricEnabled;
  String? get error => _error;

  /// True when the saved record could not be opened at all. My Health then
  /// shows a notice and refuses to save, so an empty screen never replaces
  /// what is already on the phone. Help Now, Nearby, and Learn still work.
  bool get storageUnavailable => _storageUnavailable;

  /// Files share one encrypted record, so their combined size is capped.
  /// About 3 MB of base64 text, which is roughly 2.25 MB of files.
  static const maxTotalFileChars = 3 * 1024 * 1024;

  /// Whether [document] fits in the file budget next to the other papers.
  bool documentFits(HealthDocument document) =>
      _fileChars(_withItem(documents, document, (row) => row.id)) <=
      maxTotalFileChars;

  static int _fileChars(List<HealthDocument> docs) =>
      docs.fold(0, (sum, d) => sum + (d.fileBase64?.length ?? 0));

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
      _storageUnavailable = true;
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

  /// Writes first and only then shows the change. Returns false, leaving the
  /// screen and the saved record as they were, when the write fails.
  Future<bool> _persist(
    HealthSnapshot Function(HealthSnapshot current) change,
  ) {
    final result = _saveQueue.then((_) => _apply(change));
    _saveQueue = result.then<void>((_) {});
    return result;
  }

  Future<bool> _apply(
    HealthSnapshot Function(HealthSnapshot current) change,
  ) async {
    if (_storageUnavailable) return false;
    try {
      final next = change(_snapshot);
      await _store.write(next);
      _snapshot = next;
    } catch (e) {
      if (kDebugMode) debugPrint('My Health save failed: $e');
      return false;
    }
    notifyListeners();
    await _syncReminders();
    return true;
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

  Future<bool> upsertAppointment(HealthAppointment appointment) {
    return _persist(
      (current) => current.copyWith(
        appointments: _withItem(
          current.appointments,
          appointment,
          (row) => row.id,
        ),
      ),
    );
  }

  Future<bool> deleteAppointment(String id) {
    return _persist(
      (current) => current.copyWith(
        appointments: _withoutId(current.appointments, id, (row) => row.id),
      ),
    );
  }

  Future<bool> upsertMedication(HealthMedication medication) {
    return _persist(
      (current) => current.copyWith(
        medications: _withItem(
          current.medications,
          medication,
          (row) => row.id,
        ),
      ),
    );
  }

  Future<bool> deleteMedication(String id) {
    return _persist(
      (current) => current.copyWith(
        medications: _withoutId(current.medications, id, (row) => row.id),
      ),
    );
  }

  Future<bool> upsertProvider(HealthProvider provider) {
    return _persist(
      (current) => current.copyWith(
        providers: _withItem(current.providers, provider, (row) => row.id),
      ),
    );
  }

  Future<bool> deleteProvider(String id) {
    return _persist(
      (current) => current.copyWith(
        providers: _withoutId(current.providers, id, (row) => row.id),
      ),
    );
  }

  /// Returns false without saving when the files would pass
  /// [maxTotalFileChars].
  Future<bool> upsertDocument(HealthDocument document) async {
    var tooLarge = false;
    final ok = await _persist((current) {
      final docs = _withItem(current.documents, document, (row) => row.id);
      if (_fileChars(docs) > maxTotalFileChars) {
        tooLarge = true;
        throw StateError('My Health files are over the size limit.');
      }
      return current.copyWith(documents: docs);
    });
    return ok && !tooLarge;
  }

  Future<bool> deleteDocument(String id) {
    return _persist(
      (current) => current.copyWith(
        documents: _withoutId(current.documents, id, (row) => row.id),
      ),
    );
  }

  List<T> _withItem<T>(List<T> current, T item, String Function(T row) idOf) {
    final list = [...current];
    final id = idOf(item);
    final index = list.indexWhere((row) => idOf(row) == id);
    if (index >= 0) {
      list[index] = item;
    } else {
      list.add(item);
    }
    return list;
  }

  List<T> _withoutId<T>(
    List<T> current,
    String id,
    String Function(T row) idOf,
  ) {
    return [
      for (final row in current)
        if (idOf(row) != id) row,
    ];
  }

  Future<bool> updateWallet(HealthWallet wallet) {
    return _persist((current) => current.copyWith(wallet: wallet));
  }

  Future<bool> updateEmergencyCard(EmergencyCardChoices choices) {
    return _persist((current) => current.copyWith(emergencyCard: choices));
  }

  /// Applies [change] to the choices as saved at the moment the write runs,
  /// so two quick switch taps both stick.
  Future<bool> updateEmergencyCardWith(
    EmergencyCardChoices Function(EmergencyCardChoices current) change,
  ) {
    return _persist(
      (current) =>
          current.copyWith(emergencyCard: change(current.emergencyCard)),
    );
  }

  /// Sets or replaces the optional My Health PIN (ONB-3). Digits only, 4–8.
  Future<bool> setPin(String pin) async {
    if (!_validPin(pin)) return false;
    final saved = await _persist(
      (current) => current.copyWith(pinHash: hashPin(pin)),
    );
    if (!saved) return false;
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

  Future<bool> clearPin() async {
    final saved = await _persist(
      (current) => current.copyWith(clearPinHash: true),
    );
    if (!saved) return false;
    _unlocked = true;
    notifyListeners();
    return true;
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
    return _persist((current) => current.copyWith(biometricEnabled: true));
  }

  Future<bool> disableBiometricUnlock() async {
    if (!_snapshot.biometricEnabled) return true;
    return _persist((current) => current.copyWith(biometricEnabled: false));
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
  ///
  /// Returns false, keeping the records on screen, if the phone refused.
  Future<bool> eraseAll() async {
    final erased = _saveQueue.then((_) async {
      try {
        await _store.erase();
        return true;
      } catch (e) {
        if (kDebugMode) debugPrint('My Health erase failed: $e');
        return false;
      }
    });
    _saveQueue = erased.then<void>((_) {});
    if (!await erased) return false;
    _snapshot = const HealthSnapshot(initialized: true);
    _unlocked = true;
    notifyListeners();
    await _syncReminders();
    return true;
  }

  /// Digits only, 4 to 8 of them.
  static bool isValidPin(String pin) => _validPin(pin);

  static bool _validPin(String pin) {
    if (pin.length < 4 || pin.length > 8) return false;
    return RegExp(r'^\d+$').hasMatch(pin);
  }
}
