# Learn content (bundled JSON)

**Issue:** #32  
**Asset:** `assets/content/learn.json`  
**Loader:** `loadLearnTopics()` in `lib/data/content_catalog.dart`  
**UI:** `LearnScreen` reads the asset at runtime (offline-first). The screen opens with “This does not replace seeing a doctor.”

## Shape

Each entry is an object:

| Field | Meaning |
|-------|---------|
| `title` | Area name on the grid card |
| `iconLabel` | Icon key (`body`, `mind`, `food`, `move`, `meds`, `shield`, `sleep`, `stress`, …) |
| `summary` | One-line card / article lead |
| `body` | Plain-language overview (~6th-grade). May be a short shelf intro. |
| `source` | Attribution label shown when non-empty (e.g. `CDC`). A shelf can leave this empty when each article has its own source. |
| `articlesHeading` | Optional section title for nested articles |
| `articles` | Optional list of short articles (`title`, `summary`, `body`, `source`, optional `linkLabel` + `linkUrl`) |
| `linkLabel` / `linkUrl` | Optional https link-out. `http` is rejected. |

No network fetch to load Learn. A link-out opens only when someone taps it. Hosted JSON can replace the loader later without changing the screen API.

## Placement (issues #29 and #30)

Written down before this ships, from the current issue bodies (September 18, 2026 session):

- **Sleep is its own Learn area.** George, Serena, and Ken said sleep should stand alone. It is a top-level card, not nested under Physical Health. Starter articles: everyday sleep tips (a cooler, darker room) and sleep apnea.
- **Stress management does not stand alone.** George named it, and Matt nodded. The room did not vote for stress to be its own area. The direct vote was about sleep. Stress stays inside Physical Health, under the heading "Stress management". It is reading only. It is not goal tracking (optional nudges are #33).

## Links that were checked

Articles are short stable notes, plus one link someone else keeps up to date. Outside text was not copied in.

Checked on September 24, 2026 (HTTP 200):

| Used in the app | Page |
| --- | --- |
| Everyday sleep tips | [MedlinePlus: Changing your sleep habits](https://medlineplus.gov/ency/patientinstructions/000757.htm) |
| Sleep apnea | [NHLBI: Sleep Apnea](https://www.nhlbi.nih.gov/health/sleep-apnea) |
| Stress articles | [MedlinePlus: Stress](https://medlineplus.gov/stress.html) |

Also checked and not linked, so the study app does not send people into a clinic appointment flow: Cleveland Clinic sleep apnea and stress pages (both HTTP 200). CDC and Mayo returned 403 or 404 to this check, so they are not linked.

## CAB / content update path

1. Draft or revise copy offline (plain language; name the source).
2. CAB (or designated reviewer) approves the article text and source label.
3. Edit `assets/content/learn.json` only — do not hard-code topics in Dart.
4. Open a PR that touches the JSON (and tests if topic count/titles change).
5. After merge, rebuild the app; Learn picks up the new bundle automatically.

Do **not** invent clinical advice, and do not paste text from an outside site. An https `linkUrl` is allowed only after the page is checked. Further links still need that check before they go in the JSON.

## Related issues

- #29 Sleep category  
- #30 Stress management category  
- #31 More / tab disclaimers  
