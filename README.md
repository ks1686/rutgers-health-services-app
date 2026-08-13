# CWC Health App

Navigation prototype (v1) for co-design feedback. Rutgers Scarlet chrome, four bottom tabs (**Nearby | My Health | Learn | More**), and a persistent **Help Now** control. All content is **static demo data** — no accounts, permissions, persistence, maps, or real calls/SMS.

## Run

```bash
flutter pub get
flutter run -d chrome          # quick desktop review
# or: flutter run -d <android|ios device id>
```

## Verify (local = CI)

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
flutter test integration_test -d flutter-tester
# compile checks (also run in CI):
# flutter build web --release
# flutter build apk --debug
```

GitHub Actions runs format/analyze/tests, integration navigation smoke, web release build, and Android debug APK on every PR to `main` (see `.github/workflows/flutter-ci.yml`).

Run the suite **without** `--dart-define=LIVE_NEARBY=true`. With the flag on, three tests fail by design: one asserts the flag's default is off, and two assert the demo listings render. Live mode is supposed to hide demo data, so those failures confirm the separation rather than reveal a bug.

## What’s in this build

| Tab / screen | Demo behavior |
|--------------|---------------|
| Nearby | New Brunswick sample resources; category chips; map toggle placeholder (live locator available behind `LIVE_NEARBY`, off by default) |
| My Health | Sample appointments / meds / providers; wallet card screen |
| Learn | Six topics → short articles with source labels |
| More | List to placeholder pages; Erase → “Demo only” snackbar |
| Help Now | Full-screen support actions (demo only); emergency-card toggle UI |

## Project docs

- [`AGENTS.md`](AGENTS.md) — agent handoff
- [`CWC_Health_App/`](CWC_Health_App/) — requirements + design reference
- [`docs/engineering/nearby-live-data.md`](docs/engineering/nearby-live-data.md) — **Nearby live-data** collaborator handoff (implemented; flag default off)
- [`docs/superpowers/plans/2026-08-11-nearby-live-data.md`](docs/superpowers/plans/2026-08-11-nearby-live-data.md) — task-by-task implementation plan
- Figma: https://www.figma.com/design/yAwsNNegakKROue3o0CAMJ

### Nearby live data

**Default builds stay on static demo data.** Live mode is opt-in per build and there is no runtime switch, so a demo build cannot accidentally show live listings.

```bash
# Static demo (the default — what co-design sessions should use)
flutter run -d chrome

# Live locator: OpenStreetMap only, no key or billing required
flutter run -d chrome --dart-define=LIVE_NEARBY=true

# Live locator with a Google Places attempt layered in front of OSM
flutter run -d chrome --dart-define=LIVE_NEARBY=true --dart-define=GOOGLE_PLACES_API_KEY=...
```

| Flag | Default | Effect |
|------|---------|--------|
| `LIVE_NEARBY` | `false` | `true` replaces the Nearby tab's sample listings with real places and shows the "not checked by our team" disclaimer |
| `GOOGLE_PLACES_API_KEY` | empty | Optional. Empty, unauthorized, or unbilled keys soft-fail silently to OpenStreetMap — they never surface an error or block results |

**Never commit API keys.** Pass them per build with `--dart-define`.

#### How live mode behaves

The town is fixed to New Brunswick, NJ for v1 and there is no GPS path — the app geocodes the town name through Nominatim, then queries Overpass for pharmacies, clinics, and urgent care. Results are deduplicated, cached in memory, and stamped with the time they were fetched. When every source fails, the tab shows a plain message and a Try again button; **it never falls back to the demo listings**, because a member cannot tell invented data from real data.

Overpass rate limits per IP and a room of phones on shared Wi-Fi counts as one IP, so the app tries three mirrors in order with a short retry. If you add a mirror, first confirm it serves planet-wide data — regional instances answer HTTP 200 with zero results, which would tell a member there is no pharmacy near them. See `kOverpassEndpoints`.

#### Platform notes

Live mode needs the `INTERNET` permission and Android 11+ package-visibility `<queries>` entries for the Call, Text, and Directions buttons; both are declared in `android/app/src/main/AndroidManifest.xml`. Web works without a proxy because Nominatim and the Overpass mirrors send permissive CORS headers. **macOS is not a supported target** — `macos/Runner/Release.entitlements` lacks `com.apple.security.network.client`, so live requests would fail there until someone adds it and tests on a Mac.

## Feedback questions this prototype supports

- Can you find Nearby vs My Health?
- Is Help Now always one tap away?
- Does More feel like a visible list (not a hidden menu)?
- Does scarlet branding feel supportive or alarming?

Draft for co-design — nothing is final until the community says so.
