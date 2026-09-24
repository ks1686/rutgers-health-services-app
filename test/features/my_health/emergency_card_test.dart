import 'package:cwc_health_app/features/my_health/data/emergency_card.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_models.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const pad = HealthDocument(
    id: 'pad-1',
    kind: HealthDocumentKind.pad,
    title: 'My psychiatric advance directive',
    body: 'Do not restrain me.',
  );
  const med = HealthMedication(
    id: 'med-1',
    name: 'Sertraline',
    purpose: 'Mood',
    schedule: 'morning',
  );

  HealthSnapshot privateSnapshot() {
    return const HealthSnapshot(
      medications: [med],
      documents: [pad],
      wallet: HealthWallet(emergencyContact: 'Jordan P.', conditions: 'Asthma'),
      appointments: [
        HealthAppointment(
          id: 'a1',
          provider: 'Dr. Rivera',
          whenLabel: 'Thu',
          location: 'Clinic',
          phone: '555',
          note: 'Bring the private note',
        ),
      ],
      initialized: true,
    );
  }

  test('the card shares nothing until a field is chosen', () {
    final text = emergencyCardPreview(privateSnapshot());
    expect(privateSnapshot().emergencyCard.sharesAnything, isFalse);
    expect(text, contains('Nothing from My Health'));
    expect(text, isNot(contains('Sertraline')));
    expect(text, isNot(contains('Do not restrain me')));
    expect(text, isNot(contains('Asthma')));
    expect(text, isNot(contains('Jordan')));
    expect(text, isNot(contains('Bring the private note')));
  });

  test('a chosen PAD shows while medications and notes stay off', () async {
    final store = InMemoryHealthStore();
    final health = HealthController(store);
    await health.load();
    await health.eraseAll();
    await health.upsertDocument(pad);
    await health.updateEmergencyCard(
      const EmergencyCardChoices(showPsychiatricAdvanceDirective: true),
    );
    await health.setPin('1234');
    health.lock();

    expect(health.isUnlocked, isFalse);
    final text = emergencyCardPreview(health.snapshot);
    expect(text, contains('Do not restrain me.'));
    expect(text, contains('My psychiatric advance directive'));
    expect(text, isNot(contains('Sertraline')));
    expect(text, isNot(contains('Bring the private note')));

    final again = HealthController(store);
    await again.load();
    expect(again.emergencyCard.showPsychiatricAdvanceDirective, isTrue);
    expect(again.emergencyCard.showMedications, isFalse);
  });

  test('an older save without card choices stays private', () {
    final snap = HealthSnapshot.fromJson({
      'appointments': [],
      'medications': [],
      'providers': [],
      'wallet': {'emergencyContact': 'Jordan', 'conditions': 'Asthma'},
      'initialized': true,
    });
    expect(snap.emergencyCard.sharesAnything, isFalse);
    expect(emergencyCardPreview(snap), isNot(contains('Jordan')));
    expect(emergencyCardPreview(snap), isNot(contains('Asthma')));
  });

  test('erase removes the card choices with the rest of My Health', () async {
    final store = InMemoryHealthStore();
    final health = HealthController(store);
    await health.load();
    await health.updateEmergencyCard(
      const EmergencyCardChoices(showEmergencyContact: true),
    );
    await health.eraseAll();
    expect(health.emergencyCard.sharesAnything, isFalse);
    final again = HealthController(store);
    await again.load();
    expect(again.emergencyCard.sharesAnything, isFalse);
  });
}
