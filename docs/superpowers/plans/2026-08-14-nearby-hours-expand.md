# Nearby Live Hours Expand/Collapse Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On live Nearby cards, show a tappable **Open now** / **Closed** control that expands a Mon–Sun hours list; unparseable OSM tags stay a non-tappable **Hours not listed**.

**Architecture:** A pure Dart subset parser turns OSM `opening_hours` plus a UTC instant into `OpeningHoursView`. The live `_PlaceCard` renders `NearbyHoursControl` from that view. `NearbyResource.status` is renamed to `openingHoursRaw` and is never display copy. Flag-off demo cards are unchanged.

**Tech Stack:** Flutter (`cwc_health_app`), existing `flutter_test`. No new pub dependencies — Eastern Time (DST included) is a local helper in the parser file. No `flutter_map`, no Google billing.

## Global Constraints

- Live Nearby only. Do not add this control to flag-off `DemoResource` cards.
- `LIVE_NEARBY` compile default stays **false**.
- Do not bump feature spec FIND-1.
- Parser subset only: `24/7` and weekday ranges `Mo-Fr 09:00-19:00; Sa …; Su …` with optional comma-separated same-day intervals. Overnight, `PH`, `off`, comments → `unknown`.
- Evaluate “now” in `America/New_York`, not the device zone.
- Display copy ~6th-grade; 12-hour AM/PM (`9:00 AM`, not `09:00 AM`); en-dash `–` in ranges.
- ≥48dp tappable target; hours control body ≥18pt (ACC-1). Do not use scarlet to mean closed.
- TalkBack: `Open now, show hours` / `Closed, show hours`; expanded swaps in `hide hours`.
- Work in a git worktree under `/Users/ks1686/Documents/Worktrees/` (do not dirty the main checkout).
- Preview in Cursor Simple Browser / Glass, not system Chrome. `flutter run -d chrome --dart-define=LIVE_NEARBY=true` is the Flutter device; open the resulting URL in the agent browser.
- Run tests **without** `--dart-define=LIVE_NEARBY=true` unless a step says otherwise.

**Design:** [`docs/superpowers/specs/2026-08-14-nearby-hours-expand-design.md`](../specs/2026-08-14-nearby-hours-expand-design.md)

## File map

| File | Role |
|------|------|
| `lib/features/nearby/data/opening_hours.dart` | Parser + ET helper + `OpeningHoursView` |
| `lib/features/nearby/widgets/nearby_hours_control.dart` | Collapsed/expanded hours control |
| `lib/features/nearby/data/nearby_resource.dart` | Rename `status` → `openingHoursRaw` (`String?`) |
| `lib/features/nearby/data/sources/osm_overpass_source.dart` | Store raw tag or null |
| `lib/features/nearby/data/sources/google_places_source.dart` | `openingHoursRaw: null` |
| `lib/features/nearby/data/nearby_repository.dart` | Copy `openingHoursRaw` in `_stamped` |
| `lib/features/nearby/nearby_screen.dart` | Live card uses control; inject `clock` |
| `test/features/nearby/opening_hours_test.dart` | Parser tables |
| `test/features/nearby/nearby_hours_control_test.dart` | Widget expand/collapse |
| `test/features/nearby/nearby_screen_test.dart` | Live + demo screen wiring |
| Constructors in `nearby_config_test.dart`, `nearby_repository_test.dart` | Field rename |

---

### Task 1: Opening-hours subset parser

**Files:**
- Create: `lib/features/nearby/data/opening_hours.dart`
- Test: `test/features/nearby/opening_hours_test.dart`

**Interfaces:**
- Consumes: nothing from other tasks
- Produces:
  - `enum OpeningHoursKind { openNow, closed, unknown }`
  - `class OpeningHoursView { final OpeningHoursKind kind; final List<String>? weekdayLines; }` — `weekdayLines` is seven Monday–Sunday strings iff `kind != unknown`, else null
  - `OpeningHoursView parseOpeningHours(String? raw, DateTime nowUtc)`
  - `DateTime easternWallClock(DateTime utc)` — UTC instant → DateTime whose y/M/d/H/m are America/New_York wall-clock (DST included)

- [ ] **Step 1: Write the failing parser test**

Create `test/features/nearby/opening_hours_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cwc_health_app/features/nearby/data/opening_hours.dart';

const nb =
    'Mo-Fr 09:00-19:00; Sa 09:00-17:00; Su 10:00-16:00';
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/nearby/opening_hours_test.dart`

Expected: FAIL compiling — `opening_hours.dart` does not exist.

- [ ] **Step 3: Implement the parser**

Create `lib/features/nearby/data/opening_hours.dart`:

```dart
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
  final parts = [
    for (final i in intervals) '${_ampm(i.$1)} – ${_ampm(i.$2)}',
  ];
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
  final start = DateTime.utc(year, 3, _nthWeekday(year, 3, DateTime.sunday, 2), 7);
  final end = DateTime.utc(year, 11, _nthWeekday(year, 11, DateTime.sunday, 1), 6);
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/nearby/opening_hours_test.dart`

Expected: All tests PASS.

If a DST fixture is off by an hour, print `easternWallClock(DateTime.utc(...))` and fix only the helper — do not weaken the table.

- [ ] **Step 5: Format, analyze, commit**

Run:

```bash
dart format lib/features/nearby/data/opening_hours.dart test/features/nearby/opening_hours_test.dart
flutter analyze --fatal-infos lib/features/nearby/data/opening_hours.dart test/features/nearby/opening_hours_test.dart
```

Expected: format rewrites if needed; analyze 0 issues.

```bash
git add lib/features/nearby/data/opening_hours.dart test/features/nearby/opening_hours_test.dart
git commit -m "$(cat <<'EOF'
Add OSM opening_hours subset parser for live Nearby cards.

EOF
)"
```

---

### Task 2: NearbyHoursControl widget

**Files:**
- Create: `lib/features/nearby/widgets/nearby_hours_control.dart`
- Test: `test/features/nearby/nearby_hours_control_test.dart`

**Interfaces:**
- Consumes: `OpeningHoursView`, `OpeningHoursKind` from Task 1
- Produces: `class NearbyHoursControl extends StatefulWidget { const NearbyHoursControl({super.key, required this.view}); final OpeningHoursView view; }`

- [ ] **Step 1: Write the failing widget tests**

Create `test/features/nearby/nearby_hours_control_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwc_health_app/features/nearby/data/opening_hours.dart';
import 'package:cwc_health_app/features/nearby/widgets/nearby_hours_control.dart';
import 'package:cwc_health_app/theme/cwc_theme.dart';

const _week = [
  'Monday 9:00 AM – 7:00 PM',
  'Tuesday 9:00 AM – 7:00 PM',
  'Wednesday 9:00 AM – 7:00 PM',
  'Thursday 9:00 AM – 7:00 PM',
  'Friday 9:00 AM – 7:00 PM',
  'Saturday 9:00 AM – 5:00 PM',
  'Sunday 10:00 AM – 4:00 PM',
];

void main() {
  Future<void> pump(WidgetTester tester, OpeningHoursView view) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCwcTheme(),
        home: Scaffold(body: NearbyHoursControl(view: view)),
      ),
    );
  }

  testWidgets('unknown is plain Hours not listed, not a button', (tester) async {
    await pump(
      tester,
      const OpeningHoursView(kind: OpeningHoursKind.unknown),
    );

    expect(find.text('Hours not listed'), findsOneWidget);
    expect(find.text('Open now'), findsNothing);
    expect(find.text('Closed'), findsNothing);
    expect(find.byTooltip('Open now, show hours'), findsNothing);
    expect(
      tester.getSize(find.text('Hours not listed')).height,
      greaterThanOrEqualTo(18),
    );
  });

  testWidgets('open now starts collapsed and expands then collapses', (
    tester,
  ) async {
    await pump(
      tester,
      const OpeningHoursView(
        kind: OpeningHoursKind.openNow,
        weekdayLines: _week,
      ),
    );

    expect(find.text('Open now'), findsOneWidget);
    expect(find.text('Monday 9:00 AM – 7:00 PM'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Open now, show hours'));
    await tester.pumpAndSettle();

    expect(find.text('Monday 9:00 AM – 7:00 PM'), findsOneWidget);
    expect(find.text('Sunday 10:00 AM – 4:00 PM'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Open now, hide hours'));
    await tester.pumpAndSettle();

    expect(find.text('Monday 9:00 AM – 7:00 PM'), findsNothing);
  });

  testWidgets('closed expands the same week list', (tester) async {
    await pump(
      tester,
      const OpeningHoursView(
        kind: OpeningHoursKind.closed,
        weekdayLines: _week,
      ),
    );

    expect(find.text('Closed'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Closed, show hours'));
    await tester.pumpAndSettle();
    expect(find.text('Monday 9:00 AM – 7:00 PM'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests — expect FAIL**

Run: `flutter test test/features/nearby/nearby_hours_control_test.dart`

Expected: FAIL compiling — widget file missing.

- [ ] **Step 3: Implement the widget**

Create `lib/features/nearby/widgets/nearby_hours_control.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../theme/cwc_theme.dart';
import '../data/opening_hours.dart';

class NearbyHoursControl extends StatefulWidget {
  const NearbyHoursControl({super.key, required this.view});

  final OpeningHoursView view;

  @override
  State<NearbyHoursControl> createState() => _NearbyHoursControlState();
}

class _NearbyHoursControlState extends State<NearbyHoursControl> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    if (view.kind == OpeningHoursKind.unknown) {
      return const Text(
        'Hours not listed',
        style: TextStyle(color: CwcColors.sub, fontSize: 18, height: 1.3),
      );
    }

    final summary = view.kind == OpeningHoursKind.openNow
        ? 'Open now'
        : 'Closed';
    final action = _expanded ? 'hide hours' : 'show hours';
    final lines = view.weekdayLines!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: '$summary, $action',
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Row(
                children: [
                  Text(
                    summary,
                    style: const TextStyle(
                      color: CwcColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: CwcColors.sub,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: const TextStyle(
                  color: CwcColors.sub,
                  fontSize: 18,
                  height: 1.3,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
```

If `bySemanticsLabel` cannot find the control (InkWell vs Semantics merging), wrap `InkWell` with `Semantics(container: true, …)` or set `excludeSemantics: true` on the inner `Text` so the button label wins. Do not drop the TalkBack strings.

- [ ] **Step 4: Run tests — expect PASS**

Run: `flutter test test/features/nearby/nearby_hours_control_test.dart test/features/nearby/opening_hours_test.dart`

Expected: All PASS.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/features/nearby/widgets/nearby_hours_control.dart test/features/nearby/nearby_hours_control_test.dart
flutter analyze --fatal-infos lib/features/nearby/widgets/nearby_hours_control.dart test/features/nearby/nearby_hours_control_test.dart
git add lib/features/nearby/widgets/nearby_hours_control.dart test/features/nearby/nearby_hours_control_test.dart
git commit -m "$(cat <<'EOF'
Add expandable Open now / Closed hours control.

EOF
)"
```

---

### Task 3: Rename `status` and wire the live card

**Files:**
- Modify: `lib/features/nearby/data/nearby_resource.dart`
- Modify: `lib/features/nearby/data/sources/osm_overpass_source.dart` (`_mapElement`, ~204–217)
- Modify: `lib/features/nearby/data/sources/google_places_source.dart` (~184)
- Modify: `lib/features/nearby/data/nearby_repository.dart` (`_stamped`, ~159–171)
- Modify: `lib/features/nearby/nearby_screen.dart` (`NearbyScreen` + live `_PlaceCard` usage ~303–310; keep demo `_PlaceCard` `status:` as `DemoResource.status`)
- Modify: `test/features/nearby/nearby_screen_test.dart`
- Modify: `test/features/nearby/nearby_config_test.dart` (~51)
- Modify: `test/features/nearby/nearby_repository_test.dart` (~109)

**Interfaces:**
- Consumes: `parseOpeningHours`, `NearbyHoursControl` from Tasks 1–2
- Produces: `NearbyResource.openingHoursRaw` (`String?`); `NearbyScreen({DateTime Function()? clock})` used only in live mode, default `DateTime.now`

- [ ] **Step 1: Write failing screen tests for hours**

In `test/features/nearby/nearby_screen_test.dart`:

1. Change `_resource` to take `String? openingHoursRaw` (default `null`) instead of `status: 'Hours not listed'`.
2. Add a frozen clock: `DateTime.utc(2026, 8, 11, 14, 42)` (Tue 10:42 AM ET).
3. Add these tests inside `group('live mode')` and one assertion in `group('demo mode')`:

```dart
    testWidgets('demo cards keep Open until 7pm and have no Open now', (
      tester,
    ) async {
      await pumpScreen(tester, const NearbyScreen(config: _demoConfig));

      expect(find.text('Open until 7pm'), findsOneWidget);
      expect(find.text('Open now'), findsNothing);
      expect(find.text('Hours not listed'), findsNothing);
    });

    testWidgets('live card with OSM hours shows Open now and expands', (
      tester,
    ) async {
      final repository = _StubRepository(
        _result(
          resources: [
            _resource(
              name: 'University Pharmacy',
              openingHoursRaw:
                  'Mo-Fr 09:00-19:00; Sa 09:00-17:00; Su 10:00-16:00',
            ),
          ],
        ),
      );

      await pumpScreen(
        tester,
        NearbyScreen(
          config: _liveConfig,
          repository: repository,
          clock: () => DateTime.utc(2026, 8, 11, 14, 42),
        ),
      );

      expect(find.text('Hours not listed'), findsNothing);
      expect(find.text('Open now'), findsOneWidget);
      expect(find.text('Monday 9:00 AM – 7:00 PM'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Open now, show hours'));
      await tester.pumpAndSettle();
      expect(find.text('Monday 9:00 AM – 7:00 PM'), findsOneWidget);
    });

    testWidgets('live card without hours stays Hours not listed', (tester) async {
      final repository = _StubRepository(
        _result(resources: [_resource(name: 'Highland Pharmacy')]),
      );

      await pumpScreen(
        tester,
        NearbyScreen(
          config: _liveConfig,
          repository: repository,
          clock: () => DateTime.utc(2026, 8, 11, 14, 42),
        ),
      );

      expect(find.text('Hours not listed'), findsOneWidget);
      expect(find.text('Open now'), findsNothing);
    });
```

Pass `clock:` through on **every** existing live `NearbyScreen(...)` in this file so tests stay deterministic (use the same UTC instant). Demo tests omit `clock`.

- [ ] **Step 2: Run screen tests — expect FAIL**

Run: `flutter test test/features/nearby/nearby_screen_test.dart`

Expected: FAIL — `openingHoursRaw` / `clock` not on the types yet.

- [ ] **Step 3: Implement rename + wiring**

`NearbyResource` — replace `status` with:

```dart
  const NearbyResource({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.lat,
    required this.lng,
    required this.source,
    required this.fetchedAt,
    this.phone,
    this.openingHoursRaw,
  });

  final String? openingHoursRaw;
```

`osm_overpass_source.dart` `_mapElement` — stop inventing `'Hours not listed'`:

```dart
    final hours = tagMap['opening_hours']?.trim();
    return NearbyResource(
      id: id,
      name: name,
      category: category.label,
      address: _addressFrom(tagMap),
      phone: phone,
      lat: coords.$1,
      lng: coords.$2,
      openingHoursRaw: (hours == null || hours.isEmpty) ? null : hours,
      source: 'osm',
      fetchedAt: when,
    );
```

`google_places_source.dart` mapped place: `openingHoursRaw: null` (delete `status: 'Hours not listed'`).

`nearby_repository.dart` `_stamped`: `openingHoursRaw: row.openingHoursRaw`.

`NearbyScreen` — add optional clock and pass hours into the live card only:

```dart
class NearbyScreen extends StatelessWidget {
  const NearbyScreen({
    super.key,
    this.config,
    this.repository,
    this.launcher,
    this.clock,
  });

  final NearbyConfig? config;
  final NearbyRepository? repository;
  final NearbyLinkLauncher? launcher;
  final DateTime Function()? clock;
```

Thread `clock` into `_NearbyLiveView`. Demo `_PlaceCard` still uses `status: resource.status` (`DemoResource`). Live loop:

```dart
          _PlaceCard(
            name: resource.name,
            hours: NearbyHoursControl(
              view: parseOpeningHours(
                resource.openingHoursRaw,
                (widget.clock ?? DateTime.now)(),
              ),
            ),
            badges: [resource.category],
            address: resource.address,
            actions: _actionsFor(resource),
          ),
```

Change `_PlaceCard` so demo and live do not share a `String status`:

- Add `required Widget hours`
- Remove `String status`
- In `build`, replace the status `Text` with `hours`
- Demo call site: `hours: Text(resource.status, style: const TextStyle(color: CwcColors.sub, fontSize: 13))` — keep 13pt on demo; do not “fix” demo type in this task

Import `opening_hours.dart` and `nearby_hours_control.dart` at the top of `nearby_screen.dart` (no inline imports).

Update the three test helpers that still pass `status:` on `NearbyResource`.

- [ ] **Step 4: Run the Nearby suite — expect PASS**

Run:

```bash
flutter test test/features/nearby/
flutter test
```

Expected: All PASS. Demo test still finds `Open until 7pm`. Live OSM-hours test finds `Open now`. Config test still asserts `liveNearby == false`.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/features/nearby test/features/nearby
flutter analyze --fatal-infos
git add lib/features/nearby test/features/nearby
git commit -m "$(cat <<'EOF'
Wire expandable hours onto live Nearby cards.

EOF
)"
```

---

### Task 4: Docs + local live smoke

**Files:**
- Modify: `docs/engineering/nearby-live-data.md` (as-built hours row + next-engineering item 1)
- Modify: `docs/superpowers/specs/2026-08-14-nearby-hours-expand-design.md` (status line → implemented when this task’s tests are green)
- Modify: `AGENTS.md` engineering “as-built gaps” hours bullet
- Modify: `README.md` Nearby row (hours no longer dump raw OSM)

**Interfaces:**
- Consumes: behavior from Tasks 1–3
- Produces: docs that match the app; FIND-1 still not rewritten

- [ ] **Step 1: Update as-built docs**

In `docs/engineering/nearby-live-data.md` as-built table, replace the Hours row with:

| Hours | Live cards: **Open now** / **Closed** (tap to expand Mon–Sun). Unparseable or missing OSM tags: **Hours not listed**. |

In **Next engineering**, mark item 1 done or remove it; keep FIND-4 map as next.

In `AGENTS.md` §11, drop “raw OSM hours on cards” from as-built gaps.

In `README.md` Nearby table cell, replace “hours currently dump raw OSM `opening_hours`” with “Open now / Closed expands weekday hours when OSM tags parse”.

Set the hours design spec status to: `Implemented on the hours-expand branch (flag default still off).`

Do not bump `01_CWC_Health_App_Feature_Specification_v0.4.md`.

- [ ] **Step 2: Full suite without LIVE_NEARBY**

Run:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

Expected: 0 analyze issues; all tests PASS. Do **not** run with `--dart-define=LIVE_NEARBY=true`.

- [ ] **Step 3: Manual live smoke in Cursor Glass / Simple Browser**

```bash
flutter run -d chrome --dart-define=LIVE_NEARBY=true
```

Open the printed localhost URL with Cursor `open_resource` (Glass), not system Chrome. On a card with parseable hours: collapsed Open now or Closed; tap shows seven day lines; tap again hides them. On a card with no hours: Hours not listed, not tappable. Demo path is not this run.

- [ ] **Step 4: Commit docs**

```bash
git add docs/engineering/nearby-live-data.md docs/superpowers/specs/2026-08-14-nearby-hours-expand-design.md AGENTS.md README.md
git commit -m "$(cat <<'EOF'
Document live Nearby expandable hours as as-built.

EOF
)"
```

---

## Spec coverage

| Spec section | Task |
|--------------|------|
| Parser subset + ET clock + 12-hour copy | 1 |
| `OpeningHoursView` kinds | 1 |
| `NearbyHoursControl` collapsed/expanded, 48dp, 18pt, TalkBack | 2 |
| Unknown = Hours not listed, not a button | 2, 3 |
| Rename `status` → `openingHoursRaw` | 3 |
| Live card wiring + injectable clock | 3 |
| Demo cards unchanged | 3 |
| Google rows stay unknown | 3 (`openingHoursRaw: null`) |
| FIND-1 not bumped | 4 |
| Preview in agent browser | 4 |

## Placeholder scan

None. Parser rejects overnight/`PH`/`off` in Task 1 tests. Semantics fallback is only if the first TalkBack finder fails, still using the same strings.

## Type consistency

- `parseOpeningHours(String? raw, DateTime nowUtc) → OpeningHoursView` (Tasks 1, 3)
- `NearbyHoursControl({required OpeningHoursView view})` (Tasks 2, 3)
- `NearbyResource.openingHoursRaw` (`String?`) (Task 3)
- `NearbyScreen.clock` (`DateTime Function()?`) (Task 3)
