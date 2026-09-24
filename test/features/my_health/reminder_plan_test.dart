import 'package:cwc_health_app/features/my_health/data/health_controller.dart';
import 'package:cwc_health_app/features/my_health/data/health_models.dart';
import 'package:cwc_health_app/features/my_health/data/health_store.dart';
import 'package:cwc_health_app/features/my_health/data/reminder_plan.dart';
import 'package:cwc_health_app/features/my_health/data/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 24, 9);

  test('medication reminder uses the saved name and schedule', () {
    const med = HealthMedication(
      id: 'm1',
      name: 'Metformin',
      purpose: 'Blood sugar',
      schedule: '1 tablet morning and evening with food',
      remind: true,
      remindMinutes: [8 * 60, 20 * 60],
    );
    final planned = planReminders(
      HealthSnapshot(medications: [med], initialized: true),
      now: now,
    );

    expect(planned, hasLength(2));
    expect(planned.every((r) => r.title == medicationReminderTitle), isTrue);
    expect(
      planned.every(
        (r) => r.body == 'Metformin. 1 tablet morning and evening with food',
      ),
      isTrue,
    );
    expect(planned.every((r) => r.repeatsDaily), isTrue);
    expect(planned.map((r) => r.fireAt).toSet(), {
      DateTime(2026, 9, 24, 20),
      DateTime(2026, 9, 25, 8),
    });
  });

  test('turning a reminder off or changing the time updates the plan', () {
    const med = HealthMedication(
      id: 'm1',
      name: 'Sertraline',
      purpose: 'Mood',
      schedule: '1 tablet each morning',
      remind: true,
      remindMinutes: [8 * 60],
    );
    final on = planReminders(
      HealthSnapshot(medications: [med], initialized: true),
      now: now,
    );
    expect(on.single.fireAt, DateTime(2026, 9, 25, 8));

    final moved = planReminders(
      HealthSnapshot(
        medications: [
          med.copyWith(remindMinutes: [21 * 60]),
        ],
        initialized: true,
      ),
      now: now,
    );
    expect(moved.single.fireAt, DateTime(2026, 9, 24, 21));
    expect(moved.single.id, isNot(on.single.id));

    final off = planReminders(
      HealthSnapshot(
        medications: [med.copyWith(remind: false)],
        initialized: true,
      ),
      now: now,
    );
    expect(off, isEmpty);
  });

  test('appointment reminder uses the saved visit and skips the past', () {
    final upcoming = HealthAppointment(
      id: 'a1',
      provider: 'Dr. Rivera',
      whenLabel: 'Wed, Sep 30, 2026 · 10:30 AM',
      location: 'Community Health Clinic',
      phone: '(732) 555-0198',
      remind: true,
      when: DateTime(2026, 9, 30, 10, 30),
    );
    final past = upcoming.copyWith(
      id: 'a2',
      whenLabel: 'Thu, Aug 7, 2026 · 10:30 AM',
      when: DateTime(2026, 8, 7, 10, 30),
      remindAt: DateTime(2026, 8, 7, 10, 30),
    );
    final planned = planReminders(
      HealthSnapshot(appointments: [upcoming, past], initialized: true),
      now: now,
    );

    expect(planned, hasLength(1));
    expect(planned.single.title, appointmentReminderTitle);
    expect(planned.single.body, contains('Dr. Rivera'));
    expect(planned.single.body, contains('Community Health Clinic'));
    expect(planned.single.repeatsDaily, isFalse);
    expect(planned.single.fireAt, DateTime(2026, 9, 30, 10, 30));
  });

  test('a different reminder time does not replace the saved visit', () {
    final appt = HealthAppointment(
      id: 'a1',
      provider: 'Dr. Lee',
      whenLabel: 'Wed, Sep 30, 2026 · 10:30 AM',
      location: 'Clinic',
      phone: '555',
      remind: true,
      when: DateTime(2026, 9, 30, 10, 30),
      remindAt: DateTime(2026, 9, 30, 8),
    );
    final planned = planReminders(
      HealthSnapshot(appointments: [appt], initialized: true),
      now: now,
    );
    expect(planned.single.fireAt, DateTime(2026, 9, 30, 8));
    expect(planned.single.body, contains('Dr. Lee'));
    expect(planned.single.body, contains('10:30 AM'));
  });

  test('schedule words and clock times become reminder minutes', () {
    expect(inferReminderMinutes('1 tablet morning and evening with food'), [
      8 * 60,
      20 * 60,
    ]);
    expect(inferReminderMinutes('1 tablet each morning'), [8 * 60]);
    expect(inferReminderMinutes('Take at 10:30 AM'), [10 * 60 + 30]);
    expect(inferReminderMinutes('As needed'), [8 * 60]);
  });

  test('appointment labels round-trip and older labels still parse', () {
    final dt = DateTime(2026, 10, 7, 14);
    expect(parseAppointmentWhen(formatAppointmentWhen(dt)), dt);
    expect(
      parseAppointmentWhen(
        'Thu, Aug 7 · 10:30 AM',
        yearFrom: DateTime(2026, 9, 24),
      ),
      DateTime(2026, 8, 7, 10, 30),
    );
  });

  test('reminder fields survive json', () {
    final appt = HealthAppointment(
      id: 'a1',
      provider: 'Dr. Lee',
      whenLabel: 'Wed, Sep 30, 2026 · 10:30 AM',
      location: 'Clinic',
      phone: '555',
      remind: true,
      when: DateTime(2026, 9, 30, 10, 30),
      remindAt: DateTime(2026, 9, 30, 8),
    );
    const med = HealthMedication(
      id: 'm1',
      name: 'Aspirin',
      purpose: 'Pain',
      schedule: 'As needed',
      remind: true,
      remindMinutes: [8 * 60],
    );
    final snap = HealthSnapshot(
      appointments: [appt],
      medications: [med],
      initialized: true,
    );
    final loaded = HealthSnapshot.fromJson(snap.toJson());
    expect(loaded.appointments.single.remindAt, DateTime(2026, 9, 30, 8));
    expect(loaded.medications.single.remindMinutes, [8 * 60]);
    expect(loaded.medications.single.name, 'Aspirin');
  });

  test('ids stay stable for the same saved record', () {
    expect(
      reminderNotificationId('med:m1:480'),
      reminderNotificationId('med:m1:480'),
    );
    expect(
      reminderNotificationId('med:m1:480'),
      isNot(reminderNotificationId('med:m1:1260')),
    );
  });

  schedulerTests();
}

class _MemoryPoster implements NotificationPoster {
  final scheduled = <int, ReminderRequest>{};
  final cancelled = <int>[];

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission({bool precise = false}) async => true;

  @override
  Future<bool> notificationsAllowed() async => true;

  @override
  Future<List<ScheduledReminder>> pending() async => [
    for (final entry in scheduled.entries)
      ScheduledReminder(id: entry.key, payload: entry.value.payload),
  ];

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
  }

  @override
  Future<void> schedule(ReminderRequest request) async {
    scheduled[request.id] = request;
  }
}

void schedulerTests() {
  test(
    'sync schedules the saved medication and cancels it when turned off',
    () async {
      final poster = _MemoryPoster();
      final scheduler = SyncingReminderScheduler(
        poster,
        clock: () => DateTime(2026, 9, 24, 9),
      );
      const med = HealthMedication(
        id: 'm1',
        name: 'Metformin',
        purpose: 'Blood sugar',
        schedule: '1 tablet each morning',
        remind: true,
        remindMinutes: [8 * 60],
      );
      await scheduler.sync(
        const HealthSnapshot(medications: [med], initialized: true),
      );
      expect(poster.scheduled.length, 1);
      expect(poster.scheduled.values.single.body, contains('Metformin'));

      await scheduler.sync(
        HealthSnapshot(
          medications: [med.copyWith(remind: false)],
          initialized: true,
        ),
      );
      expect(poster.scheduled, isEmpty);
      expect(poster.cancelled, isNotEmpty);
    },
  );

  test('changing the time cancels the previous alert', () async {
    final poster = _MemoryPoster();
    final scheduler = SyncingReminderScheduler(
      poster,
      clock: () => DateTime(2026, 9, 24, 9),
    );
    const med = HealthMedication(
      id: 'm1',
      name: 'Metformin',
      purpose: 'Blood sugar',
      schedule: '1 tablet each morning',
      remind: true,
      remindMinutes: [8 * 60],
    );
    await scheduler.sync(
      const HealthSnapshot(medications: [med], initialized: true),
    );
    final firstId = poster.scheduled.keys.single;

    await scheduler.sync(
      HealthSnapshot(
        medications: [
          med.copyWith(remindMinutes: [20 * 60]),
        ],
        initialized: true,
      ),
    );
    expect(poster.cancelled, contains(firstId));
    expect(poster.scheduled.keys.single, isNot(firstId));
    expect(poster.scheduled.values.single.fireAt, DateTime(2026, 9, 24, 20));
  });

  test(
    'controller schedules from the stored record and clears on erase',
    () async {
      final poster = _MemoryPoster();
      final scheduler = SyncingReminderScheduler(
        poster,
        clock: () => DateTime(2026, 9, 24, 9),
      );
      final controller = HealthController(
        InMemoryHealthStore(),
        reminders: scheduler,
      );
      await controller.load();
      await controller.eraseAll();
      expect(poster.scheduled, isEmpty);

      final med = HealthMedication(
        id: 'm1',
        name: 'Metformin',
        purpose: 'Blood sugar',
        schedule: '1 tablet each morning',
        remind: true,
        remindMinutes: [8 * 60],
      );
      await controller.upsertMedication(med);
      expect(controller.medications, hasLength(1));
      expect(poster.scheduled.values.single.body, contains('Metformin'));
      expect(poster.scheduled.values.single.body, contains(med.schedule));

      await controller.upsertMedication(med.copyWith(remind: false));
      expect(poster.scheduled, isEmpty);
      expect(controller.medications.single.name, 'Metformin');
    },
  );
}
