# Study-Build Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden the CWC study build so live Nearby fails honestly, demo chrome does not overclaim, Help Now / type meet ACC targets, and CI/DX catch the next release-only miss — without rewriting FIND-1 or shipping unverified crisis numbers.

**Architecture:** Keep the existing Nearby repository/cache/sources stack. Add member-safe error copy, timeouts, a persistent last-success cache behind the existing `NearbyCache` interface, and launcher helpers. Theme and header Help Now become the a11y source of truth. Help Now dialers stay behind a new compile flag (`HELP_NOW_LIVE`, default off) using only nationally known numbers. Demo Learn / Help Now / My Health move behind thin bundled-JSON catalogs so hosted JSON has a seam. CI adds an unsigned release APK.

**Tech Stack:** Flutter (`cwc_health_app`), existing `http` + `url_launcher` + `flutter_test`. One new runtime dependency: `shared_preferences` (persistent Nearby cache only). No Places SDK, no map tiles, no analytics, no GPS.

## Global Constraints

- `LIVE_NEARBY` compile default stays **false**. Run the suite **without** `--dart-define=LIVE_NEARBY=true` unless a step says otherwise.
- Do **not** bump or silently rewrite spec FIND-1. Live OSM remains a gated spike.
- Do **not** add `flutter_map`, Google billing, GPS, Inter font, analytics, or My Health persistence / PIN.
- Do **not** invent or ship a real NJ peer warmline or CWC number. Those stay sample + demo snackbar.
- Member-facing copy ~6th-grade. Never interpolate raw exceptions, HTTP bodies, or mirror URLs into the UI.
- GPS stays off. Directions must not require a billed Places key. Do not pass `GOOGLE_PLACES_API_KEY` in any web `--dart-define` example without a leak warning.
- Work in a git worktree under `/Users/ks1686/Documents/Worktrees/rutgers-health-services-app/study-build-hardening` on branch `oz/implement/study-build-hardening`. Do not dirty the main checkout.
- Preview: `flutter run -d chrome --dart-define=LIVE_NEARBY=true`. Not Safari.
- Children never push / `gh pr create`. Review-before-push still required later.

**Sources:** review 2026-08-15; `docs/engineering/nearby-live-data.md`; `AGENTS.md` ACC-1/2, NOW-*, PRIV-*, FIND-1.

## File map

- `lib/features/nearby/data/nearby_errors.dart` — member-safe lookup/load strings
- `lib/features/nearby/data/nearby_launchers.dart` — `tel` / `sms` / directions URIs
- `lib/features/nearby/data/nearby_cache.dart` — keep interface; add JSON helpers if needed
- `lib/features/nearby/data/prefs_nearby_cache.dart` — `shared_preferences` last-success + last GeoPoint
- `lib/features/nearby/data/nearby_resource.dart` — `toJson` / `fromJson`
- `lib/features/nearby/data/nearby_fetch_result.dart` — `toJson` / `fromJson`
- `lib/features/nearby/data/sources/nominatim_geocode.dart` — timeout, one 429 retry, reachable UA
- `lib/features/nearby/data/sources/google_places_source.dart` — request timeout
- `lib/features/nearby/data/sources/geo_point.dart` — `toJson` / `fromJson`
- `lib/features/nearby/data/nearby_repository.dart` — sanitize messages; cached-geocode fallback
- `lib/features/nearby/data/opening_hours.dart` — weekday `off`; `24:00` as end-of-day
- `lib/features/nearby/nearby_screen.dart` — empty vs unavailable; coalesce reload; hide live map; phone line; launchers
- `lib/widgets/help_now_button.dart` — ≥48dp
- `lib/theme/cwc_theme.dart` — 18pt body
- `lib/features/learn/learn_screen.dart` — large-text single column
- `lib/features/help_now/help_now_screen.dart` + `lib/data/demo_help_now.dart` — honesty + optional live 988/911/poison
- `lib/features/my_health/my_health_screen.dart` — honest PIN banner
- `lib/features/more/more_screen.dart` — honest Erase copy
- `assets/content/*.json` + thin catalog loaders — Learn / Help Now / My Health / demo Nearby
- `.github/workflows/flutter-ci.yml` — unsigned `flutter build apk --release`
- `.gitignore`, `pubspec.yaml`, Android/iOS labels, `Info.plist` queries, README / engineering docs

## Workstreams

- **WS1 Nearby reliability** — serial. Tasks 1–5. Owns `lib/features/nearby/**`.
- **WS2 Honest demo + Help Now flag** — parallel-safe with WS1. Tasks 6. Owns Help Now / My Health / More copy (not Nearby files).
- **WS3 CI / DX / hygiene** — parallel-safe with WS1/WS2. Task 9 (CI + gitignore + labels can start immediately; README Nearby paragraphs wait until WS1).
- **WS4 Accessibility** — serial after WS1 (edits `nearby_screen.dart` type sizes). Task 7.
- **WS5 Bundled JSON catalogs** — serial after WS2 (Help Now model must exist). Task 8.
- **WS6 Close-out tests/docs** — serial last. Task 10.

---

### Task 1: Member-safe Nearby errors and empty-vs-unavailable UI

**Files:**
- Create: `lib/features/nearby/data/nearby_errors.dart`
- Modify: `lib/features/nearby/data/nearby_repository.dart` (`fetch` catch paths)
- Modify: `lib/features/nearby/nearby_screen.dart` (`build` / `_buildProblem`)
- Test: `test/features/nearby/nearby_repository_test.dart`
- Test: `test/features/nearby/nearby_screen_test.dart`

**Interfaces:**
- Consumes: existing `NearbyFetchResult`, `NearbySourceStatus`
- Produces:
  - `const kNearbyMemberLookupFailed = 'We could not look up that town right now.';`
  - `const kNearbyMemberLoadFailed = 'We could not load places right now.';`
  - Empty successful OSM keeps repository message `No pharmacies or clinics found near ${query.town}.` and status `osm`
  - `_buildProblem(message, {required bool suggestConnection})` — connection sentence only when `suggestConnection`

- [ ] **Step 1: Write the failing tests**

Add to `nearby_repository_test.dart`:

```dart
test('geocode failure uses the member-safe lookup sentence', () async {
  final repo = build(
    geocode: _FakeGeocode(error: Exception('HTTP 502: <html>overpass')),
    google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
    overpass: _FakeOverpass(result: const []),
  );

  final result = await repo.fetch(query);

  expect(result.status, NearbySourceStatus.unavailable);
  expect(result.message, kNearbyMemberLookupFailed);
  expect(result.message, isNot(contains('HTTP')));
  expect(result.message, isNot(contains('html')));
});

test('overpass failure uses the member-safe load sentence', () async {
  final repo = build(
    geocode: _FakeGeocode(result: area),
    google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
    overpass: _FakeOverpass(error: Exception('All 3 Overpass endpoints failed')),
  );

  final result = await repo.fetch(query);

  expect(result.status, NearbySourceStatus.unavailable);
  expect(result.message, kNearbyMemberLoadFailed);
  expect(result.message, isNot(contains('Overpass')));
});
```

Add to `nearby_screen_test.dart` live group:

```dart
testWidgets('empty OSM does not blame the connection', (tester) async {
  final repository = _StubRepository(
    _result(
      resources: const [],
      status: NearbySourceStatus.osm,
      message: 'No pharmacies or clinics found near New Brunswick.',
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

  expect(
    find.text('No pharmacies or clinics found near New Brunswick.'),
    findsOneWidget,
  );
  expect(find.text('Check your connection, then try again.'), findsNothing);
  expect(find.text('Try again'), findsOneWidget);
});

testWidgets('unavailable still asks to check the connection', (tester) async {
  final repository = _StubRepository(
    _result(
      resources: const [],
      status: NearbySourceStatus.unavailable,
      message: kNearbyMemberLoadFailed,
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

  expect(find.text(kNearbyMemberLoadFailed), findsOneWidget);
  expect(find.text('Check your connection, then try again.'), findsOneWidget);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/nearby/nearby_repository_test.dart test/features/nearby/nearby_screen_test.dart`

Expected: FAIL — interpolated `$e` still in repository messages; empty OSM still shows the connection sentence.

- [ ] **Step 3: Implement**

`nearby_errors.dart`:

```dart
const kNearbyMemberLookupFailed =
    'We could not look up that town right now.';
const kNearbyMemberLoadFailed = 'We could not load places right now.';
```

Repository catch paths call `_cachedOr(query, kNearbyMemberLookupFailed)` / `_cachedOr(query, kNearbyMemberLoadFailed)`. Keep debug `assert`/`debugPrint` of the real `$e` if useful; never put `$e` in `message`.

Screen:

```dart
if (result == null) {
  return _buildProblem(
    kNearbyMemberLoadFailed,
    suggestConnection: true,
  );
}
if (result.resources.isEmpty) {
  return _buildProblem(
    result.message ?? kNearbyMemberLoadFailed,
    suggestConnection: result.status == NearbySourceStatus.unavailable,
  );
}
```

- [ ] **Step 4: Re-run tests**

Run: `flutter test test/features/nearby/nearby_repository_test.dart test/features/nearby/nearby_screen_test.dart`

Expected: PASS. Existing “never falls back to demo rows” still finds `Try again`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/nearby/data/nearby_errors.dart \
  lib/features/nearby/data/nearby_repository.dart \
  lib/features/nearby/nearby_screen.dart \
  test/features/nearby/nearby_repository_test.dart \
  test/features/nearby/nearby_screen_test.dart
git commit -m "fix(nearby): sanitize errors and split empty from unavailable"
```

---

### Task 2: Timeouts, Nominatim retry, reload coalesce

**Files:**
- Modify: `lib/features/nearby/data/sources/nominatim_geocode.dart`
- Modify: `lib/features/nearby/data/sources/google_places_source.dart`
- Modify: `lib/features/nearby/nearby_screen.dart` (`_reload`)
- Test: `test/features/nearby/nominatim_geocode_test.dart`
- Test: `test/features/nearby/nearby_screen_test.dart`

**Interfaces:**
- Consumes: Task 1 messages
- Produces:
  - `NominatimGeocode.requestTimeout` default `Duration(seconds: 10)`
  - One retry on HTTP 429 or `TimeoutException`, backoff `Duration(milliseconds: 600)`
  - `GooglePlacesSource.requestTimeout` default `Duration(seconds: 10)` applied to the POST (empty key still returns immediately)
  - `_reload` is a no-op while the current `_pending` is not done (disable Try again)

- [ ] **Step 1: Write the failing tests**

Nominatim — hang then succeed must not wait forever; a client that never completes should throw after timeout. Use a `MockClient` that returns a delayed future longer than a short injected timeout:

```dart
test('times out a hung Nominatim request', () async {
  final client = MockClient((_) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return http.Response('[]', 200);
  });
  final geocoder = NominatimGeocode(
    client,
    requestTimeout: const Duration(milliseconds: 50),
  );

  expect(
    () => geocoder.geocode(const NearbyQuery()),
    throwsA(isA<NominatimException>()),
  );
});

test('retries once on HTTP 429 then succeeds', () async {
  var calls = 0;
  final client = MockClient((_) async {
    calls++;
    if (calls == 1) return http.Response('rate limit', 429);
    return http.Response(
      jsonEncode([
        {
          'lat': '40.4862167',
          'lon': '-74.4518188',
          'boundingbox': ['40.45', '40.52', '-74.49', '-74.40'],
        },
      ]),
      200,
    );
  });
  final geocoder = NominatimGeocode(
    client,
    retryBackoff: Duration.zero,
  );
  final point = await geocoder.geocode(const NearbyQuery());
  expect(calls, 2);
  expect(point.lat, closeTo(40.4862167, 0.0001));
});
```

Screen — stub repository whose first `fetch` does not complete until a completer is finished; tap Try again immediately; `calls` must stay 1 until the first future completes.

```dart
testWidgets('try again is ignored while a fetch is in flight', (tester) async {
  final first = Completer<NearbyFetchResult>();
  final repository = _DelayedStubRepository(first.future);

  await tester.pumpWidget(/* NearbyScreen live + repository */);
  await tester.pump(); // still loading
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // No Try again yet (loading). Complete as unavailable, tap twice quickly.
  first.complete(_result(resources: const [], status: NearbySourceStatus.unavailable));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Try again'));
  await tester.tap(find.text('Try again'));
  await tester.pump();
  expect(repository.calls, 2); // init + one reload, not three
});
```

`_DelayedStubRepository` can extend the existing stub: first call returns the injected future; later calls increment `calls` and return a completed unavailable result. Adjust the existing “try again refetches” test so it still passes (wait for settle between taps).

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/nearby/nominatim_geocode_test.dart test/features/nearby/nearby_screen_test.dart`

Expected: FAIL — no timeout field; double tap increments twice.

- [ ] **Step 3: Implement**

Nominatim: `.timeout(requestTimeout)` on `get`; on `TimeoutException` or status 429, retry once then `throw NominatimException('lookup timed out')` / `'HTTP 429'` **without** attaching `response.body` to any member-facing path (repository already sanitizes).

Google: wrap the existing POST in `.timeout(requestTimeout)` and let the existing `catch` soft-fail.

Screen:

```dart
bool _reloadQueued = false;

void _reload() {
  if (_reloadQueued) return;
  _reloadQueued = true;
  setState(() {
    _pending = _repository.fetch(_query).whenComplete(() {
      _reloadQueued = false;
    });
  });
}
```

Disable the Try again `FilledButton` when `_reloadQueued` is true (`onPressed: null`).

User-Agent stays in this task only if Task 5 does not own it — **leave UA for Task 5** so this task stays timeouts/retry.

- [ ] **Step 4: Re-run tests**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git commit -m "fix(nearby): timeout Nominatim/Google and coalesce reloads"
```

---

### Task 3: Opening hours — weekday `off` and `24:00`

**Files:**
- Modify: `lib/features/nearby/data/opening_hours.dart`
- Test: `test/features/nearby/opening_hours_test.dart`

**Interfaces:**
- Consumes: existing `parseOpeningHours`
- Produces: same function. New accepted chunks:
  - `Su off` / `Mo-Sa off` → those days stay empty (Closed)
  - `24:00` as an interval end → `24 * 60` minutes (open through end of day)
  - `PH` / overnight / wrapping ranges still `unknown` when that chunk is the only content
  - Mixed `Mo-Fr 09:00-19:00; PH off` → **drop** the `PH` chunk, keep weekdays (do not fail the whole tag)

Keep the existing `PH off` **alone** → `unknown` test.

- [ ] **Step 1: Write the failing tests**

```dart
test('Su off keeps weekdays and marks Sunday closed', () {
  final view = parseOpeningHours(
    'Mo-Fr 09:00-19:00; Sa 09:00-17:00; Su off',
    DateTime.utc(2026, 8, 11, 14, 42),
  );
  expect(view.kind, OpeningHoursKind.openNow);
  expect(view.weekdayLines!.last, 'Sunday Closed');
});

test('00:00-24:00 is open all day', () {
  final view = parseOpeningHours(
    'Mo-Su 00:00-24:00',
    DateTime.utc(2026, 8, 11, 14, 42),
  );
  expect(view.kind, OpeningHoursKind.openNow);
});

test('PH off after a weekday rule is ignored, not fatal', () {
  final view = parseOpeningHours(
    'Mo-Fr 09:00-19:00; PH off',
    DateTime.utc(2026, 8, 11, 14, 42),
  );
  expect(view.kind, OpeningHoursKind.openNow);
  expect(view.weekdayLines, isNotNull);
});
```

Leave `test('PH off is unknown')` as-is (string is only `PH off`).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/nearby/opening_hours_test.dart`

Expected: FAIL — `Su off` currently returns `unknown`.

- [ ] **Step 3: Implement**

Extend the rule regex **or** special-case before it:

```dart
final offMatch = RegExp(
  r'^(Mo|Tu|We|Th|Fr|Sa|Su)(?:-(Mo|Tu|We|Th|Fr|Sa|Su))? off$',
).firstMatch(rule);
if (offMatch != null) {
  // mark those days empty; continue
  continue;
}
if (RegExp(r'^PH\b').hasMatch(rule)) {
  continue; // drop public-holiday clause
}
```

`_hhmm`: allow `h == 24 && m == 0` → `24 * 60`. Interval `end <= start` still rejects overnight (`22:00-02:00`).

If every remaining chunk was dropped and no intervals exist → `unknown` (covers bare `PH off`).

- [ ] **Step 4: Re-run tests**

Expected: PASS, including the original table.

- [ ] **Step 5: Commit**

```bash
git commit -m "fix(nearby): parse weekday off and 24:00 hours"
```

---

### Task 4: Launchers, phone line, hide live map stub

**Files:**
- Create: `lib/features/nearby/data/nearby_launchers.dart`
- Modify: `lib/features/nearby/nearby_screen.dart` (`_actionsFor`, remove live `_MapToggle`)
- Modify: `android/app/src/main/AndroidManifest.xml` (`<queries>` add `sms` as well as `smsto`)
- Modify: `ios/Runner/Info.plist` (`LSApplicationQueriesSchemes`: `tel`, `sms`, `http`, `https`)
- Test: `test/features/nearby/nearby_launchers_test.dart`
- Test: `test/features/nearby/nearby_screen_test.dart`

**Interfaces:**
- Consumes: `NearbyResource.phone`, `lat`, `lng`, `name`
- Produces:
  - `Uri nearbyTelUri(String phone)` → `Uri(scheme: 'tel', path: digitsOnly)`
  - `Uri nearbySmsUri(String phone)` → `Uri(scheme: 'sms', path: digitsOnly)`
  - `Uri nearbyDirectionsUri({required double lat, required double lng, required String name, required bool isWeb})` — web: `https://www.openstreetmap.org/?mlat=&mlon=#map=16/lat/lng`; io: `geo:lat,lng?q=lat,lng(name)`
  - Live map switch **removed** (FIND-4 still a later plan). Demo map toggle **stays** (`widget_test` still taps it).

- [ ] **Step 1: Write the failing tests**

```dart
test('sms and tel strip decoration', () {
  expect(nearbyTelUri('(732) 555-0142').toString(), 'tel:7325550142');
  expect(nearbySmsUri('+1-732-555-0142').scheme, 'sms');
});

test('web directions use OSM, not Google', () {
  final uri = nearbyDirectionsUri(
    lat: 40.4862,
    lng: -74.4518,
    name: 'Highland Pharmacy',
    isWeb: true,
  );
  expect(uri.host, 'www.openstreetmap.org');
  expect(uri.toString(), isNot(contains('google.com')));
});

test('io directions use geo:', () {
  expect(
    nearbyDirectionsUri(
      lat: 40.4862,
      lng: -74.4518,
      name: 'Highland Pharmacy',
      isWeb: false,
    ).scheme,
    'geo',
  );
});
```

Screen:

```dart
testWidgets('live map toggle is hidden', (tester) async {
  // pump live screen with one resource
  expect(find.text('See these on a map'), findsNothing);
  expect(find.text('Map view is not ready yet'), findsNothing);
});

testWidgets('missing phone shows Phone not listed and still has Directions', (
  tester,
) async {
  final repository = _StubRepository(
    _result(resources: [_resource(name: 'No Phone Shop', phone: null)]),
  );
  await pumpScreen(/* live */);
  expect(find.text('Phone not listed'), findsOneWidget);
  expect(find.text('Call'), findsNothing);
  expect(find.text('Directions'), findsOneWidget);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL — files missing; live map toggle still present; Google URL still used.

- [ ] **Step 3: Implement**

Keep demo `_MapToggle`. Delete live `_showMapPlaceholder` state. Android `<queries>`: duplicate the SENDTO block with `android:scheme="sms"` **and** keep `smsto`. iOS add:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>tel</string>
  <string>sms</string>
  <string>http</string>
  <string>https</string>
</array>
```

`_actionsFor` uses the helpers with `kIsWeb` from `package:flutter/foundation.dart`.

- [ ] **Step 4: Re-run tests**

Also run `flutter test test/widget_test.dart` — demo map toggle test must still pass.

- [ ] **Step 5: Commit**

```bash
git commit -m "fix(nearby): OSM/geo directions, sms queries, hide live map stub"
```

---

### Task 5: Persistent last-success cache and cached geocode

**Files:**
- Modify: `pubspec.yaml` (`shared_preferences`)
- Modify: `lib/features/nearby/data/nearby_resource.dart` — `toJson`/`fromJson`
- Modify: `lib/features/nearby/data/nearby_fetch_result.dart` — `toJson`/`fromJson`
- Modify: `lib/features/nearby/data/sources/geo_point.dart` — `toJson`/`fromJson`
- Create: `lib/features/nearby/data/prefs_nearby_cache.dart`
- Modify: `lib/features/nearby/data/nearby_repository.dart` — on geocode throw, `cache.readPoint` then Overpass
- Modify: `lib/features/nearby/data/nearby_cache.dart` — add optional `readPoint`/`writePoint` with default empty impl **or** put both on `PrefsNearbyCache` only and add methods to the abstract class
- Modify: `lib/features/nearby/nearby_screen.dart` — boot via prefs when no injected repository
- Modify: `lib/features/nearby/data/sources/nominatim_geocode.dart` — UA
- Test: `test/features/nearby/prefs_nearby_cache_test.dart`
- Test: `test/features/nearby/nearby_repository_test.dart`
- Test: `test/features/nearby/nominatim_geocode_test.dart` (UA contains github.com)

**Interfaces:**
- Consumes: Task 1 sanitized errors
- Produces:
  - `abstract class NearbyCache { Future<NearbyFetchResult?> read(...); Future<void> write(...); Future<GeoPoint?> readPoint(NearbyQuery); Future<void> writePoint(NearbyQuery, GeoPoint); }`
  - `InMemoryNearbyCache` also stores points in a second map
  - `class PrefsNearbyCache implements NearbyCache` keys `nearby.v1.result.{town}|{ST}` and `nearby.v1.point.{town}|{ST}`
  - Payload is last POI list + timestamp + status only. **No identity, no device id, no GPS.**
  - Repository `fetch`: after successful geocode, `writePoint`. On geocode failure, if `readPoint` hits, continue Google/OSM using that point; if those fail, existing `_cachedOr` list path
  - UA: `CWCHealthApp/0.1 (https://github.com/ks1686/rutgers-health-services-app; Rutgers CWC research)` — **no personal email**

- [ ] **Step 1: Add dependency and write failing tests**

```bash
flutter pub add shared_preferences
```

```dart
test('prefs cache survives a new instance', () async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final a = PrefsNearbyCache(prefs);
  await a.write(query, result);
  await a.writePoint(query, area);
  final b = PrefsNearbyCache(prefs);
  expect((await b.read(query))!.resources.single.name, 'Highland Pharmacy');
  expect((await b.readPoint(query))!.lat, closeTo(40.4862, 0.0001));
});

test('geocode failure with cached point still queries Overpass', () async {
  final cache = InMemoryNearbyCache();
  await cache.writePoint(query, area);
  final overpass = _FakeOverpass(result: [_resource(id: 'o1', name: 'From cache point')]);
  final repo = build(
    geocode: _FakeGeocode(error: Exception('down')),
    google: _FakeGoogle(GooglePlacesSoftFail('missing_key')),
    overpass: overpass,
    cache: cache,
  );
  final result = await repo.fetch(query);
  expect(overpass.calls, 1);
  expect(result.status, NearbySourceStatus.osm);
  expect(result.resources.single.name, 'From cache point');
});
```

Update the existing Nominatim UA assertion from `contains('CWCHealthApp')` to also `contains('github.com/ks1686/rutgers-health-services-app')`.

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL — `PrefsNearbyCache` missing; geocode throw skips Overpass.

- [ ] **Step 3: Implement**

JSON must be lossless enough for list display: id, name, category, address, phone, lat, lng, openingHoursRaw, source, fetchedAt (ISO-8601 UTC), status enum name, message.

Screen boot when `widget.repository == null`:

```dart
_pending = _boot();

Future<NearbyFetchResult> _boot() async {
  final prefs = await SharedPreferences.getInstance();
  final client = http.Client();
  _ownedClient = client;
  _repository = NearbyRepository.fromClient(
    client,
    config: widget.config,
    cache: PrefsNearbyCache(prefs),
  );
  return _repository.fetch(_query);
}
```

Injected repository path (tests) unchanged.

- [ ] **Step 4: Re-run Nearby tests**

Run: `flutter test test/features/nearby`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(nearby): persist last-success list and geocode point"
```

---

### Task 6: Honest demo chrome and optional Help Now dialers

**Files:**
- Modify: `lib/features/my_health/my_health_screen.dart`
- Modify: `lib/features/more/more_screen.dart`
- Modify: `lib/data/demo_help_now.dart`
- Modify: `lib/features/help_now/help_now_screen.dart`
- Create: `lib/features/help_now/help_now_config.dart`
- Test: `test/features/help_now/help_now_screen_test.dart`
- Test: `test/widget_test.dart` (banner / erase copy)

**Interfaces:**
- Consumes: `url_launcher` (already a dependency)
- Produces:
  - PIN banner copy: `Sample only — this build does not lock My Health yet.`
  - Erase snackbar: `Nothing to erase in this demo. Your health info is not saved on this phone.`
  - `HelpNowConfig.fromEnvironment()` with `helpNowLive: bool.fromEnvironment('HELP_NOW_LIVE', defaultValue: false)`
  - `DemoHelpAction` gains optional `Uri? callUri` and `Uri? textUri`
  - 988: two actions when live — `Call 988` (`tel:988`) and `Text 988` (`sms:988`); when flag off, keep one combined demo button
  - 911: `tel:911` when live
  - Poison Control: `tel:18002221222` when live
  - NJ Peer Warmline + My Wellness Center: **always** demo snackbar (`sample number`)
  - Default flag **false**. Meeting APKs stay demo.

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('My Health banner does not claim a PIN', (tester) async {
  await pumpApp(tester);
  await tester.tap(find.text('My Health').last);
  await tester.pumpAndSettle();
  expect(find.textContaining('Protected by your PIN'), findsNothing);
  expect(find.textContaining('does not lock My Health'), findsOneWidget);
});

testWidgets('Erase explains nothing is stored', (tester) async {
  await pumpApp(tester);
  await tester.tap(find.text('More').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Erase My Information'));
  await tester.pumpAndSettle();
  expect(find.textContaining('Nothing to erase'), findsOneWidget);
});

testWidgets('flag-off Help Now stays demo-only', (tester) async {
  await tester.pumpWidget(MaterialApp(
    theme: buildCwcTheme(),
    home: const HelpNowScreen(config: HelpNowConfig(helpNowLive: false)),
  ));
  await tester.tap(find.text('988 Suicide & Crisis Lifeline'));
  await tester.pumpAndSettle();
  expect(find.textContaining('Demo only'), findsOneWidget);
});

testWidgets('flag-on 988 splits call and text and launches tel/sms', (tester) async {
  final launched = <Uri>[];
  await tester.pumpWidget(MaterialApp(
    theme: buildCwcTheme(),
    home: HelpNowScreen(
      config: const HelpNowConfig(helpNowLive: true),
      launcher: (uri) async {
        launched.add(uri);
        return true;
      },
    ),
  ));
  await tester.tap(find.text('Call 988'));
  await tester.pumpAndSettle();
  expect(launched.single.scheme, 'tel');
  launched.clear();
  await tester.tap(find.text('Text 988'));
  await tester.pumpAndSettle();
  expect(launched.single.scheme, 'sms');
});
```

Help Now screen needs an optional `NearbyLinkLauncher`-style callback (extract a shared typedef to `lib/widgets/link_launcher.dart` if that is cleaner than duplicating).

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL — old PIN/Erase copy; no `HelpNowConfig`.

- [ ] **Step 3: Implement**

Do not enable `HELP_NOW_LIVE` in CI or README as the default demo. Document next to `LIVE_NEARBY` with the same “meeting APK stays off” rule. Warmline/CWC buttons ignore the flag.

- [ ] **Step 4: Re-run**

`flutter test test/widget_test.dart test/features/help_now`

Expected: PASS. Existing “Help Now stays reachable” still finds `You're not alone`.

- [ ] **Step 5: Commit**

```bash
git commit -m "fix: honest PIN/Erase copy and gated Help Now dialers"
```

---

### Task 7: ACC-1/2 — 18pt body, 48dp Help Now, Learn large text

**Files:**
- Modify: `lib/theme/cwc_theme.dart`
- Modify: `lib/widgets/help_now_button.dart`
- Modify: `lib/widgets/demo_banner.dart`
- Modify: `lib/features/learn/learn_screen.dart`
- Modify: `lib/features/nearby/nearby_screen.dart` (live address / disclaimer / chips → theme body, not 13pt hardcode)
- Modify: `lib/features/nearby/widgets/nearby_live_disclaimer.dart`
- Modify: `lib/shell/app_shell.dart` — `toolbarHeight: 64` if the 48dp pill clips
- Test: `test/theme/cwc_theme_test.dart`
- Test: `test/widgets/help_now_button_test.dart`
- Test: `test/features/learn/learn_screen_test.dart`

**Interfaces:**
- Consumes: Task 4 live screen without map toggle
- Produces:
  - `textTheme` bodyLarge/bodyMedium/bodySmall ≥ 18
  - `FilledButton` / `OutlinedButton` already 48dp; Help Now becomes a `FilledButton` with `minimumSize: Size(48, 48)`
  - Learn: `crossAxisCount: textScaler.scale(1) >= 1.3 ? 1 : 2` and no `Spacer` that clips; use `mainAxisSize: min` / `FittedBox` only if needed — prefer intrinsic column
  - Nav bar labels may stay 14 (four tabs). Do not force 18pt into the nav.

- [ ] **Step 1: Write the failing tests**

```dart
test('theme body is at least 18', () {
  final theme = buildCwcTheme();
  expect(theme.textTheme.bodyMedium!.fontSize! >= 18, isTrue);
  expect(theme.textTheme.bodyLarge!.fontSize! >= 18, isTrue);
});

testWidgets('Help Now pill is at least 48 dp tall', (tester) async {
  await tester.pumpWidget(MaterialApp(
    theme: buildCwcTheme(),
    home: const Scaffold(appBar: AppBar(actions: [HelpNowButton()])),
  ));
  final size = tester.getSize(find.widgetWithText(FilledButton, 'Help Now'));
  expect(size.height, greaterThanOrEqualTo(48));
});

testWidgets('Learn at 2.0 text scale does not overflow', (tester) async {
  FlutterError.onError = (details) {
    if (details.exception is FlutterError &&
        details.exception.toString().contains('overflowed')) {
      fail(details.exception.toString());
    }
    FlutterError.presentError(details);
  };
  await tester.pumpWidget(MaterialApp(
    theme: buildCwcTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
      child: child!,
    ),
    home: const Scaffold(body: LearnScreen()),
  ));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(find.text('Physical Health'), findsOneWidget);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL — body ~14; Help Now is InkWell ~32–36dp; Learn may overflow (if it does not overflow in test, still switch to 1 column at 2.0 and assert `find.byType(GridView)` delegate count via key or by finding one tile per row width).

- [ ] **Step 3: Implement**

```dart
textTheme: base.textTheme.copyWith(
  bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.4),
  bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 18, height: 1.4),
  bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 18, height: 1.4),
  titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
),
```

Replace hardcoded 12–13pt on live Nearby secondary text with `Theme.of(context).textTheme.bodyMedium` / `color: CwcColors.sub`. Hours control stays 18pt (already).

Help Now:

```dart
FilledButton(
  style: FilledButton.styleFrom(
    minimumSize: const Size(48, 48),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    tapTargetSize: MaterialTapTargetSize.padded,
  ),
  onPressed: () { /* existing push */ },
  child: const Text('Help Now'),
)
```

Drop the extra `Semantics` wrapper if the button text is already “Help Now”.

- [ ] **Step 4: Re-run**

`flutter test test/theme test/widgets test/features/learn test/widget_test.dart test/features/nearby/nearby_screen_test.dart`

Expected: PASS. Fix any finder that assumed 13pt-only copy layout.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(a11y): 18pt body, 48dp Help Now, Learn large-text layout"
```

---

### Task 8: Thin bundled JSON catalogs

**Files:**
- Create: `assets/content/learn.json`
- Create: `assets/content/help_now.json`
- Create: `assets/content/health.json`
- Create: `assets/content/resources.json` (demo Nearby rows only)
- Modify: `pubspec.yaml` `flutter.assets`
- Create: `lib/data/content_catalog.dart` — `Future<X> loadLearnTopics(AssetBundle bundle)` etc.
- Modify: `lib/data/demo_learn.dart`, `demo_help_now.dart`, `demo_health.dart`, `demo_resources.dart` — become parsers + `fromJson`; keep const fallbacks **or** load at screen init
- Modify screens to take an optional preloaded list (tests can pass the current literals)
- Test: `test/data/content_catalog_test.dart`

**Interfaces:**
- Consumes: Task 6 Help Now action shape (`label`, `detail`, `style`, optional uris)
- Produces: `rootBundle` loaders. Content stays the same sample copy. This is the TECH-5 seam only — no network fetch.

Do **not** persist My Health. JSON is read-only bundled demo.

- [ ] **Step 1: Write the failing test**

```dart
test('learn.json parses six sourced topics', () async {
  final bundle = TestAssetBundle(); // or DefaultAssetBundle via TestWidgetsFlutterBinding
  final topics = await loadLearnTopics(bundle);
  expect(topics, hasLength(6));
  expect(topics.first.source, isNotEmpty);
});
```

Simplest path: put the JSON under `assets/content/` and in the test use `File('assets/content/learn.json').readAsStringSync()` plus a pure `parseLearnTopics(String json)` so you do not need a widget binding.

```dart
List<DemoLearnTopic> parseLearnTopics(String json);
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL — parser / asset missing.

- [ ] **Step 3: Implement**

Move current literals into JSON. Screens: if `topics:` not injected, load via `FutureBuilder` + `rootBundle`. To avoid a loading flash in flag-off meeting APKs, keep a synchronous `parseLearnTopics` used with a **compile-time fallback string** only if you must — prefer `FutureBuilder` with the existing scaffold (short). Widget tests that tap `Physical Health` must `pumpAndSettle` (they already do).

Remove unused `DemoAppointment.phone` from the UI? Keep the field in JSON for the future Call action; still do not show it until My Health is real.

- [ ] **Step 4: Re-run**

`flutter test test/data test/widget_test.dart test/features/help_now`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git commit -m "refactor: load demo Learn/Help Now/My Health from bundled JSON"
```

---

### Task 9: CI, hygiene, labels, dead weight

**Files:**
- Modify: `.github/workflows/flutter-ci.yml`
- Modify: `.gitignore`
- Modify: `pubspec.yaml` — remove `cupertino_icons` if unused
- Modify: `android/app/src/main/AndroidManifest.xml` `android:label`
- Modify: `ios/Runner/Info.plist` `CFBundleDisplayName` / `CFBundleName`
- Create: `.github/CODEOWNERS`
- Create: `.github/dependabot.yml`
- Modify: `README.md`, `docs/engineering/README.md`, `docs/engineering/nearby-live-data.md`

**Interfaces:** none.

- [ ] **Step 1: Confirm cupertino_icons is unused**

Run: `rg "cupertino_icons|CupertinoIcons" --glob '!pubspec.lock'`

Expected: only `pubspec.yaml`. Then delete the dependency.

- [ ] **Step 2: CI**

In `build-android`, after the debug APK:

```yaml
      - name: Build unsigned release APK
        run: flutter build apk --release
```

Do not add signing. This is the regression lock for release-manifest misses (`INTERNET`, `<queries>`).

- [ ] **Step 3: gitignore IRB dumps**

```
# IRB / survey exports — never commit identifiable dumps
*.xlsx
*.xls
**/*qualtrics*
**/*survey*.csv
survey-exports/
```

- [ ] **Step 4: Labels + CODEOWNERS + Dependabot**

- Android label: `CWC Health App`
- iOS display name: `CWC Health App`
- `.github/CODEOWNERS`: `* @ks1686`
- Dependabot: `github-actions` weekly; `pub` weekly, directory `/`

- [ ] **Step 5: Docs**

- `docs/engineering/README.md`: remove “readable hours” from next-work; list this hardening plan; mention release APK in CI.
- `docs/engineering/nearby-live-data.md` Next engineering: mark persistent cache + hours `off` + hidden live map as this plan; FIND-4 remains next product plan; hardware Call tap still unverified.
- README: CI includes release APK; warn that a web `--dart-define=GOOGLE_PLACES_API_KEY` **embeds the key in JS** — do not do this; empty key is correct. Document `HELP_NOW_LIVE` default off. Document persistent cache (on-device last list only).

Do **not** enable GitHub branch protection from the agent. After Review, tell Karim the exact `gh` command and wait.

- [ ] **Step 6: Commit**

```bash
git commit -m "chore: release APK in CI, IRB gitignore, app labels"
```

---

### Task 10: Close-out verification

**Files:** none new unless a test failed.

- [ ] **Step 1: Full local CI equivalent**

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --reporter expanded
flutter test integration_test -d flutter-tester
```

Expected: all green **without** `LIVE_NEARBY=true`.

- [ ] **Step 2: Optional compile**

```bash
flutter build web --release
flutter build apk --debug
flutter build apk --release
```

If Android SDK is missing, skip APK and rely on CI.

- [ ] **Step 3: Sync AGENTS.md engineering paragraph**

One short update: live map stub hidden; persistent cache on; Help Now still default demo; ACC type/target fixes. Do not rewrite FIND-1.

- [ ] **Step 4: Commit docs if needed, then stop**

Do not push. Do not open a PR. Parent runs Review + `security-scan` first.

---

## Out of scope (do not implement)

- FIND-4 OSM map tiles
- Real PIN / FLAG_SECURE / My Health persistence
- Real Erase of stored PHI (nothing is stored)
- NJ warmline / CWC live numbers
- GPS / walk-time / Places SDK / Inter
- Branch protection API change
- Physical Android/iOS hardware taps (still a human follow-up)

## Test / verification notes

- Default suite stays flag-off.
- New live-path tests inject `NearbyScreen(config: live, repository: stub)`.
- `SharedPreferences.setMockInitialValues` for cache tests.
- Integration smoke still only checks tab keys + Help Now reachability.

## Fast-path: no
