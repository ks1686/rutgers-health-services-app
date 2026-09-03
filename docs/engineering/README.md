# Engineering docs

Shared, committed plans and handoffs for humans and agents.

| Path | Purpose |
|------|---------|
| [`nearby-live-data.md`](nearby-live-data.md) | Nearby live-data collaborator handoff (**implemented**; local demo is live-on) |
| [`../superpowers/specs/`](../superpowers/specs/) | Design specs |
| [`../superpowers/plans/`](../superpowers/plans/) | Task-by-task implementation plans |

## CI expectations

Every PR to `main` runs [`.github/workflows/flutter-ci.yml`](../../.github/workflows/flutter-ci.yml) with **four parallel jobs**:

| Job | What it proves |
|-----|----------------|
| **Format, analyze, unit + widget tests** | Style, static analysis, Nearby unit tests, full-app widget navigation/rendering |
| **Integration navigation smoke** | `integration_test/` tab circuit + Help Now |
| **Compile web** | `flutter build web --release` (JS compile succeeds) |
| **Compile Android APK** | `flutter build apk --debug` then unsigned `flutter build apk --release` (toolchain + release-manifest lock) |

### Local equivalents

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --reporter expanded
flutter test integration_test -d flutter-tester
flutter build web --release
flutter build apk --debug     # needs Android SDK
flutter build apk --release   # unsigned; needs Android SDK
```

Flutter pin: **3.44.7** (stable).

### Not in CI yet (follow-on)

- iOS `flutter build ios --no-codesign` (needs macOS runner)
- Device/emulator `flutter drive` on Chrome/Android
- Screenshot / golden tests

Nearby live-data Tasks 1–6 are on `main`. Current hardening work is [`../superpowers/plans/2026-08-15-study-build-hardening.md`](../superpowers/plans/2026-08-15-study-build-hardening.md). My Health persistence / CRUD / optional PIN / Erase: [`../superpowers/plans/2026-09-03-my-health.md`](../superpowers/plans/2026-09-03-my-health.md). Next Nearby product plan: FIND-4 OSM map view. See [`nearby-live-data.md`](nearby-live-data.md).
