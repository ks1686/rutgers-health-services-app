# Nearby map view Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Opt-in overhead map on live Nearby with Google Maps when keyed, OSM soft-fail otherwise; shared category filters; pins for the current list.

**Architecture:** `NearbyMapView` facade chooses `google_maps_flutter` or `flutter_map`; `NearbyScreen` restores the live map toggle and passes filtered resources + origin.

**Tech Stack:** Flutter, `google_maps_flutter`, `flutter_map`, `latlong2`, existing Nearby models.

## Global Constraints

- `LIVE_NEARBY` default off; real map only when live is on.
- Never commit API keys; empty `GOOGLE_MAPS_API_KEY` → OSM.
- No pan-to-refetch; no AR; list remains primary.
- WCAG: chips and cards ≥48dp; map secondary to list.

---

### Task 1: Design docs

**Files:**
- Create: `docs/superpowers/specs/2026-09-03-nearby-map-design.md`
- Create: `docs/superpowers/plans/2026-09-03-nearby-map.md`
- Modify: `docs/engineering/nearby-live-data.md`

- [x] Spec + this plan written with Google-first / OSM soft-fail locked.

### Task 2: Config + deps + platform hooks

**Files:**
- Modify: `pubspec.yaml`, `nearby_config.dart`, Android manifest/gradle, iOS AppDelegate/Info.plist
- Test: `nearby_config_test.dart`

- [x] Add `googleMapsApiKey` from `GOOGLE_MAPS_API_KEY`
- [x] Add packages; Android meta-data placeholder; iOS GMS key when non-empty

### Task 3: NearbyMapView

**Files:**
- Create: `lib/features/nearby/widgets/nearby_map_view.dart`
- Test: `test/features/nearby/nearby_map_view_test.dart`

- [x] Facade: Google when key + !web; else OSM tiles + attribution
- [x] Markers from resources; optional origin; onMarkerTap(id)

### Task 4: Screen wiring

**Files:**
- Modify: `nearby_screen.dart`, `nearby_errors.dart`
- Test: `nearby_screen_test.dart`

- [x] Live toggle shows map; shared chips filter list + pins; pin tap selects card

### Task 5: Docs + verify

- [x] README flags; engineering handoff; AGENTS next-line; `flutter test` Nearby
