import 'health_models.dart';
import 'reminder_plan.dart';

/// Schedules on-device alerts from the My Health snapshot. No network.
abstract class ReminderScheduler {
  Future<void> sync(HealthSnapshot snapshot);

  /// Asks the phone to show alerts. [precise] also asks Android for exact alarms.
  Future<bool> requestPermission({bool precise = false});

  Future<bool> notificationsAllowed();
}

/// Used in tests and whenever the phone cannot schedule alerts.
class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  Future<void> sync(HealthSnapshot snapshot) async {}

  @override
  Future<bool> requestPermission({bool precise = false}) async => true;

  @override
  Future<bool> notificationsAllowed() async => true;
}

class ScheduledReminder {
  const ScheduledReminder({required this.id, this.payload});

  final int id;
  final String? payload;
}

/// Platform piece behind [SyncingReminderScheduler].
abstract class NotificationPoster {
  Future<void> init();

  Future<bool> requestPermission({bool precise = false});

  Future<bool> notificationsAllowed();

  Future<List<ScheduledReminder>> pending();

  Future<void> cancel(int id);

  Future<void> schedule(ReminderRequest request);
}

/// Replaces the phone's pending My Health alerts with [planReminders].
class SyncingReminderScheduler implements ReminderScheduler {
  SyncingReminderScheduler(this._poster, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final NotificationPoster _poster;
  final DateTime Function() _clock;
  var _ready = false;

  Future<void> _ensure() async {
    if (_ready) return;
    await _poster.init();
    _ready = true;
  }

  @override
  Future<void> sync(HealthSnapshot snapshot) async {
    await _ensure();
    final planned = planReminders(snapshot, now: _clock());
    final pending = await _poster.pending();
    final wanted = {for (final request in planned) request.id};
    for (final old in pending) {
      final payload = old.payload ?? '';
      if (payload.startsWith(reminderPayloadPrefix) &&
          !wanted.contains(old.id)) {
        await _poster.cancel(old.id);
      }
    }
    for (final request in planned) {
      await _poster.schedule(request);
    }
  }

  @override
  Future<bool> requestPermission({bool precise = false}) async {
    await _ensure();
    return _poster.requestPermission(precise: precise);
  }

  @override
  Future<bool> notificationsAllowed() async {
    await _ensure();
    return _poster.notificationsAllowed();
  }
}
