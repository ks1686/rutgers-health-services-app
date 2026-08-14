# Nearby live data — design (2026-08-11)

**Status (2026-08-14):** Implemented on `main`, gated by `LIVE_NEARBY` (compile default still off). Local engineering demo is Chrome with the flag **on**. Map tiles and parsed hours were non-goals of this spike; they are the next plans. Handoff: [`docs/engineering/nearby-live-data.md`](../../engineering/nearby-live-data.md).

## Problem

The Flutter app’s Nearby tab is a static New Brunswick demo. The 2026-08-11 meeting asked engineering to advance a **live locator** for pharmacies/clinics while demos continue on the current prototype. Google Places was mentioned on the call; the study build will **not** enable Google billing, so OSM must be the reliable live path.

## Goals

- Live POI list on **iOS and Android** via one Dart HTTP stack.
- Try Google Places when a key exists; **soft-fail** to OSM Overpass when key is empty, denied, or billing-blocked.
- Keep static demo as default (`LIVE_NEARBY` off).
- Show unvetted + “updated as of” disclaimer in live mode.
- Leave map-tile UI as placeholder.

## Non-goals

- Curated/bundled CWC or wellness overlay.
- Google Cloud billing, committed secrets, or Places SDK UI.
- `flutter_map` / MapKit map view.
- Favorites, GPS-first location, Learn content, training materials.

## Architecture

```text
NearbyScreen
  ├─ LIVE_NEARBY=false → demo_resources.dart (unchanged)
  └─ LIVE_NEARBY=true  → NearbyRepository
                           ├─ NominatimGeocode (town → center/bbox)
                           ├─ GooglePlacesSource (optional; soft-fail)
                           ├─ OsmOverpassSource (fallback / expected)
                           └─ optional last-success cache
```

**Source status** surfaced to UI: `google` | `osm` | `cache` | `unavailable`.

## Model (target)

`NearbyResource`: `id`, `name`, `category`, `address`, `phone?`, `lat`, `lng`, `status`, `source`, `fetchedAt`.

Categories for live v1: `Pharmacy`, `Clinic`, `Urgent care` (plus `All` filter). Do not invent CWC rows from Places/OSM.

## Failure policy

| Condition | Behavior |
|-----------|----------|
| Empty Google key | Skip Google; call OSM |
| Google 403 / REQUEST_DENIED / billing / timeout | Soft-fail → OSM |
| OSM success | Show OSM results; status `osm` |
| Google + OSM fail; cache hit | Show cache; status `cache` |
| All fail | Empty state + plain-language “Need a connection…” — **never** swap to fake demo while live mode is on |

## Privacy

- No location tracking. Live v1 uses **town name → Nominatim** only (no GPS permission).
- Do not store or transmit user identity. Cache is on-device last POI payload only.

## UI (live mode only)

- Same card chrome as demo list.
- Disclaimer: listings are not vetted by the study team; show fetch timestamp.
- Call / Text / Directions use real `tel:` / `sms:` / maps URLs when data exists.
- Demo path keeps “Demo only” snackbars.

## Cross-platform

Pure Dart `http` clients. Same code on Android and iOS. Identify Nominatim/Overpass requests with a research-appropriate User-Agent.

## Open follow-ons

- Readable hours on live cards — design: [`2026-08-14-nearby-hours-expand-design.md`](2026-08-14-nearby-hours-expand-design.md).
- FIND-4 OSM map tiles (placeholder toggle already in live UI).
- Full FIND-2 region/town picker; optional GPS shortcut.
- Persistent on-device cache; post-usability decision on curated vs live directory for FIND-1.