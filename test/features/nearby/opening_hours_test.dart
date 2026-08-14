import 'package:flutter_test/flutter_test.dart';
import 'package:cwc_health_app/features/nearby/data/opening_hours.dart';

const nb = 'Mo-Fr 09:00-19:00; Sa 09:00-17:00; Su 10:00-16:00';
const lunch = 'Mo-Fr 08:00-12:00,13:00-17:00';

void main() {
  test('24/7 is always open with seven day lines', () {
    final view = parseOpeningHours('24/7', DateTime.utc(2026, 8, 11, 14, 42));
    expect(view.kind, OpeningHoursKind.openNow);
    expect(view.weekdayLines, [
      'Monday Open 24 hours',
      'Tuesday Open 24 hours',
      'Wednesday Open 24 hours',
      'Thursday Open 24 hours',
      'Friday Open 24 hours',
      'Saturday Open 24 hours',
      'Sunday Open 24 hours',
    ]);
  });

  test('New Brunswick-style string is open Tuesday 10:42 AM ET', () {
    // 10:42 AM EDT = 14:42 UTC
    final view = parseOpeningHours(nb, DateTime.utc(2026, 8, 11, 14, 42));
    expect(view.kind, OpeningHoursKind.openNow);
    expect(view.weekdayLines, [
      'Monday 9:00 AM – 7:00 PM',
      'Tuesday 9:00 AM – 7:00 PM',
      'Wednesday 9:00 AM – 7:00 PM',
      'Thursday 9:00 AM – 7:00 PM',
      'Friday 9:00 AM – 7:00 PM',
      'Saturday 9:00 AM – 5:00 PM',
      'Sunday 10:00 AM – 4:00 PM',
    ]);
  });

  test('same string is closed Sunday 8:00 PM ET', () {
    // Sunday 16 Aug 2026 8:00 PM EDT = 00:00 UTC Monday 17 Aug
    final view = parseOpeningHours(nb, DateTime.utc(2026, 8, 17, 0, 0));
    expect(view.kind, OpeningHoursKind.closed);
  });

  test('same string is closed Tuesday 8:00 PM ET', () {
    // Tuesday 11 Aug 2026 8:00 PM EDT = 00:00 UTC Wednesday 12 Aug
    final view = parseOpeningHours(nb, DateTime.utc(2026, 8, 12, 0, 0));
    expect(view.kind, OpeningHoursKind.closed);
  });

  test('PH off is unknown', () {
    final view = parseOpeningHours('PH off', DateTime.utc(2026, 8, 11, 14, 42));
    expect(view.kind, OpeningHoursKind.unknown);
    expect(view.weekdayLines, isNull);
  });

  test('overnight range is unknown', () {
    final view = parseOpeningHours(
      'Mo-Fr 22:00-02:00',
      DateTime.utc(2026, 8, 11, 14, 42),
    );
    expect(view.kind, OpeningHoursKind.unknown);
  });

  test('null and blank are unknown', () {
    expect(
      parseOpeningHours(null, DateTime.utc(2026, 8, 11)).kind,
      OpeningHoursKind.unknown,
    );
    expect(
      parseOpeningHours('  ', DateTime.utc(2026, 8, 11)).kind,
      OpeningHoursKind.unknown,
    );
  });

  test('lunch gap is closed at 12:30 PM ET and open at 1:30 PM ET', () {
    expect(
      parseOpeningHours(lunch, DateTime.utc(2026, 8, 11, 16, 30)).kind,
      OpeningHoursKind.closed,
    );
    expect(
      parseOpeningHours(lunch, DateTime.utc(2026, 8, 11, 17, 30)).kind,
      OpeningHoursKind.openNow,
    );
  });

  test('wrapping day range is unknown', () {
    expect(
      parseOpeningHours(
        'Fr-Mo 09:00-17:00',
        DateTime.utc(2026, 8, 11, 14, 42),
      ).kind,
      OpeningHoursKind.unknown,
    );
  });
}
