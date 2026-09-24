# Learn content (bundled JSON)

**Issue:** #32  
**Asset:** `assets/content/learn.json`  
**Loader:** `loadLearnTopics()` in `lib/data/content_catalog.dart`  
**UI:** `LearnScreen` reads the asset at runtime (offline-first).

## Shape

Each entry is an object:

| Field | Meaning |
|-------|---------|
| `title` | Topic name on the grid card |
| `iconLabel` | Icon key (`body`, `mind`, `food`, `move`, `meds`, `shield`, `sleep`, `stress`, …) |
| `summary` | One-line card / article lead |
| `body` | Plain-language article (~6th-grade) |
| `source` | Attribution label shown on the article (e.g. `CDC`) |

No network fetch in the study build. Hosted JSON can replace the loader later without changing the screen API.

## CAB / content update path

1. Draft or revise copy offline (plain language; name the source).
2. CAB (or designated reviewer) approves the article text and source label.
3. Edit `assets/content/learn.json` only — do not hard-code topics in Dart.
4. Open a PR that touches the JSON (and tests if topic count/titles change).
5. After merge, rebuild the app; Learn picks up the new bundle automatically.

Do **not** invent clinical advice. External “read more” links (Mayo, Hopkins, Cleveland Clinic, CDC, etc.) stay out until CAB vets them; then add an optional field in a later revision.

## Related issues

- #29 Sleep category  
- #30 Stress management category  
- #31 More / tab disclaimers  
