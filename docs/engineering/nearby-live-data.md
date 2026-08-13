# Nearby live data — collaborator handoff

**Status:** Implementation in progress (Tasks 1–3 on branch / merged as noted).  
**Task 1 (models/config/deps):** **Complete** (ks1686)  
**Task 2 (Nominatim + Overpass):** **Complete** (ks1686) — fixture-backed unit tests; NJ guard.  
**Task 3 (Google Places soft-fail):** **Complete** (kholaif) — empty key / 403 / billing-style soft-fail; Maps Places API (New) happy path.  
**Task 4 (repository + cache):** **Complete** (kholaif) on `feat/nearby-live-task4-kholaif`, stacked on the Task 3 PR. In-memory cache only — see caveat below.  
**Task 5 (NearbyScreen wiring + disclaimer):** **Complete** (kholaif) on `feat/nearby-live-task5-kholaif`. Verified against real OSM — see live-run findings below.  
**Next open:** Task 6 (cross-platform verify + README flags) — unclaimed.  
**Meeting context:** 2026-08-11 project call — Nearby / “locator” is the near-term engineering focus; static demo stays for pre-usability show-and-tell (`LIVE_NEARBY` still default off).

## Read these in order

| # | Doc | Why |
|---|-----|-----|
| 1 | This file | Locked decisions + how to run later |
| 2 | [`../superpowers/specs/2026-08-11-nearby-live-data-design.md`](../superpowers/specs/2026-08-11-nearby-live-data-design.md) | Design / architecture |
| 3 | [`../superpowers/plans/2026-08-11-nearby-live-data.md`](../superpowers/plans/2026-08-11-nearby-live-data.md) | Task-by-task implementation plan for humans/agents |
| 4 | [`../../CWC_Health_App/01_CWC_Health_App_Feature_Specification_v0.4.md`](../../CWC_Health_App/01_CWC_Health_App_Feature_Specification_v0.4.md) | FIND-* / TECH-* (note tension below) |
| 5 | [`../../AGENTS.md`](../../AGENTS.md) | Project + agent ground rules |

## Locked decisions (do not reopen without Karim)

1. **Demo default stays static.** `liveNearby` defaults **off**. Meeting demos use today’s New Brunswick fake list.
2. **Live path:** Google Places HTTP (optional) → **soft-fail** → **OSM Overpass** (supported path).
3. **No Google Cloud billing** for the study build. Empty / denied key is expected; OSM must work alone.
4. **No curated CWC overlay** in this spike (no bundled wellness/CWC merge JSON).
5. **Cross-platform:** one pure-Dart HTTP path for **iOS and Android** (no Apple MapKit-only search).
6. **Out of scope here:** map tiles UI, favorites, GPS permission flow, Learn/training changes.

## Spec tension (intentional spike)

Spec **FIND-1** (curated directory) and **TECH-6** (no commercial map API costs) remain authoritative for the funded MVP narrative. This workstream is a **live-locator spike** from the 2026-08-11 action item. Do **not** silently rewrite FIND-1. If live OSM becomes the product direction, bump the feature spec in a separate PR with research-team buy-in.

## Flags (planned; not in app yet)

```bash
# Default demo (meetings / pre-usability)
flutter run -d chrome

# Live mode once implemented (OSM expected; Google skipped without key)
flutter run -d chrome --dart-define=LIVE_NEARBY=true

# Optional Google attempt only if someone later enables a key + billing (not study default)
flutter run --dart-define=LIVE_NEARBY=true --dart-define=GOOGLE_PLACES_API_KEY=...
```

Never commit API keys. Never add billing setup scripts to this repo for the study build.

## Progress

| Task | Status | Owner |
|------|--------|-------|
| 1 Models, config, deps | **Done** | ks1686 |
| 2 Nominatim + Overpass | **Done** | ks1686 |
| 3 Google Places soft-fail | **Done** | kholaif |
| 4 Repository + cache | **Done** (in-memory cache) | kholaif |
| 5 NearbyScreen wiring | **Done** | kholaif |
| 6 Cross-platform verify + README flags | Not started | — |
| 7 Collaborator close-out | Not started | — |

## Split work (active)

| Person / agent | Assignment |
|----------------|------------|
| ks1686 | Tasks 1–2 complete. Task 6 (cross-platform verify + README flags) is the next free slot. |
| **kholaif** | Tasks 3–5 complete (PRs #3, #4, #5). Not claiming Task 6 yet. |

## Live-run findings (2026-08-12, kholaif)

Ran the assembled repository against the real Nominatim + Overpass endpoints for New Brunswick, NJ. Four things worth the team's attention:

1. **The happy path works.** A good run returns five real places — University Pharmacy and Surgical, Zajac's Pharmacy, Eric B. Chandler Health Center, Saint Peter's Center for Ambulatory Resources, and a Walgreens. No invented rows.
2. **The public Overpass endpoint is genuinely flaky.** Across five runs it returned HTTP 504 ("server too busy") once and HTTP 429 (rate limited by IP) after roughly three calls in quick succession. The repository degrades correctly to `unavailable` with a plain-language message and a "Try again" button, so nothing crashes — but **a focus-group room full of phones on one Wi-Fi network shares one public IP and will hit that rate limit.** Mitigations to discuss before usability testing: persistent cache instead of in-memory, a retry with backoff, or a second Overpass mirror. Not fixed here; it touches Task 2 files.
3. **Most OSM rows have no phone number.** Only one of five carried `phone` / `contact:phone`, so the Call and Text buttons are hidden on most live cards (the Directions button always shows). For a population that often needs to call ahead, that's a real gap in live data versus the curated directory FIND-1 describes.
4. **The town bbox reaches past the town.** One result sat in Edison rather than New Brunswick. Still in NJ and still close, but "Nearby" currently means "in the geocoded bounding box," not "in your town."

## Task 4 decisions worth a second opinion

1. **Cache is in-memory only.** `NearbyCache` is an interface with an `InMemoryNearbyCache` implementation, so results survive tab switches but not app restarts. `shared_preferences` was listed as optional in the plan; skipped to avoid adding a plugin dependency mid-spike. Dropping in a persistent implementation needs no repository changes.
2. **Cache hits keep their original timestamp.** A cached result reports the time the data was actually fetched, not the time of the failed refresh, so the Task 5 "Updated as of …" line can't overstate freshness.
3. **Google wins only when it returns rows.** An empty `GooglePlacesOk` falls through to OSM rather than showing an empty list.
4. **A successful-but-empty OSM response is `osm`, not `cache`.** "No pharmacies or clinics found near <town>" is a real answer; stale cache would be misleading.
5. **Dedupe is name + 50 m**, which mainly collapses the duplicate node/way rows Overpass returns for one building.
| Later | UI flag wiring + disclaimer (Task 5); keep demo path untouched |

## Meeting follow-ons (not this plan)

Unvetted disclaimer + “updated as of” ship with live UI. Favorites, voice-nav training materials, Learn sustainability, and first-run walkthrough are tracked as meeting feedback — separate plans.