# Nearby live data — collaborator handoff

**Status:** Implementation in progress (Tasks 1–2 merged to `main`).  
**Task 1 (models/config/deps):** **Complete** (ks1686)  
**Task 2 (Nominatim + Overpass):** **Complete** (ks1686) — fixture-backed unit tests; NJ guard.  
**Next:** Task 3 (Google Places soft-fail client) — **claimed by kholaif** (in progress claim; coding not started until owner confirms).  
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
| 3 Google Places soft-fail | **Claimed** (awaiting start) | **kholaif** |
| 4 Repository + cache | Open — do not start while Task 3 is active unless coordinated | — |
| 5 NearbyScreen wiring | Not started | — |
| 6 Cross-platform verify + README flags | Not started | — |
| 7 Collaborator close-out | Not started | — |

## Split work (active)

| Person / agent | Assignment |
|----------------|------------|
| ks1686 | Tasks 1–2 complete. Pick next open task only after coordinating (avoid Task 3 while claimed). |
| **kholaif** | **Task 3 — Google Places soft-fail** (claimed). Then propose Task 4 or 5 after Task 3 is committed. |
| Later | UI flag wiring + disclaimer (Task 5); keep demo path untouched |

## Meeting follow-ons (not this plan)

Unvetted disclaimer + “updated as of” ship with live UI. Favorites, voice-nav training materials, Learn sustainability, and first-run walkthrough are tracked as meeting feedback — separate plans.