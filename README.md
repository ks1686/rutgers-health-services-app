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

## What’s in this build

| Tab / screen | Demo behavior |
|--------------|---------------|
| Nearby | New Brunswick sample resources; category chips; map toggle placeholder |
| My Health | Sample appointments / meds / providers; wallet card screen |
| Learn | Six topics → short articles with source labels |
| More | List to placeholder pages; Erase → “Demo only” snackbar |
| Help Now | Full-screen support actions (demo only); emergency-card toggle UI |

## Project docs

- [`AGENTS.md`](AGENTS.md) — agent handoff
- [`CWC_Health_App/`](CWC_Health_App/) — requirements + design reference
- [`docs/engineering/nearby-live-data.md`](docs/engineering/nearby-live-data.md) — **Nearby live-data** collaborator handoff (plan ready; not implemented yet)
- [`docs/superpowers/plans/2026-08-11-nearby-live-data.md`](docs/superpowers/plans/2026-08-11-nearby-live-data.md) — task-by-task implementation plan
- Figma: https://www.figma.com/design/yAwsNNegakKROue3o0CAMJ

### Nearby live data (planned)

Default builds stay on static demo data. When implementation lands, live mode will use:

```bash
flutter run --dart-define=LIVE_NEARBY=true
# Optional Google Places attempt (study build does not enable billing; OSM is the supported path):
# flutter run --dart-define=LIVE_NEARBY=true --dart-define=GOOGLE_PLACES_API_KEY=...
```

Never commit API keys.

## Feedback questions this prototype supports

- Can you find Nearby vs My Health?
- Is Help Now always one tap away?
- Does More feel like a visible list (not a hidden menu)?
- Does scarlet branding feel supportive or alarming?

Draft for co-design — nothing is final until the community says so.
