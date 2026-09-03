# CWC Health App

Navigation prototype for co-design feedback. Rutgers Scarlet chrome, four bottom tabs (**Nearby | My Health | Learn | More**), and a persistent **Help Now** control. **Nearby live listings** (OpenStreetMap) and interactive **My Health** (encrypted on-device) are in the study build. No accounts, no stored credentials, no third-party analytics.

**Ship targets: Android + iOS only.** Flutter web is not supported (no `web/` folder, not in CI).

## Run

Local review is **Android with live Nearby** (emulator or device).

```bash
flutter pub get
flutter run -d android --dart-define=LIVE_NEARBY=true
```

`LIVE_NEARBY` still **defaults off** at compile time, so a meeting APK without the flag keeps the fake New Brunswick list. Do not use the flag-off list as the working engineering demo.

Optional Google Places attempt (study build does not enable billing; OSM is the supported path):

```bash
flutter run -d android --dart-define=LIVE_NEARBY=true --dart-define=GOOGLE_PLACES_API_KEY=...
```

Never commit API keys.

## Verify (local = CI)

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
flutter test integration_test -d flutter-tester
# compile checks (also run in CI):
flutter build apk --debug
flutter build apk --release   # unsigned; locks the release manifest
```

GitHub Actions runs format/analyze/tests, integration navigation smoke, and Android debug **plus unsigned release** APK on every PR to `main` (see `.github/workflows/flutter-ci.yml`).

Run the suite **without** `--dart-define=LIVE_NEARBY=true`. With the flag on, three tests fail by design: one asserts the flag's default is off, and two assert the demo listings render. Live mode is supposed to hide demo data, so those failures confirm the separation rather than reveal a bug.

## What’s in this build

| Tab / screen | Demo behavior |
|--------------|---------------|
| Nearby | Live OSM pharmacies/clinics/urgent care (New Brunswick bbox) behind `LIVE_NEARBY`; unvetted disclaimer; live map toggle hidden until FIND-4; Open now / Closed expands weekday hours when OSM tags parse |
| My Health | On-device appointments / meds / providers (Keystore/Keychain); optional PIN; wallet card; Erase from More |
| Learn | Six topics → short articles with source labels |
| More | List to placeholder pages; Erase clears My Health |
| Help Now | Full-screen support actions (demo only unless `HELP_NOW_LIVE`); emergency-card toggle UI |

## Project docs

- [`AGENTS.md`](AGENTS.md) — agent handoff
- [`CWC_Health_App/`](CWC_Health_App/) — requirements + design reference
- [`docs/engineering/nearby-live-data.md`](docs/engineering/nearby-live-data.md) — **Nearby live-data** collaborator handoff
- [`docs/superpowers/plans/2026-09-03-my-health.md`](docs/superpowers/plans/2026-09-03-my-health.md) — My Health interactive plan
- Figma: https://www.figma.com/design/yAwsNNegakKROue3o0CAMJ

### Nearby live data

**Default compile stays on static Nearby data** so a meeting build cannot accidentally show live listings. Local engineering uses the flag **on**. There is no runtime switch.

```bash
flutter run -d android --dart-define=LIVE_NEARBY=true
```

| Flag | Default | Effect |
|------|---------|--------|
| `LIVE_NEARBY` | `false` | `true` replaces the Nearby tab's sample listings with real places and shows the "not checked by our team" disclaimer |
| `HELP_NOW_LIVE` | `false` | `true` turns 988 / 911 / Poison Control into `tel:`/`sms:` launches. Warmline and CWC stay sample. Meeting APKs stay off. |
| `GOOGLE_PLACES_API_KEY` | empty | Optional. Empty, unauthorized, or unbilled keys soft-fail silently to OpenStreetMap. Never commit keys. |

#### How live mode behaves

The town is fixed to New Brunswick, NJ for v1 (GPS may be a separate Nearby plan). The app geocodes the town name through Nominatim, then queries Overpass for pharmacies, clinics, and urgent care. Results are deduplicated, cached on-device (last-success list + town point only; no identity), and stamped with the time they were fetched. When every source fails, the tab shows a plain message and a Try again button; **it never falls back to the demo listings**. Directions use `geo:` on Android/iOS, not Google Maps.
