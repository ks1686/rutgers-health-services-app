# Engineering docs

Shared, committed plans and handoffs for humans and agents.

| Path | Purpose |
|------|---------|
| [`nearby-live-data.md`](nearby-live-data.md) | Nearby live-data collaborator handoff |
| [`../superpowers/specs/`](../superpowers/specs/) | Design specs |
| [`../superpowers/plans/`](../superpowers/plans/) | Task-by-task implementation plans |

## CI expectations

Every PR to `main` runs [`.github/workflows/flutter-ci.yml`](../../.github/workflows/flutter-ci.yml) with **four parallel jobs**:

| Job | What it proves |
|-----|----------------|
| **Format, analyze, unit + widget tests** | Style, static analysis, Nearby unit tests, full-app widget navigation/rendering |
| **Integration navigation smoke** | `integration_test/` tab circuit + Help Now |
| **Compile web** | `flutter build web --release` (JS compile succeeds) |
| **Compile Android APK** | `flutter build apk --debug` (Android toolchain + Dart AOT/debug compile) |

### Local equivalents

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --reporter expanded
flutter test integration_test -d flutter-tester
flutter build web --release
flutter build apk --debug   # needs Android SDK
```

Flutter pin: **3.44.7** (stable).

### Not in CI yet (follow-on)

- iOS `flutter build ios --no-codesign` (needs macOS runner)
- Device/emulator `flutter drive` on Chrome/Android
- Screenshot / golden tests
