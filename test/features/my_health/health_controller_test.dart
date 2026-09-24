import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/my_health/data/document_file_picker.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_models.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';

void main() {
  test('first load seeds demo sample once', () async {
    final store = InMemoryHealthStore();
    final a = HealthController(store);
    await a.load();
    expect(a.appointments, isNotEmpty);
    expect(a.medications, isNotEmpty);
    expect(a.providers, isNotEmpty);
    expect(a.wallet.emergencyContact, isNotEmpty);

    await a.deleteAppointment(a.appointments.first.id);
    final remaining = a.appointments.length;

    final b = HealthController(store);
    await b.load();
    expect(b.appointments.length, remaining);
  });

  test('erase clears data and does not re-seed', () async {
    final store = InMemoryHealthStore();
    final c = HealthController(store);
    await c.load();
    await c.upsertDocument(
      HealthDocument(
        id: 'paper-1',
        kind: HealthDocumentKind.pad,
        title: 'My PAD',
        body: 'Do not take me to that hospital.',
      ),
    );
    expect(c.documents, isNotEmpty);

    await c.eraseAll();
    expect(c.appointments, isEmpty);
    expect(c.medications, isEmpty);
    expect(c.documents, isEmpty);
    expect(c.hasPin, isFalse);

    final again = HealthController(store);
    await again.load();
    expect(again.appointments, isEmpty);
  });

  test('PIN set unlock and wrong pin', () async {
    final c = HealthController(InMemoryHealthStore());
    await c.load();
    expect(await c.setPin('12'), isFalse);
    expect(await c.setPin('1234'), isTrue);
    expect(c.hasPin, isTrue);
    expect(c.isUnlocked, isTrue);

    c.lock();
    expect(c.isUnlocked, isFalse);
    expect(await c.unlock('9999'), isFalse);
    expect(await c.unlock('1234'), isTrue);
    expect(c.isUnlocked, isTrue);

    await c.clearPin();
    expect(c.hasPin, isFalse);
    expect(c.isUnlocked, isTrue);
  });

  test('CRUD appointment medication provider', () async {
    final c = HealthController(InMemoryHealthStore());
    await c.load();
    await c.eraseAll();

    final appt = HealthAppointment(
      id: HealthController.newId(),
      provider: 'Dr. Lee',
      whenLabel: 'Mon · 9:00 AM',
      location: 'Clinic',
      phone: '555',
    );
    await c.upsertAppointment(appt);
    expect(c.appointments.single.provider, 'Dr. Lee');
    await c.upsertAppointment(appt.copyWith(note: 'Fasting'));
    expect(c.appointments.single.note, 'Fasting');
    await c.deleteAppointment(appt.id);
    expect(c.appointments, isEmpty);

    final med = HealthMedication(
      id: HealthController.newId(),
      name: 'Aspirin',
      purpose: 'Pain',
      schedule: 'As needed',
    );
    await c.upsertMedication(med);
    await c.deleteMedication(med.id);
    expect(c.medications, isEmpty);

    final prov = HealthProvider(
      id: HealthController.newId(),
      name: 'Pharmacy',
      role: 'Pharmacy',
      phone: '555',
      portalUrl: 'https://example.com',
    );
    await c.upsertProvider(prov);
    expect(c.providers.single.portalUrl, 'https://example.com');
    await c.deleteProvider(prov.id);
    expect(c.providers, isEmpty);

    final paper = HealthDocument(
      id: HealthController.newId(),
      kind: HealthDocumentKind.chargeIt,
      title: 'Charge It notes',
      body: 'The workbook pages I use.',
    );
    await c.upsertDocument(paper);
    expect(c.documents.single.kind, HealthDocumentKind.chargeIt);
    await c.upsertDocument(
      paper.copyWith(kind: HealthDocumentKind.ratPlan, title: 'My RAT plan'),
    );
    expect(c.documents.single.title, 'My RAT plan');
    expect(c.documents.single.kind, HealthDocumentKind.ratPlan);
    await c.deleteDocument(paper.id);
    expect(c.documents, isEmpty);
  });

  test(
    'a file from the phone stays in the locked record and erase removes it',
    () async {
      final store = InMemoryHealthStore();
      final c = HealthController(store);
      await c.load();
      await c.eraseAll();

      final picked = paperFileFromBytes(
        name: 'living-will.pdf',
        bytes: Uint8List.fromList(const [1, 2, 3, 4]),
      );
      expect(picked, isNotNull);
      await c.upsertDocument(
        HealthDocument(
          id: 'file-1',
          kind: HealthDocumentKind.livingWill,
          title: 'Living will',
          body: '',
          fileName: picked!.name,
          fileBase64: base64Encode(picked.bytes),
        ),
      );

      final again = HealthController(store);
      await again.load();
      expect(again.documents.single.fileName, 'living-will.pdf');
      expect(base64Decode(again.documents.single.fileBase64!), [1, 2, 3, 4]);

      await again.eraseAll();
      expect(again.documents, isEmpty);
      final afterErase = HealthController(store);
      await afterErase.load();
      expect(afterErase.documents, isEmpty);
    },
  );

  test('a file over 500 KB is refused before it is stored', () {
    expect(
      () => paperFileFromBytes(
        name: 'big.pdf',
        bytes: Uint8List(HealthDocument.maxFileBytes + 1),
      ),
      throwsA(isA<PaperFileTooLarge>()),
    );
  });

  test('older snapshots without papers still load', () {
    final snap = HealthSnapshot.fromJson({
      'appointments': [],
      'medications': [],
      'providers': [],
      'wallet': {'emergencyContact': '', 'conditions': ''},
      'initialized': true,
    });
    expect(snap.documents, isEmpty);
  });
}
