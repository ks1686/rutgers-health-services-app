# Nearby live data — collaborator handoff

**Status:** **Implemented (flag default off).** Tasks 1–6 complete and merged to `main`. Task 7 close-out docs synced 2026-08-14.  
**Task 1 (models/config/deps):** **Complete** (ks1686)  
**Task 2 (Nominatim + Overpass):** **Complete** (ks1686) — fixture-backed unit tests; NJ guard.  
**Task 3 (Google Places soft-fail):** **Complete** (kholaif) — empty key / 403 / billing-style soft-fail; Maps Places API (New) happy path.  
**Task 4 (repository + cache):** **Complete** (kholaif). Persistent last-success cache added in study-build hardening (2026-08-15).  
**Task 5 (NearbyScreen wiring + disclaimer):** **Complete** (kholaif). Verified against real OSM — see live-run findings below.  
**Task 6 (cross-platform verify + README flags):** **Complete** (kholaif) — two Android release blockers found and fixed; see below.  
**Task 7 (collaborator close-out):** **Docs synced 2026-08-14** (ks1686). FIND-1 not rewritten. Commit of this close-out is with the next docs PR.  
**Local demo:** **Live Nearby on Android** (`LIVE_NEARBY=true`). Flutter web is not a ship target. The flag-off static list is not used for local engineering review.  
**Meeting context:** 2026-08-11 project call — Nearby / “locator” is the near-term engineering focus. Compile-time `LIVE_NEARBY` still defaults **off** so a meeting APK cannot accidentally show live listings.

## Read these in order

| # | Doc | Why |
|---|-----|-----|
| 1 | This file | Locked decisions + how to run + as-built notes |
| 2 | [`../superpowers/specs/2026-08-11-nearby-live-data-design.md`](../superpowers/specs/2026-08-11-nearby-live-data-design.md) | Design / architecture (this spike; map was a non-goal) |
| 3 | [`../superpowers/plans/2026-08-11-nearby-live-data.md`](../superpowers/plans/2026-08-11-nearby-live-data.md) | Task-by-task implementation plan (Tasks 1–6 done) |
| 4 | [`../../CWC_Health_App/01_CWC_Health_App_Feature_Specification_v0.4.md`](../../CWC_Health_App/01_CWC_Health_App_Feature_Specification_v0.4.md) | FIND-* / TECH-* (note tension below) |
| 5 | [`../../AGENTS.md`](../../AGENTS.md) | Project + agent ground rules |

## Locked decisions (do not reopen without Karim)

1. **Compile-time default stays static.** `liveNearby` defaults **off**. A build without the flag still shows the New Brunswick fake list. **Local engineering review uses live-on** (`--dart-define=LIVE_NEARBY=true` on Android). [TEAM 2026-08-14]
2. **Live path:** Google Places HTTP (optional) → **soft-fail** → **OSM Overpass** (supported path).
3. **No Google Cloud billing** for the study build. Empty / denied key is expected; OSM must work alone.
4. **No curated CWC overlay** in this spike (no bundled wellness/CWC merge JSON).
5. **Cross-platform:** one pure-Dart HTTP path for **iOS and Android** (no Apple MapKit-only search).
6. **Out of scope for *this* spike:** map tiles UI, favorites, GPS permission flow, Learn/training changes. Map is FIND-4 and is the next engineering plan, not a silent add-on here.

## Spec tension (intentional spike)

Spec **FIND-1** (curated directory) and **TECH-6** (no commercial map API costs) remain authoritative for the funded MVP narrative. This workstream is a **live-locator spike** from the 2026-08-11 action item. Do **not** silently rewrite FIND-1. If live OSM becomes the product direction, bump the feature spec in a separate PR with research-team buy-in.

## Flags (in the app)

```bash
# Local engineering demo (Android emulator or device)
flutter run -d android --dart-define=LIVE_NEARBY=true

# Flag-off static list (compile default — meeting APKs / tests that assert demo rows)
flutter run -d android

# Optional Google attempt only if someone later enables a key + billing (not study default)
flutter run -d android --dart-define=LIVE_NEARBY=true --dart-define=GOOGLE_PLACES_API_KEY=...
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
| 6 Cross-platform verify + README flags | **Done** | kholaif |
| 7 Collaborator close-out | **Docs written 2026-08-14** | ks1686 |

## Split work

This spike is closed. FIND-4 overhead map and device-location proximity are implemented (see below). Readable hours on live cards is on `main`.

## As-built (2026-08-14, ks1686)

Verified on then-`main` with `LIVE_NEARBY=true` (historical Chrome web bundle; web is no longer a ship target). Matches kholaif's 2026-08-12 live-run: real New Brunswick-area places, unvetted disclaimer, no demo names.

| What | As built |
|------|----------|
| Disclaimer | “These places come from public maps data. They are not checked by our team.” + “Updated as of …” |
| Sample rows | University Pharmacy and Surgical (New Brunswick); Walgreens (Edison — bbox overshoot reproduced) |
| Hours | Live cards: **Open now** / **Closed** (tap to expand Mon–Sun). Unparseable or missing OSM tags: **Hours not listed**. |
| Map toggle | Opt-in FIND-4 overhead map on the live list (Google when keyed; OSM `flutter_map` study default). Demo list still has the placeholder switch. |
| GPS | Live tab asks for a one-shot coarse fix on load; sorts nearest-first; town is fallback only |
| Call / Text | Hidden when OSM has no phone; Directions always shown |
| Categories | Live chips: All / Pharmacy / Clinic / Urgent care. No CWC or Wellness rows |

## OSM category mapping caveats (Task 7)

`OsmOverpassSource._categoryFor` is deliberately narrow:

| OSM tags | Live category |
|----------|----------------|
| `amenity=pharmacy` | Pharmacy |
| `amenity=clinic` or `healthcare=clinic` | Clinic |
| `healthcare=urgent_care` only | Urgent care |
| hospital, doctors, dentist, `healthcare=yes`, CWC, wellness | **Dropped** (under-claim) |

Hours: OSM `opening_hours` is stored on `NearbyResource.openingHoursRaw` and parsed on the live card into **Open now** / **Closed** (tap to expand Mon–Sun). Unparseable or missing tags: **Hours not listed**. Google Places live rows currently always get **Hours not listed** (`openingHoursRaw: null`). Spec FIND-1 (curated directory) is unchanged.

## Live-run findings (2026-08-12, kholaif)

Ran the assembled repository against the real Nominatim + Overpass endpoints for New Brunswick, NJ. Four things worth the team's attention:

1. **The happy path works.** A good run returns five real places — University Pharmacy and Surgical, Zajac's Pharmacy, Eric B. Chandler Health Center, Saint Peter's Center for Ambulatory Resources, and a Walgreens. No invented rows.
2. **The public Overpass endpoint is genuinely flaky.** Across five runs it returned HTTP 504 ("server too busy") once and HTTP 429 (rate limited by IP) after roughly three calls in quick succession. The repository degrades correctly to `unavailable` with a plain-language message and a "Try again" button, so nothing crashes — but **a focus-group room full of phones on one Wi-Fi network shares one public IP and will hit that rate limit.** *Addressed in the follow-up below.*
3. **Most OSM rows have no phone number.** Only one of five carried `phone` / `contact:phone`, so the Call and Text buttons are hidden on most live cards (the Directions button always shows). For a population that often needs to call ahead, that's a real gap in live data versus the curated directory FIND-1 describes.
4. **The town bbox reaches past the town.** One result sat in Edison rather than New Brunswick. Still in NJ and still close, but "Nearby" currently means "in the geocoded bounding box," not "in your town."

## Overpass endpoint failover (2026-08-12, kholaif)

Follow-up to finding 2 above. `OsmOverpassSource` now takes a list of mirrors instead of one URL, retries a busy or rate-limited server once with a short backoff, then fails over to the next mirror. It gives up only when every endpoint is exhausted, and it applies a 20-second per-request timeout so one hanging mirror cannot stall the screen. Behaviour is unchanged when the primary is healthy: one request, same host as before.

**This touched ks1686's Task 2 file.** The parsing, the NJ guard, and the query builder are untouched — the change is purely about which server answers. The old `endpoint` field became `endpoints`.

**One trap worth knowing about.** I checked five candidate mirrors against a New Brunswick bounding box before choosing. `overpass.osm.ch` answered **HTTP 200 with zero elements** because it only carries Swiss data. Adding it would not have thrown an error — the app would have calmly told a member there is no pharmacy near them. `overpass.osm.jp` fails TLS verification. `maps.mail.ru` works and returns correct data, but it is operated by VK/Mail.ru, and routing health-adjacent lookups from a Rutgers study through it is not a call I should make quietly — leaving it out. The three shipped mirrors all returned the same real New Brunswick pharmacies. There is now a comment on `kOverpassEndpoints` requiring the same check before anyone adds a fourth.

**Cache:** last-success list + last geocode point persist on-device via `shared_preferences` (`PrefsNearbyCache`). No identity, no GPS, no query history. Cold start can still show the last good New Brunswick list when every Overpass mirror is down.

## Cross-platform verification (2026-08-12, kholaif — Task 6)

**Two Android release blockers were found and fixed.** Neither is visible in debug builds or in CI, which is why they survived this long:

1. **`INTERNET` permission was missing from the release manifest.** It was declared only in `android/app/src/debug/` and `android/app/src/profile/`, where the Flutter tooling puts it for hot reload. Debug builds therefore had network and release builds would not have — so the live Nearby tab would have failed completely on any APK handed to a participant, with CI staying green because it only builds `--debug`. Now declared in `android/app/src/main/AndroidManifest.xml` and confirmed present in the merged release manifest of an actual `flutter build apk --release`.
2. **Android 11+ package visibility blocked the card actions.** The manifest declared `<queries>` only for `PROCESS_TEXT`. Without entries for `https`, `tel`, and `smsto`, `url_launcher` cannot resolve the Call, Text, and Directions buttons on API 30 and above — which is essentially every current phone. Added and verified in the same merged manifest.

**Verified working:**

| Check | Result |
|---|---|
| `flutter build apk --release` | Builds; merged manifest carries `INTERNET` + all three `<queries>` intents |
| Web CORS | Nominatim and both primary Overpass mirrors return `Access-Control-Allow-Origin: *`, so web needs no proxy |
| Live data end to end | Real New Brunswick pharmacies and clinics returned from the live repository |
| Demo default | Unchanged; full suite green with the flag off |
| Category chips | Now derived from `NearbyCategory.values`, with a test asserting every source category has a chip |
| Historical web live (2026-08-14) | Real listings + disclaimer were verified on Chrome before web was dropped as a ship target. Current demo is Android. |

**Not verified — needs someone with the hardware:**

- **No physical Android device or emulator run.** The build is verified and the manifest is correct, but nobody has yet tapped Call on a real phone. This is the single most valuable thing left to check, since Android is 21 of 27 member phones.
- **No iOS run at all.** Original Task 6 host was Windows. iOS needs no extra configuration for `launchUrl`, but that is reasoning, not evidence.
- **macOS is not a supported target.** `macos/Runner/Release.entitlements` has no `com.apple.security.network.client`, so live requests would fail. Left alone deliberately rather than shipping a change that cannot be tested from Windows.

## Task 4 decisions worth a second opinion

1. **Cache is on-device last-success.** `NearbyCache` has `InMemoryNearbyCache` (tests) and `PrefsNearbyCache` (app). Payload is the last POI list + timestamp + last GeoPoint only.
2. **Cache hits keep their original timestamp.** A cached result reports the time the data was actually fetched, not the time of the failed refresh, so the Task 5 "Updated as of …" line can't overstate freshness.
3. **Google wins only when it returns rows.** An empty `GooglePlacesOk` falls through to OSM rather than showing an empty list.
4. **A successful-but-empty OSM response is `osm`, not `cache`.** "No pharmacies or clinics found near <town>" is a real answer; stale cache would be misleading.
5. **Dedupe is name + 50 m**, which mainly collapses the duplicate node/way rows Overpass returns for one building.

## Next engineering (not this spike)

Separate plans — do not fold into the closed Tasks 1–7:

1. **Readable hours on live cards** — **Done.** Weekday `off` and `24:00` now parse; bare `PH off` stays unknown.
2. **Persistent on-device cache** — **Done** in study-build hardening (`PrefsNearbyCache`).
3. **FIND-4 map view** [TEAM 2026-09-03] — **done on `nearby-proximity`.** Overhead map; Google when keyed, OSM soft-fail; shared category chips; no pan-to-refetch.
4. Physical Android Call/Text/Directions tap; iOS smoke.

## FIND-4 overhead map (2026-09-03, nearby-proximity)

Design: [`../superpowers/specs/2026-09-03-nearby-map-design.md`](../superpowers/specs/2026-09-03-nearby-map-design.md).  
Plan: [`../superpowers/plans/2026-09-03-nearby-map.md`](../superpowers/plans/2026-09-03-nearby-map.md).

**Implemented** on this branch: opt-in map on live Nearby; Google Maps when `GOOGLE_MAPS_API_KEY` works on native; OSM `flutter_map` soft-fail (study default on Android when no Maps key); pins for the current filtered list; shared category chips; no pan-to-refetch.

## Device location + proximity (2026-09-03, nearby-proximity)

Live Nearby asks for a one-shot device fix on load (Android / iOS),
sorts results nearest-first, and is not limited to New Brunswick. Town remains
the honest fallback when location is denied, off, or unavailable — never shown
as if it were device-based. Coordinates stay in memory only (never cached).

| Decision | As built |
|---|---|
| Plugin | `geolocator` ^14.0.3, one-shot `getCurrentPosition`, low accuracy, 12 s cap |
| Permissions | Android `ACCESS_COARSE_LOCATION` only (no fine/GPS); iOS `NSLocationWhenInUseUsageDescription` with plain-language copy |
| Origin | Coordinates stay in memory for one search; `NearbyFetchResult.origin` is never persisted and device results are never written to `PrefsNearbyCache` |
| Search shape | Overpass forced to an `around:` circle from the device point (`fetchAround`) — never the town bbox; NJ guardrail skipped because members travel |
| Sort | Device results ordered nearest-first (straight-line meters) |
| Distances | "~N min walk" badges computed on-device (~80 m/min straight-line), shown only when a device origin exists |
| Failure honesty | Denied / services-off / timeout all fall back to the town lookup with a plain-language reason line; "Use my location" stays available to retry |

## Meeting follow-ons (not this plan)

Favorites, voice-nav training materials, Learn sustainability, and first-run walkthrough are tracked as meeting feedback — separate plans.
