# Engineering docs

Shared, committed plans and handoffs for humans and agents.

| Path | Purpose |
|------|---------|
| [`nearby-live-data.md`](nearby-live-data.md) | Nearby live-data collaborator handoff (**implemented**; local demo is live-on Android) |
| [`learn-content.md`](learn-content.md) | Learn bundled JSON + CAB content update path (#32) |
| [`../superpowers/specs/`](../superpowers/specs/) | Design specs |
| [`../superpowers/plans/`](../superpowers/plans/) | Task-by-task implementation plans |

## CI expectations

Every PR to `main` runs [`.github/workflows/flutter-ci.yml`](../../.github/workflows/flutter-ci.yml) with **three parallel jobs**:

| Job | What it proves |
|-----|----------------|
| **Format, analyze, unit + widget tests** | Style, static analysis, unit/widget tests |
| **Integration navigation smoke** | `integration_test/` tab circuit + Help Now |
| **Compile Android APK** | `flutter build apk --debug` then unsigned `flutter build apk --release` |

Flutter **web is not a ship or CI target** (folder removed; study build is Android + iOS).

### Local equivalents

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --reporter expanded
flutter test integration_test -d flutter-tester
flutter build apk --debug     # needs Android SDK
flutter build apk --release   # unsigned; needs Android SDK
```

Flutter pin: **3.44.7** (stable).

### Not in CI yet (follow-on)

- iOS `flutter build ios --no-codesign` (needs macOS runner)
- Device/emulator `flutter drive` on Android
- Screenshot / golden tests

Nearby live-data Tasks 1–6, device-location proximity, and FIND-4 overhead map are on this branch. My Health interactive + encrypted store: [`../superpowers/plans/2026-09-03-my-health.md`](../superpowers/plans/2026-09-03-my-health.md). See [`nearby-live-data.md`](nearby-live-data.md).
