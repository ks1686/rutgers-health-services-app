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

Written down before this ships, from the current issue bodies (September 18, 2026 session) and a later Karim/Sasan study-build decision:

- **Sleep is its own Learn area.** George, Serena, and Ken said sleep should stand alone. It is a top-level card, not nested under Physical Health. Starter articles: everyday sleep tips (a cooler, darker room) and sleep apnea.
- **Stress Management is its own Learn area.** The study build uses a selectable top-level tile (Karim/Sasan). The two stress articles live on that tile, not under Physical Health. It is reading only. It is not goal tracking (optional nudges are #33).
- **Medications is not a Learn area.** Personal lists and reminders stay in My Health. Learn has no "Medications" tile, so the tab does not look like the place to manage meds. Physical Health includes a short pointer to My Health for a medicines list. Spec LRN-1 still names medications as a survey information need; that is not a Learn card. The More how-to "Add a medication" still opens My Health.
- **Exercise is not a Learn area.** Karim/Sasan dropped the Exercise tile for the study-build grid (paper Fig.1(c)). Spec LRN-1 still names exercise/fitness as a survey information need; Physical Health still mentions movement. There is no Exercise card.

## Links that were checked

Articles are short stable notes, plus one link someone else keeps up to date. Outside text was not copied in.

Checked on September 24, 2026 (HTTP 200):

| Used in the app | Page |
| --- | --- |
| Everyday sleep tips | [MedlinePlus: Changing your sleep habits](https://medlineplus.gov/ency/patientinstructions/000757.htm) |
| Sleep apnea | [NHLBI: Sleep Apnea](https://www.nhlbi.nih.gov/health/sleep-apnea) |
| Stress articles | [MedlinePlus: Stress](https://medlineplus.gov/stress.html) |

Also checked and not linked, so the study app does not send people into a clinic appointment flow: Cleveland Clinic sleep apnea and stress pages (both HTTP 200). CDC and Mayo returned 403 or 404 to this check, so they are not linked.

## Study-build filler (2026-10-06)

Physical Health, Mental Health, Nutrition, and Preventive Care each have two short notes for the Oct 14 CAB demo. Sleep and Stress were already filled. Copy is original plain language. Nothing was pasted from the linked pages. These notes are study-build filler, not a CAB-final text. [TEAM 2026-10-05] said CDC, Mayo, or Cleveland filler was acceptable. This pass links only pages that returned HTTP 200 on 2026-10-06. CDC still returned 403, so it is not linked. Mayo was not linked. Cleveland Clinic stress returned 200 on GET and was not linked, for the same clinic-flow reason as September 24.

Checked on October 6, 2026:

| Used in the app | Result | Page |
| --- | --- | --- |
| A checkup when you feel okay | 200 | [MedlinePlus: Health Checkup](https://medlineplus.gov/healthcheckup.html) |
| Moving a little each day | 200 | [MedlinePlus: Exercise and Physical Fitness](https://medlineplus.gov/exerciseandphysicalfitness.html) |
| Small ways to care for your mood | 200 | [NIMH: Caring for Your Mental Health](https://www.nimh.nih.gov/health/topics/caring-for-your-mental-health) |
| When to ask for more help | 200 | [MedlinePlus: Mental Health](https://medlineplus.gov/mentalhealth.html) |
| Eating when you can | 200 | [MedlinePlus: Nutrition](https://medlineplus.gov/nutrition.html) |
| A simple way to fill a plate | 200 | [USDA MyPlate](https://www.myplate.gov/) |
| Checks before you feel sick | 200 | [MedlinePlus: Health Screening](https://medlineplus.gov/healthscreening.html) |
| Shots that protect you | 200 | [MedlinePlus: Vaccines](https://medlineplus.gov/vaccines.html) |

Not linked: `https://www.cdc.gov/vaccines/index.html` (403). `https://medlineplus.gov/healthyeating.html` (404). Parent tiles still show the older source labels (CDC, SAMHSA, USDA). Each new note has its own source.

## Starting-release notes (2026-10-07)

The same twelve notes were rewritten in original plain language for the first study build. Nothing was pasted from the linked pages. Titles and the six-tile layout stayed the same. MyPlate (`https://www.myplate.gov/`) returned HTTP 403 on this check, so “A simple way to fill a plate” now links Nutrition.gov instead. The other links below returned HTTP 200 on 2026-10-07. These notes are still not a CAB-final text. [TEAM]

| Note | Result | Page |
| --- | --- | --- |
| A checkup when you feel okay | 200 | [MedlinePlus: Health Checkup](https://medlineplus.gov/healthcheckup.html) |
| Moving a little each day | 200 | [MedlinePlus: Exercise and Physical Fitness](https://medlineplus.gov/exerciseandphysicalfitness.html) |
| Small ways to care for your mood | 200 | [NIMH: Caring for Your Mental Health](https://www.nimh.nih.gov/health/topics/caring-for-your-mental-health) |
| When to ask for more help | 200 | [MedlinePlus: Mental Health](https://medlineplus.gov/mentalhealth.html) |
| Everyday ways to ease stress | 200 | [MedlinePlus: Stress](https://medlineplus.gov/stress.html) |
| When stress feels like too much | 200 | [MedlinePlus: Stress](https://medlineplus.gov/stress.html) |
| Eating when you can | 200 | [MedlinePlus: Nutrition](https://medlineplus.gov/nutrition.html) |
| A simple way to fill a plate | 200 | [Nutrition.gov: Healthy Eating](https://www.nutrition.gov/topics/basic-nutrition/healthy-eating) |
| Checks before you feel sick | 200 | [MedlinePlus: Health Screening](https://medlineplus.gov/healthscreening.html) |
| Shots that protect you | 200 | [MedlinePlus: Vaccines](https://medlineplus.gov/vaccines.html) |
| Everyday sleep tips | 200 | [MedlinePlus: Changing your sleep habits](https://medlineplus.gov/ency/patientinstructions/000757.htm) |
| Sleep apnea | 200 | [NHLBI: Sleep Apnea](https://www.nhlbi.nih.gov/health/sleep-apnea) |

Not linked on this pass: `https://www.myplate.gov/` (403). `https://www.cdc.gov/` (403 on earlier checks). Mayo and Cleveland Clinic were not linked.

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
