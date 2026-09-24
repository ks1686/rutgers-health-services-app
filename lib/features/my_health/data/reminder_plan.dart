import 'dart:convert';

import 'health_models.dart';

/// Payload prefix for alerts this app scheduled. Used to cancel stale ones.
const reminderPayloadPrefix = 'cwc-reminder:';

const medicationReminderTitle = 'Take your medication';
const appointmentReminderTitle = 'You have an appointment today';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

final _clockTime = RegExp(
  r'\b(\d{1,2})(?::(\d{2}))?\s*([ap])\.?m\.?\b',
  caseSensitive: false,
);

final _whenLabel = RegExp(
  r'^(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun), '
  r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) '
  r'(\d{1,2})(?:, (\d{4}))? · '
  r'(\d{1,2}):(\d{2}) (AM|PM)$',
);

/// One on-device notification built from a saved My Health record.
class ReminderRequest {
  const ReminderRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.fireAt,
    required this.repeatsDaily,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final DateTime fireAt;
  final bool repeatsDaily;
  final String payload;
}

/// Stable 31-bit id so the same saved record keeps the same alert.
int reminderNotificationId(String key) {
  final bytes = utf8.encode(key);
  var hash = 0x811c9dc5;
  for (final b in bytes) {
    hash ^= b;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

List<int> normalizeReminderMinutes(Iterable<int> minutes) {
  final unique = <int>{
    for (final minute in minutes)
      if (minute >= 0 && minute < 24 * 60) minute,
  };
  final list = unique.toList()..sort();
  return list;
}

/// Clock times written in [schedule], otherwise words like "morning".
/// Always returns at least one time so turning a reminder on has a start.
List<int> inferReminderMinutes(String schedule) {
  final clocks = _clockTimes(schedule);
  if (clocks.isNotEmpty) return normalizeReminderMinutes(clocks);
  final lower = schedule.toLowerCase();
  final minutes = <int>[];
  if (lower.contains('morning')) minutes.add(8 * 60);
  if (lower.contains('noon') || lower.contains('midday')) minutes.add(12 * 60);
  if (lower.contains('afternoon')) minutes.add(15 * 60);
  if (lower.contains('evening')) minutes.add(20 * 60);
  if (lower.contains('night') || lower.contains('bed')) minutes.add(21 * 60);
  if (minutes.isEmpty) minutes.add(8 * 60);
  return normalizeReminderMinutes(minutes);
}

String formatMinuteOfDay(int minuteOfDay) {
  final bounded = minuteOfDay.clamp(0, (24 * 60) - 1);
  final hour24 = bounded ~/ 60;
  final minute = bounded % 60;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour:${minute.toString().padLeft(2, '0')} $period';
}

String formatAppointmentWhen(DateTime dt) {
  final local = dt.toLocal();
  final period = local.hour >= 12 ? 'PM' : 'AM';
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_weekdays[local.weekday - 1]}, '
      '${_months[local.month - 1]} ${local.day}, ${local.year} · '
      '$hour:$minute $period';
}

/// Parses labels this app writes, including older ones that omit the year.
DateTime? parseAppointmentWhen(String label, {DateTime? yearFrom}) {
  final match = _whenLabel.firstMatch(label.trim());
  if (match == null) return null;
  final month = _months.indexOf(match.group(1)!) + 1;
  final day = int.parse(match.group(2)!);
  final year = match.group(3) != null
      ? int.parse(match.group(3)!)
      : (yearFrom ?? DateTime.now()).year;
  var hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final isPm = match.group(6) == 'PM';
  if (hour < 1 || hour > 12 || minute > 59 || day < 1) return null;
  if (hour == 12) {
    hour = isPm ? 12 : 0;
  } else if (isPm) {
    hour += 12;
  }
  final parsed = DateTime(year, month, day, hour, minute);
  if (parsed.month != month || parsed.day != day) return null;
  return parsed;
}

/// Alerts for medications and appointments already stored in [snapshot].
/// Past one-time visits are skipped. Nothing here uses the network.
List<ReminderRequest> planReminders(
  HealthSnapshot snapshot, {
  required DateTime now,
}) {
  final planned = <ReminderRequest>[];
  for (final med in snapshot.medications) {
    if (!med.remind) continue;
    final minutes = normalizeReminderMinutes(
      med.remindMinutes.isEmpty
          ? inferReminderMinutes(med.schedule)
          : med.remindMinutes,
    );
    for (final minute in minutes) {
      final key = 'med:${med.id}:$minute';
      planned.add(
        ReminderRequest(
          id: reminderNotificationId(key),
          title: medicationReminderTitle,
          body: '${med.name}. ${med.schedule}',
          fireAt: _nextDaily(minute, now),
          repeatsDaily: true,
          payload: '$reminderPayloadPrefix$key',
        ),
      );
    }
  }
  for (final appt in snapshot.appointments) {
    if (!appt.remind) continue;
    final fireAt =
        appt.remindAt ?? appt.when ?? parseAppointmentWhen(appt.whenLabel);
    if (fireAt == null || !fireAt.isAfter(now)) continue;
    final key = 'appt:${appt.id}';
    final parts = <String>[
      appt.provider,
      if (appt.whenLabel.trim().isNotEmpty) appt.whenLabel.trim(),
      if (appt.location.trim().isNotEmpty) appt.location.trim(),
    ];
    planned.add(
      ReminderRequest(
        id: reminderNotificationId(key),
        title: appointmentReminderTitle,
        body: parts.join('. '),
        fireAt: fireAt,
        repeatsDaily: false,
        payload: '$reminderPayloadPrefix$key',
      ),
    );
  }
  return planned;
}

DateTime _nextDaily(int minuteOfDay, DateTime now) {
  final local = now.toLocal();
  final hour = minuteOfDay ~/ 60;
  final minute = minuteOfDay % 60;
  var fire = DateTime(local.year, local.month, local.day, hour, minute);
  if (!fire.isAfter(local)) {
    fire = fire.add(const Duration(days: 1));
  }
  return fire;
}

List<int> _clockTimes(String schedule) {
  final out = <int>[];
  for (final match in _clockTime.allMatches(schedule)) {
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2) ?? '0');
    final isPm = match.group(3)!.toLowerCase() == 'p';
    if (hour < 1 || hour > 12 || minute > 59) continue;
    if (hour == 12) {
      hour = isPm ? 12 : 0;
    } else if (isPm) {
      hour += 12;
    }
    out.add(hour * 60 + minute);
  }
  return out;
}
