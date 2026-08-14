# Nearby live hours — expand/collapse design (2026-08-14)

**Status:** Implemented on the hours-expand branch (flag default still off). Implementation plan: [`../plans/2026-08-14-nearby-hours-expand.md`](../plans/2026-08-14-nearby-hours-expand.md).  
**Parent:** [`2026-08-11-nearby-live-data-design.md`](2026-08-11-nearby-live-data-design.md) (live Nearby spike, implemented).  
**Handoff:** [`docs/engineering/nearby-live-data.md`](../../engineering/nearby-live-data.md).  
**Evidence:** [TEAM 2026-08-14] — live OSM `opening_hours` dumped into the card is hard to read.

## Problem

Live Nearby cards put the raw OSM `opening_hours` tag in `NearbyResource.status` (e.g. `Mo-Fr 09:00-19:00; Sa 09:00-17:00; Su 10:00-16:00`). That is not ~6th-grade copy and is hard to scan. Spec FIND-1 wants plain-language hours. Missing tags already show `Hours not listed`.

## Goal

On **live** Nearby cards only: show **Open now** or **Closed** as a tappable control. Tap expands a Mon–Sun list in plain language. Tap again collapses. If we cannot tell open vs closed, show a non-tappable **Hours not listed**.

## Non-goals

- FIND-4 map tiles (separate plan).
- GPS / town picker.
- Changing the `LIVE_NEARBY` compile-time default.
- Rewriting FIND-1 (curated directory remains the funded MVP narrative).
- Google Places hours (those rows stay `Hours not listed` until a later source change).
- Pretty-printing raw OSM text we did not parse.
- Flag-off demo cards (`Open until 7pm` etc. stay as they are).
- Persistent cache.

## Locked UI (approach A)

- Live `_PlaceCard` only.
- Starts **collapsed**.
- `openNow` / `closed` → one ≥48dp control under the place name. Label is **Open now** or **Closed** plus a chevron. Not color-only: the words carry the meaning; scarlet is not used to mean closed.
- Tap expands Mon–Sun lines, 12-hour AM/PM, e.g. `Monday 9:00 AM – 7:00 PM`. Closed days: `Sunday Closed`.
- `unknown` → static text **Hours not listed**. Not a button. No chevron.
- TalkBack: collapsed control name is `Open now, show hours` or `Closed, show hours`. Expanded: `Open now, hide hours` / `Closed, hide hours`.
- Base type follows ACC-1 (18pt+ / OS scaling). Do not keep the current 13pt status line for this control.

## Architecture

Three units. Live path only.

```text
OsmOverpassSource          keeps raw opening_hours on NearbyResource
        │
        ▼
parseOpeningHours(raw, nowEt)   pure Dart, no Flutter, no HTTP
        │
        ▼
NearbyHoursControl              live _PlaceCard only
```

### 1. Parser (`lib/features/nearby/data/opening_hours.dart`)

**Input:** OSM `opening_hours` string (nullable/blank allowed) + an evaluation instant in `America/New_York`.

**Output:** `OpeningHoursView`

```dart
enum OpeningHoursKind { openNow, closed, unknown }

class OpeningHoursView {
  const OpeningHoursView({required this.kind, this.weekdayLines});

  final OpeningHoursKind kind;

  /// Seven Monday–Sunday lines for the expand panel.
  /// Null iff kind == unknown.
  final List<String>? weekdayLines;
}
```

`unknown` when the tag is missing, empty, or outside the subset below. No weekday lines, no button.

**Subset grammar (accept):**

- `24/7` → always `openNow`; every day line is `Open 24 hours`.
- Semicolon-separated rules.
- Day tokens: `Mo` `Tu` `We` `Th` `Fr` `Sa` `Su`.
- Day ranges: `Mo-Fr`, `Sa-Su`, inclusive, wrapping not allowed (`Fr-Mo` → unknown).
- Times: `HH:MM-HH:MM` in 24-hour OSM form, same calendar day, `end` > `start`.
- Several intervals on one rule, comma-separated: `Mo-Fr 08:00-12:00,13:00-17:00`.

**Reject → unknown (not a button):** overnight (`22:00-02:00`), `off`, `PH`, quoted comments, month/year selectors, `open`, `closed` as OSM keywords, wrapping day ranges, any leftover characters after parse.

**Clock:** evaluate “now” in `America/New_York` (DST included), **not** the device zone. A laptop in Mountain Time must still classify New Brunswick hours in Eastern Time. Inject a `DateTime nowUtc` (or a `Clock`) in tests.

**Display times:** convert accepted 24-hour ranges to 12-hour AM/PM with no leading zero on the hour (`9:00 AM`, not `09:00 AM`).

### 2. Model

Rename `NearbyResource.status` to `openingHoursRaw` (nullable `String?`). That field is the OSM tag or null — never display copy. Do not precompute Open/Closed in the repository: “now” changes while the list is on screen, and tests need a frozen clock.

Google Places rows: `openingHoursRaw` empty → `unknown`.

Flag-off demo resources are `DemoResource`, not `NearbyResource`. Do not add this control there.

### 3. Widget (`lib/features/nearby/widgets/nearby_hours_control.dart`)

`NearbyHoursControl` takes `OpeningHoursView`. Live `_PlaceCard` calls the parser with the resource’s raw tag and the current Eastern instant, then passes the view in.

State: expanded/collapsed is per card, local `StatefulWidget`. Collapsing one card does not collapse others.

Minimum target 48×48 dp on the tappable row.

## Data flow

1. Overpass maps `opening_hours` onto the resource (already does this into `status`).
2. Live card build: `parseOpeningHours(resource.openingHoursRaw, nowEt)`.
3. Widget renders unknown vs control.
4. No network on expand. No cache of open/closed.

## Tests

Parser (table-driven):

| Input | Now (ET) | Kind |
|-------|----------|------|
| `24/7` | any | `openNow` |
| `Mo-Fr 09:00-19:00; Sa 09:00-17:00; Su 10:00-16:00` | Tue 10:42 AM | `openNow` |
| same | Sun 8:00 PM | `closed` |
| same | Tue 8:00 PM | `closed` |
| `PH off` | any | `unknown` |
| `Mo-Fr 22:00-02:00` | any | `unknown` |
| `''` / null | any | `unknown` |
| `Mo-Fr 08:00-12:00,13:00-17:00` | Tue 12:30 PM | `closed` (lunch gap) |
| `Mo-Fr 08:00-12:00,13:00-17:00` | Tue 1:30 PM | `openNow` |

Also assert weekday line copy for the New Brunswick–style string (Monday–Friday 9:00 AM – 7:00 PM, Saturday 9:00 AM – 5:00 PM, Sunday 10:00 AM – 4:00 PM).

Widget:

- `unknown` → text `Hours not listed`; no button / no `show hours` semantics.
- `openNow` starts collapsed; tap reveals seven day lines; tap again hides them.
- `closed` same expand/collapse.
- Flag-off `NearbyScreen` still shows `Open until 7pm` / `Main Street Pharmacy`; no `Open now` control.

Existing live Nearby widget tests keep passing (disclaimer, chips, empty/error). Three tests that assert `LIVE_NEARBY` default off stay flag-off.

## Files (implementation)

- Create: `lib/features/nearby/data/opening_hours.dart`
- Create: `lib/features/nearby/widgets/nearby_hours_control.dart`
- Create: `test/features/nearby/opening_hours_test.dart`
- Modify: `lib/features/nearby/data/nearby_resource.dart` (raw hours field)
- Modify: `lib/features/nearby/data/sources/osm_overpass_source.dart` (and Google source if the field name changes)
- Modify: `lib/features/nearby/nearby_screen.dart` (live `_PlaceCard` only; split widget out so this file does not keep growing)
- Modify: `test/features/nearby/nearby_screen_test.dart` and repository tests that construct `NearbyResource`

## Spec tension

FIND-1 still describes a curated directory with human hours. This work makes the **live spike** readable; it does not claim OSM hours are vetted. Do not bump the feature spec in this change.

## Preview

Local engineering demo remains `LIVE_NEARBY=true`. Open it in Cursor’s Simple Browser / agent browser (`http://127.0.0.1:8081/` when a live web build is served), not system Chrome or Safari. Flutter debug `web-server` still does not boot in Safari.
