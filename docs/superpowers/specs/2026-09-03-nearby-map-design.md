# Nearby map view — design (2026-09-03)

**Status:** Implementing on `nearby-proximity`. Spec FIND-4 (optional OSM map) plus study preference for Google Maps when a key works.  
**Handoff:** [`../../engineering/nearby-live-data.md`](../../engineering/nearby-live-data.md)

## Problem

Live Nearby is list-first with walk-time badges and optional device location. Members who want spatial context still see a placeholder (“OpenStreetMap would load here”). FIND-4 calls for an optional free/open map; the product ask is a **simple overhead map** (like opening Google Maps), not AR and not pan-to-search.

## Goals

- Opt-in “See these on a map” on the **live** tab only.
- Overhead map centered on device origin or town/results; pins for **current list** places.
- **Same category chips** (`All` / `Pharmacy` / `Clinic` / `Urgent care`) filter list cards and map pins together.
- **Google Maps first** when `GOOGLE_MAPS_API_KEY` is present and the native SDK can run; **OSM (`flutter_map`) soft-fail** otherwise (empty key = study default).
- Tiles/SDK load only after the toggle is on; list remains usable offline.
- Tap pin → focus the matching list card (actions stay on the card).

## Non-goals

- Pan-to-refetch / “search this area.”
- AR, clustering, in-app turn-by-turn, favorites, curated CWC overlay.
- Demo-mode real map (`LIVE_NEARBY=false` keeps the placeholder).
- Committing API keys or in-repo Google Cloud billing setup.

## Architecture

```text
NearbyScreen (live)
  ├─ category chips (shared) ──► filtered resources
  ├─ map toggle
  │     └─ NearbyMapView
  │           ├─ google_maps_flutter  (key on native)
  │           └─ flutter_map OSM      (soft-fail / empty key; study default)
  └─ place cards (same filtered list)
```

Pins are a view over the in-memory `NearbyFetchResult.resources` — no new Overpass call when the camera moves.

## Privacy

- Map does not request or track GPS by itself. Device origin comes from the existing one-shot Nearby location path and stays transient ([PRIV-2](../../../CWC_Health_App/01_CWC_Health_App_Feature_Specification_v0.4.md)).
- No identity in tile requests beyond a research User-Agent / package name.

## Keys

| Define | Default | Role |
|--------|---------|------|
| `GOOGLE_MAPS_API_KEY` | empty | Dart chooses Google vs OSM; native Android/iOS must receive the same key for the SDK |
| `GOOGLE_PLACES_API_KEY` | empty | Unchanged (Places HTTP soft-fail) |

Never commit keys. Empty key is the study default (OSM on Android).

## Failure policy

| Condition | Behavior |
|-----------|----------|
| Empty Maps key | OSM `flutter_map` (study default on Android) |
| Google SDK init / blank failure | Soft-fail to OSM when detectable; otherwise OSM path preferred for study demos |
| Offline tiles | List still works; map shows plain “Map needs a connection right now.” |

## Evidence

[FIND-4][TEAM][TECH-3][TECH-6][PRIV-2] — study stack preference Google-first with OSM backup matches Places soft-fail pattern [TEAM].
