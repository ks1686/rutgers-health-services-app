import 'package:cwc_health_app/app.dart';
import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_models.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:cwc_health_app/features/my_health/data/reminder_plan.dart';
import 'package:cwc_health_app/features/my_health/data/reminder_scheduler.dart';
import 'package:cwc_health_app/features/onboarding/disclaimer_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/stub_nearby.dart';

class _RecordingScheduler implements ReminderScheduler {
  HealthSnapshot? last;
  bool lastSuppress = false;

  @override
  Future<void> sync(HealthSnapshot snapshot, {bool suppress = false}) async {
    last = snapshot;
    lastSuppress = suppress;
  }

  @override
  Future<bool> requestPermission({bool precise = false}) async => true;

  @override
  Future<bool> notificationsAllowed() async => true;
}

/// The app ships no sample records, so tests seed their own.
Future<void> _seedTestData(HealthController health) async {
  await health.upsertAppointment(
    HealthAppointment(
      id: 'test-appt-1',
      provider: 'Test Provider',
      whenLabel: 'Thu, Aug 7 · 10:30 AM',
      location: 'Test Clinic',
      phone: '(555) 010-0000',
    ),
  );
  await health.upsertAppointment(
    HealthAppointment(
      id: 'test-appt-2',
      provider: 'Test Provider Two',
      whenLabel: 'Mon, Aug 11 · 2:00 PM',
      location: 'Test Clinic',
      phone: '(555) 010-0000',
    ),
  );
  await health.upsertMedication(
    HealthMedication(
      id: 'test-med-1',
      name: 'Test Medicine',
      purpose: 'Test purpose',
      schedule: '1 tablet morning and evening with food',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester, HealthController health) async {
    SharedPreferences.setMockInitialValues({disclaimerAckPref: true});
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      CwcApp(
        healthController: health,
        nearbyRepository: StubNearbyRepository(result: stubNearbyResult()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('saved medication reminder does not ask for the medicine again', (
    tester,
  ) async {
    final scheduler = _RecordingScheduler();
    final health = HealthController(
      InMemoryHealthStore(),
      reminders: scheduler,
    );
    await health.load();
    await _seedTestData(health);
    await pump(tester, health);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Test Medicine'), 300);
    await tester.tap(find.text('Test Medicine'));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(nameField.controller?.text, 'Test Medicine');

    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Remind me on this phone'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('8:00 AM'), findsOneWidget);
    expect(find.textContaining('8:00 PM'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final metformin = health.medications.where(
      (m) => m.name == 'Test Medicine',
    );
    expect(metformin, hasLength(1));
    expect(metformin.single.remind, isTrue);
    expect(metformin.single.remindMinutes, [8 * 60, 20 * 60]);
    expect(metformin.single.purpose, 'Test purpose');

    final planned = planReminders(
      scheduler.last!,
      now: DateTime(2026, 9, 24, 9),
    );
    expect(planned, hasLength(2));
    expect(
      planned.every((r) => r.body == 'Time for a medication reminder'),
      isTrue,
    );
    expect(planned.every((r) => r.body.contains('Test Medicine')), isFalse);
    expect(
      planned.every(
        (r) => r.body.contains('1 tablet morning and evening with food'),
      ),
      isFalse,
    );
  });

  testWidgets('More changes a saved reminder without a new form', (
    tester,
  ) async {
    final scheduler = _RecordingScheduler();
    final health = HealthController(
      InMemoryHealthStore(),
      reminders: scheduler,
    );
    await health.load();
    await _seedTestData(health);
    final before = health.medications.length;
    await pump(tester, health);

    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Notifications'), 300);
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Test Medicine'), findsOneWidget);
    expect(find.text('Test Provider'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('reminder-med-test-med-1')));
    await tester.pumpAndSettle();

    expect(health.medications, hasLength(before));
    final metformin = health.medications.firstWhere(
      (m) => m.id == 'test-med-1',
    );
    expect(metformin.name, 'Test Medicine');
    expect(metformin.remind, isTrue);
    expect(metformin.schedule, '1 tablet morning and evening with food');

    final planned = planReminders(
      scheduler.last!,
      now: DateTime(2026, 9, 24, 9),
    );
    expect(
      planned.every((r) => r.body == 'Time for a medication reminder'),
      isTrue,
    );
    expect(planned.every((r) => r.body.contains('Test Medicine')), isFalse);
  });

  testWidgets('turning an appointment reminder off keeps the visit', (
    tester,
  ) async {
    final health = HealthController(
      InMemoryHealthStore(),
      reminders: _RecordingScheduler(),
    );
    await health.load();
    await _seedTestData(health);
    final appt = health.appointments.first;
    await health.upsertAppointment(
      appt.copyWith(
        remind: true,
        when: DateTime(2026, 10, 1, 10, 30),
        remindAt: DateTime(2026, 10, 1, 9),
      ),
    );
    await pump(tester, health);

    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text(appt.provider), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.tap(find.byKey(ValueKey('reminder-appt-${appt.id}')));
    await tester.pumpAndSettle();

    final saved = health.appointments.firstWhere((a) => a.id == appt.id);
    expect(saved.remind, isFalse);
    expect(saved.provider, appt.provider);
    expect(saved.whenLabel, appt.whenLabel);
    expect(saved.location, appt.location);
    expect(health.appointments, hasLength(2));
  });

  testWidgets('helper mode hides notification names and pauses alerts', (
    tester,
  ) async {
    final scheduler = _RecordingScheduler();
    final health = HealthController(
      InMemoryHealthStore(),
      reminders: scheduler,
    );
    await health.load();
    await _seedTestData(health);
    await pump(tester, health);

    Future<void> openMore() async {
      await tester.tap(find.byKey(const ValueKey('tab-more')));
      await tester.pumpAndSettle();
    }

    await openMore();
    await tester.scrollUntilVisible(find.text('Helper Mode'), 300);
    await tester.tap(find.text('Helper Mode'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('helper-hide-switch')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();
    expect(scheduler.lastSuppress, isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Notifications'), 300);
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Test Medicine'), findsNothing);
    expect(find.text('Test Provider'), findsNothing);
    expect(
      find.textContaining('Hidden while someone is helping you.'),
      findsWidgets,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Helper Mode'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('helper-hide-switch')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();
    expect(scheduler.lastSuppress, isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Test Medicine'), findsOneWidget);
    expect(find.text('Test Provider'), findsWidgets);
  });
}
