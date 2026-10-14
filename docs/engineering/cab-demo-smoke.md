# v1 phone check (before Oct 14, 2026)

Use a release APK built from current `main`, version `1.0.0`. Nearby is always live. Help Now opens a `tel:` or `sms:` link and the member places the call. There is no sample pharmacy list and no seeded health record.

The October study-build pre-release (`study-build-2026-10`) is older. It does not dial Help Now and it is not this file.

To build and print the short checklist: `scripts/smoke.sh`.

A local release APK is signed with an upload key that is not in the repo. A GitHub Actions artifact is signed with the runner debug key. Those two will not upgrade each other. Uninstall the old app first.

Pass `HELP_NOW_LIVE=false` only when a tap in the room must not open the dialer. The default is on.

## Path

Do this on a phone with a network connection. Stop if a step does not match.

1. Open the app from closed. **Before you continue** shows every time the process starts. Tap **I understand**. The app lands on **My Health**. Appointments, medicines, and providers start empty. Help Now is in the header.
2. Open **Nearby**. Confirm **They are not checked by our team.** The list is live places for the remembered town (default New Brunswick). Wait for rows. If the network fails, the screen says the list is unavailable. That is a fail for this check.
3. On one live card, tap **Call**, then back out of the dialer without placing the call. Tap **Text**, then back out. Tap **Directions**, then back out. A card with no phone shows **Phone not listed** and still has Directions.
4. Open **Learn**. Count six tiles: Physical Health, Mental Health, Stress Management, Nutrition, Preventive Care, Sleep. There is no Medications tile and no Exercise tile. Open Physical Health and one short note. The note names a source (MedlinePlus, NIMH, USDA, or NHLBI). A tile says **From: CWC Health App team**.
5. Open **Help Now** from the header. **911 Emergency** is first. The page says one tap opens the number, filled in, and the app never dials for you. Tap **911 Emergency**, confirm the dialer shows 911, and back out without calling. Do the same for **Call 988** if you want a second check. NJ Peer Warmline and My Wellness Center are not on the page until CSPNJ confirms those numbers.
6. Open **More**, then **Ask a Peer**. The peer screen is full screen and the bottom tabs are gone. Back returns to More and the tabs.
7. On **More**, open **Session questions**. Tap one Yes or No. The page says the answers stay on this phone. Back returns to More.
8. On **More**, open **How This App Protects You**. The page says personal information is not uploaded. Back returns to More.
9. On **More**, open **How to Use This App**, then **Find a pharmacy**. The steps are on the phone. The page says this build does not include a video file. Back returns to More.

## Pass

Every step above matched. Call, Text, and Directions each opened the phone's own app once. Help Now opened the dialer with the number filled in, and nobody placed the call.

## Not this check

- Placing a real 911, 988, or poison-control call.
- NJ Peer Warmline and the member's wellness center. Those numbers are not confirmed.
- iPhone cell service. The simulator steps are in `docs/engineering/ios-simulator.md`. A simulator cannot prove a call.
- TestFlight. That needs a paid Apple Developer Program account. Do not enroll for this check.

## Known gaps: free APIs to migrate

Nearby uses free OpenStreetMap services. They stay until a later move to Google. Do not migrate them in this release.

| What | Now | Later |
|------|-----|--------|
| Place search | OpenStreetMap Overpass | Google Places |
| Town lookup | Nominatim | Google Geocoding, if needed |
| Overhead map | OSM tiles (`flutter_map`) | Google Maps when a key is set |

`GOOGLE_PLACES_API_KEY` and `GOOGLE_MAPS_API_KEY` already exist. An empty key is the study default. A key that is present and not billed soft-fails to OpenStreetMap. Never commit a key.
