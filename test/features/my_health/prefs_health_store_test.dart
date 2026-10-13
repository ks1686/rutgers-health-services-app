import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cwc_health_app/features/my_health/data/health_models.dart';
import 'package:cwc_health_app/features/my_health/data/prefs_health_store.dart';

void main() {
  final sample = HealthSnapshot(
    appointments: [
      HealthAppointment(
        id: 'a1',
        provider: 'Dr. Rivera',
        whenLabel: 'Thu, Aug 7 · 10:30 AM',
        location: 'Community Health Clinic',
        phone: '(732) 555-0198',
        note: 'Bring medication list',
      ),
    ],
    medications: [
      HealthMedication(
        id: 'm1',
        name: 'Metformin',
        purpose: 'Blood sugar',
        schedule: '1 tablet morning and evening with food',
      ),
    ],
    providers: [
      HealthProvider(
        id: 'p1',
        name: 'Dr. Rivera',
        role: 'Primary care',
        phone: '(732) 555-0198',
        portalLabel: 'Clinic patient portal',
        portalUrl: 'https://example.com/portal',
      ),
    ],
    wallet: const HealthWallet(
      emergencyContact: 'Alex M. · (732) 555-0100',
      conditions: 'Diabetes · Anxiety',
    ),
    pinHash: 'abc123',
    initialized: true,
  );

  test('prefs health store survives a new instance', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final a = PrefsHealthStore(prefs);
    await a.write(sample);

    final b = PrefsHealthStore(prefs);
    final loaded = await b.read();
    expect(loaded.appointments.single.provider, 'Dr. Rivera');
    expect(loaded.medications.single.name, 'Metformin');
    expect(loaded.providers.single.portalUrl, 'https://example.com/portal');
    expect(loaded.wallet.emergencyContact, contains('Alex'));
    expect(loaded.pinHash, 'abc123');
    expect(loaded.initialized, isTrue);
  });

  test('erase clears personal data and pin', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = PrefsHealthStore(prefs);
    await store.write(sample);
    await store.erase();

    final loaded = await store.read();
    expect(loaded.appointments, isEmpty);
    expect(loaded.medications, isEmpty);
    expect(loaded.providers, isEmpty);
    expect(loaded.wallet.emergencyContact, '');
    expect(loaded.wallet.conditions, '');
    expect(loaded.pinHash, isNull);
    expect(loaded.initialized, isTrue);
  });

  test('old JSON without service animal keys keeps the other data', () async {
    SharedPreferences.setMockInitialValues({
      PrefsHealthStore.dataKey: jsonEncode({
        'appointments': [],
        'medications': [],
        'providers': [],
        'wallet': {'emergencyContact': 'Jordan', 'conditions': 'Asthma'},
        'emergencyCard': {'showEmergencyContact': true},
        'pinHash': 'abc123',
        'initialized': true,
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    final loaded = await PrefsHealthStore(prefs).read();
    expect(loaded.wallet.emergencyContact, 'Jordan');
    expect(loaded.wallet.conditions, 'Asthma');
    expect(loaded.wallet.serviceAnimal, '');
    expect(loaded.emergencyCard.showEmergencyContact, isTrue);
    expect(loaded.emergencyCard.showServiceAnimal, isFalse);
    expect(loaded.pinHash, 'abc123');
    expect(loaded.initialized, isTrue);
  });

  test('service animal round-trips in prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = PrefsHealthStore(prefs);
    await store.write(
      sample.copyWith(
        wallet: const HealthWallet(
          emergencyContact: 'Alex M. · (732) 555-0100',
          conditions: 'Diabetes · Anxiety',
          serviceAnimal: 'Service dog, Max. Please keep with me.',
        ),
        emergencyCard: const EmergencyCardChoices(showServiceAnimal: true),
      ),
    );
    final loaded = await PrefsHealthStore(prefs).read();
    expect(
      loaded.wallet.serviceAnimal,
      'Service dog, Max. Please keep with me.',
    );
    expect(loaded.emergencyCard.showServiceAnimal, isTrue);
    expect(loaded.providers.single.name, 'Dr. Rivera');
  });

  test('missing prefs reads as uninitialized empty snapshot', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final loaded = await PrefsHealthStore(prefs).read();
    expect(loaded.initialized, isFalse);
    expect(loaded.appointments, isEmpty);
  });
}
