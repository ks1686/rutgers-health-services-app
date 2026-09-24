# CWC Health App

Navigation prototype for co-design feedback. Rutgers Scarlet chrome, four bottom tabs (**Nearby | My Health | Learn | More**), and a persistent **Help Now** control. **Nearby live listings** (OpenStreetMap) and interactive **My Health** (encrypted on-device) are in the study build. No accounts, no stored credentials, no third-party analytics.

**Ship targets: Android + iOS only.** Flutter web is not supported (no `web/` folder, not in CI).

## Run

Local review is **Android with live Nearby** (emulator or device).

```bash
flutter pub get
flutter run -d android --dart-define=LIVE_NEARBY=true --dart-define=HELP_NOW_LIVE=true
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
| Nearby | Live OSM pharmacies/clinics/urgent care behind `LIVE_NEARBY`; unvetted disclaimer; opt-in overhead map (Google when `GOOGLE_MAPS_API_KEY` set, else OSM tiles); shared category chips filter list + pins; Open now / Closed hours; live tab asks for one-shot location on load and sorts by proximity; town list is fallback only |
| My Health | On-device appointments / meds / providers (Keystore/Keychain); optional PIN; wallet card; Erase from More |
| Learn | Topics from bundled `assets/content/learn.json` (offline); source labels on each article |
| More | List to placeholder pages; Erase clears My Health |
| Help Now | 911 first, then 988 / Poison Control / ReachNJ / Clearinghouse; demo only unless `HELP_NOW_LIVE`; emergency-card toggle at the top (real My Health wallet) |

## Project docs

- [`AGENTS.md`](AGENTS.md) — agent handoff
- [`CWC_Health_App/`](CWC_Health_App/) — requirements + design reference
- [`docs/engineering/nearby-live-data.md`](docs/engineering/nearby-live-data.md) — **Nearby live-data** collaborator handoff
- [`docs/superpowers/plans/2026-09-03-my-health.md`](docs/superpowers/plans/2026-09-03-my-health.md) — My Health interactive plan
- [`docs/engineering/learn-content.md`](docs/engineering/learn-content.md) — Learn JSON + CAB update path
- Figma: https://www.figma.com/design/yAwsNNegakKROue3o0CAMJ

### Nearby live data

**Default compile stays on static Nearby data** so a meeting build cannot accidentally show live listings. Local engineering uses the flag **on**. There is no runtime switch.

```bash
flutter run -d android --dart-define=LIVE_NEARBY=true --dart-define=HELP_NOW_LIVE=true
```

| Flag | Default | Effect |
|------|---------|--------|
| `LIVE_NEARBY` | `false` | `true` replaces the Nearby tab's sample listings with real places and shows the "not checked by our team" disclaimer |
| `HELP_NOW_LIVE` | `false` | `true` turns 911 / 988 / Poison Control / ReachNJ / Clearinghouse into `tel:`/`sms:` launches (user still places the call). Warmline and CWC stay sample. Meeting APKs stay off. |
| `GOOGLE_PLACES_API_KEY` | empty | Optional. Empty, unauthorized, or unbilled keys soft-fail silently to OpenStreetMap. Never commit keys. |
| `GOOGLE_MAPS_API_KEY` | empty | Optional FIND-4 map. Empty → OSM `flutter_map` (study default on Android). Non-empty on Android/iOS → Google Maps (also set `-PGOOGLE_MAPS_API_KEY=` / iOS `GMSApiKey`). |

**Never commit API keys.** Pass them per native build with `--dart-define` only if needed. Empty key is the correct study default.

#### How live mode behaves

The live tab asks for a **coarse, one-shot location fix** on load (`geolocator`, `LocationAccuracy.low`) on Android and iOS: no background updates, no fine/GPS permission on Android (`ACCESS_COARSE_LOCATION` only), iOS uses while-using with plain-language copy. Coordinates live in memory for that single search: Overpass runs an `around:` circle from the device point, the NJ-only guardrail is skipped (usable anywhere), results are **sorted nearest-first**, and **nothing is written to the cache** — an origin never touches storage. Each card gains a "~N min walk" badge (~80 m/min, straight-line). If the member declines, location services are off, or the fix times out, the tab falls back to the New Brunswick town list with a plain-language reason line and a *Use my location* retry — it never shows the town list as if it were device-based.

**Overhead map (FIND-4).** *See these on a map* loads tiles only when toggled on. Pins match the **category-filtered** list (same chips). Google Maps is used when `GOOGLE_MAPS_API_KEY` is set on a native build; otherwise OSM/Carto tiles via `flutter_map` (study default on Android). Panning does not refetch places. Tap a pin to highlight the matching card.

Overpass rate limits per IP and a room of phones on shared Wi-Fi counts as one IP, so the app tries three mirrors in order with a short retry. If you add a mirror, first confirm it serves planet-wide data — regional instances answer HTTP 200 with zero results, which would tell a member there is no pharmacy near them. See `kOverpassEndpoints`.

#### Platform notes

Live mode needs the `INTERNET` permission and Android 11+ package-visibility `<queries>` entries for the Call, Text, and Directions buttons; both are declared in `android/app/src/main/AndroidManifest.xml`. Directions use `geo:` on Android/iOS, not Google Maps. **macOS is not a supported target** — `macos/Runner/Release.entitlements` lacks `com.apple.security.network.client`, so live requests would fail there until someone adds it and tests on a Mac.

## Feedback questions this prototype supports

- Can you find Nearby vs My Health?
- Is Help Now always one tap away?
- Does More feel like a visible list (not a hidden menu)?
- Does scarlet branding feel supportive or alarming?

Draft for co-design — nothing is final until the community says so.
