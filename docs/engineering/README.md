# Engineering docs

Shared, committed plans and handoffs for humans and agents.

| Path | Purpose |
|------|---------|
| [`nearby-live-data.md`](nearby-live-data.md) | Nearby live-data collaborator handoff |
| [`../superpowers/specs/`](../superpowers/specs/) | Design specs |
| [`../superpowers/plans/`](../superpowers/plans/) | Task-by-task implementation plans |

## CI expectations

Every PR to `main` runs [`.github/workflows/flutter-ci.yml`](../../.github/workflows/flutter-ci.yml):

1. `dart format --set-exit-if-changed .`
2. `flutter analyze --fatal-infos`
3. `flutter test`

Run the same commands locally before pushing. Pin matches Flutter **3.44.7** (stable used for Task 1).
