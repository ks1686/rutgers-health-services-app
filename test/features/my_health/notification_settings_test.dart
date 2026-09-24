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

class _RecordingScheduler implements ReminderScheduler {
  HealthSnapshot? last;

  @override
  Future<void> sync(HealthSnapshot snapshot) async {
    last = snapshot;
  }

  @override
  Future<bool> requestPermission({bool precise = false}) async => true;

  @override
  Future<bool> notificationsAllowed() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester, HealthController health) async {
    SharedPreferences.setMockInitialValues({disclaimerAckPref: true});
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(CwcApp(healthController: health));
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
    await pump(tester, health);

    await tester.tap(find.byKey(const ValueKey('tab-my-health')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Metformin'), 300);
    await tester.tap(find.text('Metformin'));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(nameField.controller?.text, 'Metformin');

    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Remind me on this phone'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('8:00 AM'), findsOneWidget);
    expect(find.textContaining('8:00 PM'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final metformin = health.medications.where((m) => m.name == 'Metformin');
    expect(metformin, hasLength(1));
    expect(metformin.single.remind, isTrue);
    expect(metformin.single.remindMinutes, [8 * 60, 20 * 60]);
    expect(metformin.single.purpose, 'Blood sugar');

    final planned = planReminders(
      scheduler.last!,
      now: DateTime(2026, 9, 24, 9),
    );
    expect(planned, hasLength(2));
    expect(planned.every((r) => r.body.contains('Metformin')), isTrue);
    expect(
      planned.every(
        (r) => r.body.contains('1 tablet morning and evening with food'),
      ),
      isTrue,
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
    final before = health.medications.length;
    await pump(tester, health);

    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Notifications'), 300);
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Metformin'), findsOneWidget);
    expect(find.text('Dr. Rivera'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('reminder-med-seed-med-0')));
    await tester.pumpAndSettle();

    expect(health.medications, hasLength(before));
    final metformin = health.medications.firstWhere(
      (m) => m.id == 'seed-med-0',
    );
    expect(metformin.name, 'Metformin');
    expect(metformin.remind, isTrue);
    expect(metformin.schedule, '1 tablet morning and evening with food');

    final planned = planReminders(
      scheduler.last!,
      now: DateTime(2026, 9, 24, 9),
    );
    expect(planned.every((r) => r.body.contains('Metformin')), isTrue);
  });

  testWidgets('turning an appointment reminder off keeps the visit', (
    tester,
  ) async {
    final health = HealthController(
      InMemoryHealthStore(),
      reminders: _RecordingScheduler(),
    );
    await health.load();
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
}
