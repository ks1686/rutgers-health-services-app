# Nearby Live Data Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Gate:** Implementation started on `feat/nearby-live-task1` (Task 1 complete). Continue task-by-task; do not skip ahead without tests.

**Goal:** Add a flag-gated live Nearby pipeline (Google Places soft-fail → OSM Overpass) on Flutter iOS/Android while keeping the static demo as the default.

**Architecture:** Pure-Dart HTTP under `lib/features/nearby/data/`. `NearbyRepository` geocodes the town via Nominatim, tries Google Places when a key exists, soft-fails to Overpass, normalizes to `NearbyResource`, optionally caches last success. `NearbyScreen` switches on `LIVE_NEARBY`.

**Tech Stack:** Flutter (`cwc_health_app`), `http`, `url_launcher` (live call/SMS/maps), optional `shared_preferences` for cache. No `google_maps_flutter`, no MapKit search, no Google billing setup.

## Global Constraints

- `LIVE_NEARBY` defaults **false** — meeting demos stay on static data.
- Never commit API keys; Google key only via `--dart-define=GOOGLE_PLACES_API_KEY`.
- Study build does **not** enable Google Cloud billing; OSM must work with empty key.
- No curated CWC/wellness overlay JSON.
- Same Dart path on iOS and Android.
- Live mode must not silently fall back to fake demo rows.
- Plain-language copy (~6th grade); unvetted disclaimer + “Updated as of …” in live UI.
- Do not rewrite FIND-1 in the feature spec inside this implementation PR (docs already note the tension).
- ≥48dp targets; body text stays ACC-aware (do not shrink type for density).

**Design / handoff:** [`docs/superpowers/specs/2026-08-11-nearby-live-data-design.md`](../specs/2026-08-11-nearby-live-data-design.md), [`docs/engineering/nearby-live-data.md`](../../engineering/nearby-live-data.md).

---

### Task 1: Models, config, and dependency stubs — **COMPLETE**

**Status:** Done on `feat/nearby-live-task1` (`c912eaa` + follow-ups). Verified with expanded unit tests, `dart format`, `flutter analyze --fatal-infos`, and `flutter test`. CI workflow enforces the same checks.

**Files:**
- Create: `lib/features/nearby/data/nearby_resource.dart`
- Create: `lib/features/nearby/data/nearby_query.dart`
- Create: `lib/features/nearby/data/nearby_config.dart`
- Create: `lib/features/nearby/data/nearby_fetch_result.dart`
- Modify: `pubspec.yaml` — add `http: ^1.2.2` (or current stable), `url_launcher: ^6.3.1`
- Test: `test/features/nearby/nearby_config_test.dart`

**Interfaces:**
- Produces:
  - `enum NearbySourceStatus { google, osm, cache, unavailable }`
  - `enum NearbyCategory { pharmacy, clinic, urgentCare }` with `String get label`
  - `class NearbyResource` fields: `id`, `name`, `category` (`String` label matching demo chips), `address`, `phone` (`String?`), `lat`, `lng`, `status`, `source` (`String`: `google`|`osm`|`cache`), `fetchedAt` (`DateTime`)
  - `class NearbyQuery { final String town; final String stateCode; }` default `town: 'New Brunswick', stateCode: 'NJ'`
  - `class NearbyConfig { final bool liveNearby; final String googlePlacesApiKey; static NearbyConfig fromEnvironment(); }`
  - `fromEnvironment` reads `bool.fromEnvironment('LIVE_NEARBY', defaultValue: false)` and `String.fromEnvironment('GOOGLE_PLACES_API_KEY', defaultValue: '')`
  - `class NearbyFetchResult { final List<NearbyResource> resources; final NearbySourceStatus status; final DateTime fetchedAt; final String? message; }`

- [x] **Step 1: Write the failing config test**
- [x] **Step 2: Run test to verify it fails**
- [x] **Step 3: Add dependencies and implement models/config**
- [x] **Step 4: Run test to verify it passes**
- [x] **Step 5: Commit**

---

### Task 2: Nominatim geocode + Overpass source

**Files:**
- Create: `lib/features/nearby/data/sources/nominatim_geocode.dart`
- Create: `lib/features/nearby/data/sources/osm_overpass_source.dart`
- Create: `test/features/nearby/fixtures/overpass_new_brunswick_sample.json`
- Test: `test/features/nearby/osm_overpass_source_test.dart`
- Test: `test/features/nearby/nominatim_geocode_test.dart`

**Interfaces:**
- Consumes: `NearbyQuery`, `NearbyResource`, `http.Client`
- Produces:
  - `class GeoPoint { final double lat; final double lng; final double? bboxSouth, bboxNorth, bboxWest, bboxEast; }`
  - `class NominatimGeocode { NominatimGeocode(http.Client client, {String userAgent}); Future<GeoPoint> geocode(NearbyQuery query); }`
  - `class OsmOverpassSource { OsmOverpassSource(http.Client client, {String userAgent}); Future<List<NearbyResource>> fetch(GeoPoint area, {DateTime? fetchedAt}); }`
  - User-Agent (required): `CWCHealthApp/0.1 (Rutgers CWC research; contact: via repo)` — adjust contact if team supplies email later
  - NJ guard: drop points outside roughly `lat 38.8–41.4`, `lng -75.6–-73.8`

- [ ] **Step 1: Write failing Overpass parser test with fixture**

Fixture: minimal Overpass JSON with one `amenity=pharmacy` node (name, lat, lon, phone) and one clinic way with `center`.

```dart
test('parses pharmacy and clinic into NearbyResource', () async {
  // inject MockClient returning fixture body
  final resources = await source.fetch(fixedGeoPoint);
  expect(resources.map((r) => r.category), containsAll(['Pharmacy', 'Clinic']));
});
```

- [ ] **Step 2: Run test — expect FAIL**

Run: `flutter test test/features/nearby/osm_overpass_source_test.dart`

- [ ] **Step 3: Implement Nominatim + Overpass**

Nominatim: `GET https://nominatim.openstreetmap.org/search?city=...&state=New%20Jersey&country=USA&format=json&limit=1` with User-Agent header.

Overpass: POST to `https://overpass-api.de/api/interpreter` with a query around bbox or radius (~3–5 km) for:

```text
amenity=pharmacy → Pharmacy
amenity=clinic / healthcare=clinic → Clinic
amenity=doctors or healthcare=urgent_care / tag variants → Urgent care only when confident; else skip
```

Prefer under-claiming categories. Map `phone` / `contact:phone`. Status default: `Hours not listed` when no opening_hours.

- [ ] **Step 4: Run OSM + Nominatim unit tests — expect PASS**

Run: `flutter test test/features/nearby/`

- [ ] **Step 5: Commit**

```bash
git add lib/features/nearby/data/sources/ test/features/nearby/
git commit -m "$(cat <<'EOF'
Add Nominatim geocode and OSM Overpass Nearby sources.

EOF
)"
```

---

### Task 3: Google Places source (soft-fail, no billing)

**Files:**
- Create: `lib/features/nearby/data/sources/google_places_source.dart`
- Test: `test/features/nearby/google_places_source_test.dart`

**Interfaces:**
- Consumes: `NearbyConfig.googlePlacesApiKey`, `GeoPoint`, `http.Client`
- Produces:
  - `sealed class GooglePlacesOutcome {}`
  - `class GooglePlacesOk extends GooglePlacesOutcome { final List<NearbyResource> resources; }`
  - `class GooglePlacesSoftFail extends GooglePlacesOutcome { final String reason; }`
  - `class GooglePlacesSource { Future<GooglePlacesOutcome> fetch(GeoPoint area); }`
  - Empty key → `GooglePlacesSoftFail('missing_key')` **without** HTTP
  - HTTP 403 / permission / billing-style errors → `GooglePlacesSoftFail`
  - Success with zero results → `GooglePlacesOk([])` (repository still tries OSM)

- [ ] **Step 1: Write failing tests**

```dart
test('empty key soft-fails without calling HTTP', () async { ... });
test('403 soft-fails', () async { ... });
test('200 maps places to NearbyResource', () async { ... });
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement Places API (New) HTTP client**

Use Places Nearby Search (New) or Text Search over HTTPS to `places.googleapis.com` with header `X-Goog-Api-Key` and field mask for id, displayName, formattedAddress, location, nationalPhoneNumber, types. Map types to Pharmacy / Clinic / Urgent care; drop unmatched.

Do **not** add billing docs or setup scripts.

- [ ] **Step 4: Run tests — PASS**

- [ ] **Step 5: Commit**

```bash
git add lib/features/nearby/data/sources/google_places_source.dart test/features/nearby/google_places_source_test.dart
git commit -m "$(cat <<'EOF'
Add Google Places Nearby source with expected soft-fail path.

EOF
)"
```

---

### Task 4: NearbyRepository + optional cache

**Files:**
- Create: `lib/features/nearby/data/nearby_repository.dart`
- Create: `lib/features/nearby/data/nearby_cache.dart` (memory first; `shared_preferences` JSON optional in same task if quick)
- Test: `test/features/nearby/nearby_repository_test.dart`

**Interfaces:**
- Consumes: `NearbyConfig`, `NominatimGeocode`, `GooglePlacesSource`, `OsmOverpassSource`, cache
- Produces:
  - `class NearbyRepository { Future<NearbyFetchResult> fetch(NearbyQuery query); }`
  - Order: geocode → Google → if SoftFail or empty-ok policy then OSM → on OSM failure try cache → else `unavailable`
  - Dedupe: same name (case-fold) within ~50 m → keep first
  - Stamp `fetchedAt` on all rows

- [ ] **Step 1: Write repository tests with fake sources**

```dart
test('google soft-fail uses OSM results', () async { ... });
test('both fail with cache returns cache status', () async { ... });
test('both fail without cache returns unavailable', () async { ... });
```

- [ ] **Step 2: Run — FAIL**

- [ ] **Step 3: Implement repository + in-memory cache**

If adding `shared_preferences`, add dep in this commit and serialize `NearbyFetchResult` for the last town key.

- [ ] **Step 4: Run — PASS**

- [ ] **Step 5: Commit**

```bash
git add lib/features/nearby/data/nearby_repository.dart lib/features/nearby/data/nearby_cache.dart test/features/nearby/nearby_repository_test.dart pubspec.yaml pubspec.lock
git commit -m "$(cat <<'EOF'
Orchestrate Nearby Google soft-fail to OSM with cache fallback.

EOF
)"
```

---

### Task 5: Wire NearbyScreen behind LIVE_NEARBY

**Files:**
- Modify: `lib/features/nearby/nearby_screen.dart`
- Modify: `lib/app.dart` or `lib/main.dart` — construct `NearbyConfig.fromEnvironment()` and pass config/repository if needed
- Create: `lib/features/nearby/widgets/nearby_live_disclaimer.dart`
- Test: `test/features/nearby/nearby_screen_test.dart`
- Modify: `test/widget_test.dart` if smoke test breaks

**Interfaces:**
- Consumes: `NearbyConfig`, `NearbyRepository` (injectable for tests)
- Demo path: unchanged `demo_resources` + demo snackbars
- Live path: load on init; show disclaimer; category filter; real `url_launcher` for call/sms/directions when phone/coords present
- Empty/unavailable: plain message, no demo rows

- [ ] **Step 1: Write widget tests**

```dart
testWidgets('demo mode shows DemoBanner and sample pharmacy', (tester) async { ... });
testWidgets('live mode shows unvetted disclaimer and repo cards', (tester) async { ... });
```

- [ ] **Step 2: Run — FAIL**

- [ ] **Step 3: Implement UI wiring**

Disclaimer copy (live only):

> These places come from public maps data. They are not checked by our team. Updated as of &lt;local time&gt;.

Keep map toggle placeholder. Town chip may stay New Brunswick for v1 (fixed `NearbyQuery`).

- [ ] **Step 4: `flutter test` — PASS; manual web/android smoke with `LIVE_NEARBY=false`**

- [ ] **Step 5: Commit**

```bash
git add lib/features/nearby/ lib/app.dart lib/main.dart test/
git commit -m "$(cat <<'EOF'
Gate live Nearby repository behind LIVE_NEARBY with disclaimer UI.

EOF
)"
```

---

### Task 6: Cross-platform verification + README flags

**Files:**
- Modify: `README.md` — document `LIVE_NEARBY` / `GOOGLE_PLACES_API_KEY`
- Modify: `docs/engineering/nearby-live-data.md` — mark implementation status when done

- [ ] **Step 1: Run full test suite**

Run: `flutter test`

- [ ] **Step 2: Manual live-on OSM (no Google key)**

```bash
flutter run -d chrome --dart-define=LIVE_NEARBY=true
# Also once each: Android emulator/device and iOS simulator if available
```

Expect: OSM (or cache/empty) — not demo fake names unless they coincidentally exist in OSM.

- [ ] **Step 3: Confirm demo default**

```bash
flutter run -d chrome
```

Expect: unchanged static demo.

- [ ] **Step 4: Update README with flag docs (no billing instructions)**

- [ ] **Step 5: Commit**

```bash
git add README.md docs/engineering/nearby-live-data.md
git commit -m "$(cat <<'EOF'
Document Nearby LIVE_NEARBY flags after cross-platform smoke checks.

EOF
)"
```

---

### Task 7: Collaborator close-out

**Files:** none required beyond status tweaks in `docs/engineering/nearby-live-data.md`

- [ ] **Step 1: Set handoff status to “Implemented (flag default off)”** in `docs/engineering/nearby-live-data.md`
- [ ] **Step 2: List any OSM category mapping caveats discovered**
- [ ] **Step 3: Do not bump feature spec FIND-1 unless research team asks**
- [ ] **Step 4: Open or update PR description with test evidence (Android + iOS/web)**
- [ ] **Step 5: Commit doc status if changed**

---

## Spec coverage check

| Design requirement | Task |
|--------------------|------|
| Flag-gated demo default | 1, 5 |
| Google soft-fail | 3, 4 |
| OSM Overpass + Nominatim | 2, 4 |
| No curated CWC overlay | (omitted intentionally) |
| Disclaimer + as-of | 5 |
| Cross-platform HTTP | 2–6 |
| No silent demo swap in live mode | 4, 5 |
| Tests | 1–5 |

## Placeholder scan

None intentional. If Overpass endpoint mirrors change, update Task 2 URL only — keep soft-fail behavior.
