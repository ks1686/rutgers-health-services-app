import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../data/demo_health.dart';
import 'health_models.dart';
import 'health_store.dart';

/// Owns My Health state for the shell. Local-only; never syncs.
class HealthController extends ChangeNotifier {
  HealthController(this._store);

  final HealthStore _store;

  HealthSnapshot _snapshot = const HealthSnapshot();
  bool _ready = false;
  bool _unlocked = false;
  String? _error;

  HealthSnapshot get snapshot => _snapshot;
  bool get ready => _ready;
  bool get hasPin => _snapshot.hasPin;
  bool get isUnlocked => !_snapshot.hasPin || _unlocked;
  String? get error => _error;

  List<HealthAppointment> get appointments => _snapshot.appointments;
  List<HealthMedication> get medications => _snapshot.medications;
  List<HealthProvider> get providers => _snapshot.providers;
  List<HealthDocument> get documents => _snapshot.documents;
  HealthWallet get wallet => _snapshot.wallet;
  EmergencyCardChoices get emergencyCard => _snapshot.emergencyCard;

  /// App-local salt — not a secret; slows casual plaintext prefs snooping.
  static const _pinSalt = 'cwc-health-pin-v1';

  /// Study-build PIN fingerprint (not keystore encryption — PRIV-4 follow-on).
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
        snap = _seedFromDemo();
        await _store.write(snap);
      }
      _snapshot = snap;
      _unlocked = !snap.hasPin;
      _ready = true;
    } catch (e) {
      _error = 'Could not load My Health.';
      _ready = true;
    }
    notifyListeners();
  }

  HealthSnapshot _seedFromDemo() {
    return HealthSnapshot(
      appointments: [
        for (var i = 0; i < demoAppointments.length; i++)
          HealthAppointment(
            id: 'seed-appt-$i',
            provider: demoAppointments[i].provider,
            whenLabel: demoAppointments[i].whenLabel,
            location: demoAppointments[i].location,
            phone: demoAppointments[i].phone,
            note: demoAppointments[i].note,
          ),
      ],
      medications: [
        for (var i = 0; i < demoMedications.length; i++)
          HealthMedication(
            id: 'seed-med-$i',
            name: demoMedications[i].name,
            purpose: demoMedications[i].purpose,
            schedule: demoMedications[i].schedule,
          ),
      ],
      providers: [
        for (var i = 0; i < demoProviders.length; i++)
          HealthProvider(
            id: 'seed-prov-$i',
            name: demoProviders[i].name,
            role: demoProviders[i].role,
            phone: demoProviders[i].phone,
            portalLabel: demoProviders[i].portalLabel,
            portalUrl: demoProviders[i].portalLabel == null
                ? null
                : 'https://example.com/portal',
          ),
      ],
      wallet: const HealthWallet(
        emergencyContact: demoWalletEmergencyContact,
        conditions: demoWalletConditions,
      ),
      initialized: true,
    );
  }

  Future<void> _persist(HealthSnapshot next) async {
    _snapshot = next;
    await _store.write(next);
    notifyListeners();
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

  /// PRIV-5 — clears personal My Health data (and PIN). Does not re-seed.
  Future<void> eraseAll() async {
    await _store.erase();
    _snapshot = const HealthSnapshot(initialized: true);
    _unlocked = true;
    notifyListeners();
  }

  static bool _validPin(String pin) {
    if (pin.length < 4 || pin.length > 8) return false;
    return RegExp(r'^\d+$').hasMatch(pin);
  }
}
