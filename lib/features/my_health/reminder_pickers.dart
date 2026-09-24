import 'package:flutter/material.dart';

Future<int?> pickMinuteOfDay(
  BuildContext context, {
  required int initial,
}) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
  );
  if (picked == null) return null;
  return picked.hour * 60 + picked.minute;
}

Future<DateTime?> pickLocalDateTime(
  BuildContext context, {
  required DateTime initial,
}) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 5),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
