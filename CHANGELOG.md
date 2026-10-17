# Changelog

All notable changes to the CWC Health App are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Nearby includes hospitals as their own category, from OpenStreetMap and from Google Places when a key is set.
- Nearby has a Save button. A saved place stays on this phone and shows first in the current list. Erase my information clears saved places.
- Mental Health has a short note, "A slow breath you can try," linked to MedlinePlus.

### Changed

- "Hours not listed" and "Phone not listed" use the main text color so they are easier to read.
- The personal-paper choice "RAT plan" is spelled out as "Rapid assessment and treatment plan."
- While Helper Mode hides details, My Health does not show the Add buttons.
- After Erase my information, the Nearby list stops showing places as Saved right away.
- When Nearby finds nothing with "All" picked, it says "No places found near" the town.

### Removed

- Wellness goals is no longer on the More list. The October 14 meeting asked for it to come off.

## [1.0.1] - 2026-10-13

### Added

- My Health shows a "Check with your doctor first" card. Call my provider appears only when a provider is saved, and it opens the phone dialer with the number filled in.
- More has a draft page, "Using this app (agreement)". The wording needs Karim and CAB sign-off. The first-open disclaimer can link to it. There is no mandatory gate.
- Optional fingerprint unlock for My Health after a PIN is set. The PIN always works. The phone checks the fingerprint. This app never sees it, and it does not leave the phone.
- The emergency card can include a service or support animal line when that choice is on and the note is not empty.
- Stress Management has two WRAP notes. Facts come from the public WRAP page, checked on 2026-10-13.

### Changed

- Session questions stay in the app. The More tile is hidden unless the build sets `SHOW_SESSION_QUESTIONS`.
- Docs describe this repository as the public v1 app.

### Fixed

- Helper Mode no longer says it loads sample records.
- Help Now rows keep 48dp targets and spoken labels when text is large. Numbers, order, and dialer behavior are unchanged. The app still does not place the call.

## [1.0.0] - 2026-10-12

First installable Android build for the Oct 14 CAB review.

- Version 1.0.0 (versionCode 1). Package `org.rutgers.cwc.cwc_health_app`.
- Nearby lists real places from OpenStreetMap for the remembered town (default New Brunswick). There is no sample pharmacy list.
- Help Now opens the phone number, filled in. You place the call. The app does not dial by itself. 911 is first, then 988, Poison Control, ReachNJ, and the NJ Self-Help Group Clearinghouse.
- NJ Peer Warmline and My Wellness Center are not on the page. Those numbers are not confirmed yet.
- My Health starts empty. An optional PIN and an emergency card are included. What you add stays on the phone.
- Learn has six topics. A tile says "From: CWC Health App team." A note names MedlinePlus, NIMH, USDA, or NHLBI.
- More includes How to Use with steps and captions, reminders, and wellness goals.
- iPhone / TestFlight is not in this release.
- Nearby still uses Overpass, Nominatim, and OSM map tiles.

Signed with the upload key (certificate SHA-256 `0d5e89d03f75e5b2c730c0143fd6892dbfcfcd7d4db49dce71bc817391b6079b`). Built from `2b0f9a7`.
