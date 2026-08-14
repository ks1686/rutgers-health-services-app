enum OpeningHoursKind { openNow, closed, unknown }

class OpeningHoursView {
  const OpeningHoursView({required this.kind, this.weekdayLines});

  final OpeningHoursKind kind;
  final List<String>? weekdayLines;
}

const _dayToken = {
  'Mo': DateTime.monday,
  'Tu': DateTime.tuesday,
  'We': DateTime.wednesday,
  'Th': DateTime.thursday,
  'Fr': DateTime.friday,
  'Sa': DateTime.saturday,
  'Su': DateTime.sunday,
};

const _dayName = {
  DateTime.monday: 'Monday',
  DateTime.tuesday: 'Tuesday',
  DateTime.wednesday: 'Wednesday',
  DateTime.thursday: 'Thursday',
  DateTime.friday: 'Friday',
  DateTime.saturday: 'Saturday',
  DateTime.sunday: 'Sunday',
};

final _rulePattern = RegExp(
  r'^(Mo|Tu|We|Th|Fr|Sa|Su)(?:-(Mo|Tu|We|Th|Fr|Sa|Su))? '
  r'(\d{2}:\d{2}-\d{2}:\d{2}(?:,\d{2}:\d{2}-\d{2}:\d{2})*)$',
);

OpeningHoursView parseOpeningHours(String? raw, DateTime nowUtc) {
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return const OpeningHoursView(kind: OpeningHoursKind.unknown);
  }
  if (trimmed == '24/7') {
    return OpeningHoursView(
      kind: OpeningHoursKind.openNow,
      weekdayLines: [
        for (var d = DateTime.monday; d <= DateTime.sunday; d++)
          '${_dayName[d]} Open 24 hours',
      ],
    );
  }

  final byDay = <int, List<(int start, int end)>>{
    for (var d = DateTime.monday; d <= DateTime.sunday; d++) d: [],
  };

  for (final chunk in trimmed.split(';')) {
    final rule = chunk.trim();
    if (rule.isEmpty) continue;
    final match = _rulePattern.firstMatch(rule);
    if (match == null) {
      return const OpeningHoursView(kind: OpeningHoursKind.unknown);
    }
    final startDay = _dayToken[match.group(1)!]!;
    final endDay = match.group(2) == null
        ? startDay
        : _dayToken[match.group(2)!]!;
    if (endDay < startDay) {
      return const OpeningHoursView(kind: OpeningHoursKind.unknown);
    }
    final intervals = <(int, int)>[];
    for (final part in match.group(3)!.split(',')) {
      final times = part.split('-');
      final start = _hhmm(times[0]);
      final end = _hhmm(times[1]);
      if (start == null || end == null || end <= start) {
        return const OpeningHoursView(kind: OpeningHoursKind.unknown);
      }
      intervals.add((start, end));
    }
    for (var d = startDay; d <= endDay; d++) {
      byDay[d]!.addAll(intervals);
    }
  }

  final et = easternWallClock(nowUtc);
  final minutes = et.hour * 60 + et.minute;
  final today = byDay[et.weekday]!;
  final isOpen = today.any((i) => minutes >= i.$1 && minutes < i.$2);

  return OpeningHoursView(
    kind: isOpen ? OpeningHoursKind.openNow : OpeningHoursKind.closed,
    weekdayLines: [
      for (var d = DateTime.monday; d <= DateTime.sunday; d++)
        _lineFor(_dayName[d]!, byDay[d]!),
    ],
  );
}

String _lineFor(String name, List<(int start, int end)> intervals) {
  if (intervals.isEmpty) return '$name Closed';
  final parts = [for (final i in intervals) '${_ampm(i.$1)} – ${_ampm(i.$2)}'];
  return '$name ${parts.join(', ')}';
}

int? _hhmm(String raw) {
  final bits = raw.split(':');
  if (bits.length != 2) return null;
  final h = int.tryParse(bits[0]);
  final m = int.tryParse(bits[1]);
  if (h == null || m == null || h > 23 || m > 59) return null;
  return h * 60 + m;
}

String _ampm(int minutes) {
  final h24 = minutes ~/ 60;
  final m = minutes % 60;
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  final meridiem = h24 < 12 ? 'AM' : 'PM';
  final mm = m.toString().padLeft(2, '0');
  return '$h12:$mm $meridiem';
}

/// UTC instant → DateTime whose calendar fields are America/New_York wall-clock.
DateTime easternWallClock(DateTime utc) {
  final instant = utc.toUtc();
  final offset = _isEasternDaylight(instant) ? -4 : -5;
  return instant.add(Duration(hours: offset));
}

bool _isEasternDaylight(DateTime utc) {
  final year = utc.year;
  final start = DateTime.utc(
    year,
    3,
    _nthWeekday(year, 3, DateTime.sunday, 2),
    7,
  );
  final end = DateTime.utc(
    year,
    11,
    _nthWeekday(year, 11, DateTime.sunday, 1),
    6,
  );
  return !utc.isBefore(start) && utc.isBefore(end);
}

int _nthWeekday(int year, int month, int weekday, int n) {
  var count = 0;
  for (var day = 1; day <= 31; day++) {
    final candidate = DateTime.utc(year, month, day);
    if (candidate.month != month) break;
    if (candidate.weekday == weekday) {
      count++;
      if (count == n) return day;
    }
  }
  throw StateError('no nth weekday');
}
