import 'dart:convert';

import 'package:cwc_health_app/features/my_health/appointment_form_screen.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_models.dart';
import 'package:cwc_health_app/features/my_health/data/secure_health_store.dart';
import 'package:cwc_health_app/features/my_health/data/secure_string_store.dart';
import 'package:cwc_health_app/features/my_health/health_scope.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/failing_stores.dart';

HealthAppointment _appt(String id) => HealthAppointment(
  id: id,
  provider: 'Test Provider $id',
  whenLabel: 'Thu',
  location: 'Test Clinic',
  phone: '',
);

void main() {
  group('H2 controller saves', () {
    test('a failed write keeps the old state and reports false', () async {
      final store = FlakyHealthStore();
      final c = HealthController(store);
      await c.load();
      expect(await c.upsertAppointment(_appt('a1')), isTrue);

      store.failWrites = true;
      final ok = await c.upsertAppointment(_appt('a2'));
      expect(ok, isFalse);
      expect(c.appointments.map((a) => a.id), ['a1']);
      expect(store.saved.appointments.map((a) => a.id), ['a1']);
    });

    test('a failed delete keeps the record', () async {
      final store = FlakyHealthStore();
      final c = HealthController(store);
      await c.load();
      await c.upsertAppointment(_appt('a1'));
      store.failWrites = true;
      expect(await c.deleteAppointment('a1'), isFalse);
      expect(c.appointments, hasLength(1));
    });

    test('back to back saves do not lose either change', () async {
      final c = HealthController(FlakyHealthStore());
      await c.load();
      await Future.wait([
        c.updateEmergencyCardWith((e) => e.copyWith(showConditions: true)),
        c.updateEmergencyCardWith((e) => e.copyWith(showMedications: true)),
      ]);
      expect(c.emergencyCard.showConditions, isTrue);
      expect(c.emergencyCard.showMedications, isTrue);
    });

    test('a failed load blocks writes so saved data is not replaced', () async {
      final store = BrokenHealthStore();
      final c = HealthController(store);
      await c.load();
      expect(c.ready, isTrue);
      expect(c.storageUnavailable, isTrue);
      expect(await c.upsertAppointment(_appt('a1')), isFalse);
      expect(store.writes, 0);
    });

    test('total document size is capped', () async {
      final c = HealthController(FlakyHealthStore());
      await c.load();
      final big = base64Encode(List.filled(HealthDocument.maxFileBytes, 1));
      var saved = 0;
      for (var i = 0; i < 10; i++) {
        final doc = HealthDocument(
          id: 'd$i',
          kind: HealthDocumentKind.otherPaper,
          title: 'Paper $i',
          body: '',
          fileName: 'p$i.pdf',
          fileBase64: big,
        );
        if (!c.documentFits(doc)) break;
        expect(await c.upsertDocument(doc), isTrue);
        saved++;
      }
      expect(saved, lessThan(10));
      final total = c.documents.fold<int>(
        0,
        (sum, d) => sum + (d.fileBase64?.length ?? 0),
      );
      expect(total, lessThanOrEqualTo(HealthController.maxTotalFileChars));
      final extra = HealthDocument(
        id: 'extra',
        kind: HealthDocumentKind.otherPaper,
        title: 'Too much',
        body: '',
        fileName: 'x.pdf',
        fileBase64: big,
      );
      expect(await c.upsertDocument(extra), isFalse);
    });
  });

  group('H2 decode', () {
    test('a wrongly shaped saved record does not throw', () async {
      final secure = MemorySecureStringStore();
      await secure.write(
        SecureHealthStore.dataKey,
        jsonEncode({
          'appointments': [
            {'id': 5, 'provider': true},
          ],
          'initialized': 'yes',
        }),
      );
      final store = SecureHealthStore(secure);
      final snap = await store.read();
      expect(snap.appointments, isEmpty);
      // The unreadable text is kept aside, not thrown away.
      expect(await secure.read(SecureHealthStore.unreadableKey), isNotNull);
      await store.erase();
      expect(await secure.read(SecureHealthStore.unreadableKey), isNull);
    });
  });

  testWidgets('H2 appointment form shows Could not save and stays open', (
    tester,
  ) async {
    final store = FlakyHealthStore();
    final c = HealthController(store);
    await c.load();
    store.failWrites = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: HealthScope(controller: c, child: const AppointmentFormScreen()),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, 'Dr. Test');
    await tester.enterText(find.byType(TextFormField).at(1), 'Thursday');
    await tester.enterText(find.byType(TextFormField).at(2), 'Test Clinic');
    await tester.enterText(find.byType(TextFormField).at(3), '555 010 0000');
    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not save'), findsOneWidget);
    expect(find.byType(AppointmentFormScreen), findsOneWidget);
    expect(c.appointments, isEmpty);
  });
}
