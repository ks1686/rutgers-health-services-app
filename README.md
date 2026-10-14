# CWC Health App

Version **1.0.0**. Rutgers Scarlet chrome, four bottom tabs (**Nearby | My Health | Learn | More**), and a persistent **Help Now** control. Nearby lists real OpenStreetMap places. My Health starts empty and stays on the device. No accounts, no stored credentials, no third-party analytics.

**Ship targets: Android + iOS only.** Flutter web is not supported (no `web/` folder, not in CI).

## Run

Local review is Android (emulator or device). Nearby is always live. Help Now dials unless you turn it off.

```bash
flutter pub get
flutter run -d android
```

Turn Help Now dialing off for a room where a tap must not open the phone app:

```bash
flutter run -d android --dart-define=HELP_NOW_LIVE=false
```

Optional Google Places attempt (no billing in this build; OpenStreetMap is the path that works):

```bash
flutter run -d android --dart-define=GOOGLE_PLACES_API_KEY=...
```

Never commit API keys. iOS Simulator steps are in [`docs/engineering/ios-simulator.md`](docs/engineering/ios-simulator.md).

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

### One-command pre-CAB smoke

[`scripts/smoke.sh`](scripts/smoke.sh) runs the same gates as CI and builds the release APK:

```bash
scripts/smoke.sh                 # format + analyze + test + release APK + checklist
scripts/smoke.sh --skip-build    # gates only
scripts/smoke.sh --skip-format   # ignore local/CI formatter version drift
scripts/smoke.sh --ios           # also build the iOS Simulator app
```

It prints the APK path, size, and sha256, then the short phone checklist. The full walkthrough is [`docs/engineering/cab-demo-smoke.md`](docs/engineering/cab-demo-smoke.md).

`HELP_NOW_LIVE` defaults to **true**. Pass `HELP_NOW_LIVE=false` only for a build whose taps must not open the dialer.

### Release APK

```bash
flutter build apk --release
```

Version is `1.0.1` (`pubspec.yaml` `1.0.1+2`). A local release is signed with an upload key that is not in this repo. GitHub Actions stays on the runner debug key and uploads `cwc-demo-apk-live-nearby-<sha>` (kept 30 days). That artifact is not the file to hand someone: it expires, it needs a GitHub login, and it will not upgrade an upload-key install. Uninstall first if you must try it.

The older [`study-build-2026-10`](https://github.com/ks1686/rutgers-health-services-app/releases/tag/study-build-2026-10) pre-release does not dial Help Now. Do not use it as v1.

Do not publish a new GitHub release until Karim says so.

## What’s in this build

| Tab / screen | What ships |
|--------------|------------|
| Nearby | Live OSM pharmacies, clinics, and urgent care. Unvetted disclaimer. Opt-in map (Google when `GOOGLE_MAPS_API_KEY` is set, otherwise OSM tiles). Category chips filter the list and the pins. Open now / Closed. Remembered North/Central/South town. Optional one-shot location sorts nearest-first |
| My Health | Starts empty. On-device appointments, medicines, and providers (Keystore/Keychain). Optional PIN, with an optional fingerprint unlock after the PIN is set. Check with your doctor first. Wallet card, including an optional service or support animal line. Erase from More |
| Learn | Six offline topics from `assets/content/learn.json`. Most topics have two notes. Stress Management also has two WRAP notes. Each note has a source and a link. No Medications or Exercise tile. Tile line is **From: CWC Health App team**. Notes cite MedlinePlus, NIMH, USDA, NHLBI, or Wellness Recovery Action Plan |
| More | How to Use (steps and captions; no video file), Ask a Peer, Wellness goals, Helper Mode, About, Using this app (agreement), Notifications, Settings, How This App Protects You, Erase. Session questions stay hidden unless `SHOW_SESSION_QUESTIONS` is true |
| Help Now | 911 first, then 988 (call and text), Poison Control, ReachNJ, Clearinghouse. Each opens `tel:` or `sms:` and the member places the call. NJ Peer Warmline and My Wellness Center stay hidden until CSPNJ confirms the numbers |

## Project docs

- [`AGENTS.md`](AGENTS.md): agent handoff
- [`CWC_Health_App/`](CWC_Health_App/): requirements + design reference
- [`docs/engineering/nearby-live-data.md`](docs/engineering/nearby-live-data.md): **Nearby live-data** collaborator handoff
- [`docs/superpowers/plans/2026-09-03-my-health.md`](docs/superpowers/plans/2026-09-03-my-health.md): My Health interactive plan
- [`docs/engineering/starting-release.md`](docs/engineering/starting-release.md): what the October 2026 build includes
- [`docs/engineering/learn-content.md`](docs/engineering/learn-content.md): Learn JSON + CAB update path
- Figma: https://www.figma.com/design/yAwsNNegakKROue3o0CAMJ

### Nearby live data

Nearby has no sample list and no on/off flag. A failed lookup says the list is unavailable.

```bash
flutter run -d android
```

| Flag | Default | Effect |
|------|---------|--------|
| `HELP_NOW_LIVE` | `true` | `false` keeps the Help Now rows from opening the dialer. Warmline and wellness-center rows stay hidden either way |
| `HELP_NOW_UNCONFIRMED` | `false` | `true` shows NJ Peer Warmline and My Wellness Center. Those rows have no number and do not dial |
| `GOOGLE_PLACES_API_KEY` | empty | Optional. Empty, unauthorized, or unbilled keys soft-fail to OpenStreetMap. Never commit keys |
| `GOOGLE_MAPS_API_KEY` | empty | Optional map. Empty uses the CARTO/OpenStreetMap picture. Non-empty on Android/iOS uses Google Maps |
| `CARTO_BASEMAP_API_KEY` | empty | Picture for that OpenStreetMap-style map. Empty shows CARTO's "API key required" tiles. Never commit the key |
| `SHOW_SESSION_QUESTIONS` | `false` | `true` shows the Session questions tile in More. Saved answers stay on the phone either way |

**Never commit API keys.** Pass them per native build with `--dart-define` only if needed. Empty key is the correct v1 default.

#### How live mode behaves

The live tab looks up the **remembered town** (North, Central, or South, then a town; default New Brunswick). That choice is stored on the phone. **Use my location** is an optional one-shot shortcut (`geolocator`, `LocationAccuracy.low`) on Android and iOS: no background updates, no fine/GPS permission on Android (`ACCESS_COARSE_LOCATION` only), iOS uses while-using with plain-language copy. Coordinates live in memory for that single search: Overpass runs an `around:` circle from the device point, the NJ-only guardrail is skipped (usable anywhere), results are **sorted nearest-first**, and **nothing is written to the cache**. An origin never touches storage. Each card gains a "~N min walk" badge (~80 m/min, straight-line). If the member declines, location services are off, or the fix times out, the tab falls back to the remembered town with a plain-language reason line and a *Use my location* retry. It never shows the town list as if it were device-based.

**Overhead map (FIND-4).** *See these on a map* loads tiles only when toggled on. Pins match the **category-filtered** list (same chips). Google Maps is used when `GOOGLE_MAPS_API_KEY` is set on a native build; otherwise OSM/Carto tiles via `flutter_map` (v1 default on Android). Panning does not refetch places. Tap a pin to highlight the matching card.

Overpass rate limits per IP and a room of phones on shared Wi-Fi counts as one IP, so the app tries three mirrors in order with a short retry. If you add a mirror, first confirm it serves planet-wide data. Regional instances answer HTTP 200 with zero results, which would tell a member there is no pharmacy near them. See `kOverpassEndpoints`.

#### Platform notes

Live mode needs the `INTERNET` permission and Android 11+ package-visibility `<queries>` entries for the Call, Text, and Directions buttons; both are declared in `android/app/src/main/AndroidManifest.xml`. Directions use `geo:` on Android/iOS, not Google Maps. **macOS is not a supported target.** `macos/Runner/Release.entitlements` lacks `com.apple.security.network.client`, so live requests would fail there until someone adds it and tests on a Mac.

## Feedback questions this app can record

A research build can show More, then **Session questions**, with `--dart-define=SHOW_SESSION_QUESTIONS=true`. That tile is hidden in the v1 app. The screen and any saved answers stay on the device. Erase my information deletes them. They are not uploaded.

- Can you find Nearby vs My Health?
- Is Help Now always one tap away?
- Does More feel like a visible list (not a hidden menu)?
- Does scarlet branding feel supportive or alarming?

Nothing here is a clinical recommendation. Wording still waits on the community where the spec says so.

## Known gaps: free APIs to migrate

Nearby search, town lookup, and the default map use free OpenStreetMap services (Overpass, Nominatim, OSM tiles). A later release can move those to Google Places and Google Maps. The Google flags above already soft-fail to OpenStreetMap. Do not migrate them as part of v1.

Also still open, and not placeholders to invent:

- NJ Peer Warmline and the member's wellness center phone numbers, until CSPNJ confirms them.
- TestFlight. That needs a paid Apple Developer Program account.
- App icon artwork is still the Flutter template set.
