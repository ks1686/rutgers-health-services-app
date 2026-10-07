# Starting study build (October 2026)

This is the first installable study build on `main`. It is the Android demo for co-design and usability prep. It is not a store release, and the Learn wording is not a CAB sign-off.

Checked build: `ff05525` in [Actions run 37690420910](https://github.com/ks1686/rutgers-health-services-app/actions/runs/37690420910). Later green `main` runs replace that file. The artifact name is `cwc-demo-apk-live-nearby-<sha>`.

## Install

The shared file is the demo release APK:

- `LIVE_NEARBY=true`
- `HELP_NOW_LIVE=false`

Uninstall any older copy first. Each Actions runner signs with a new debug key. Download needs access to this private repo. The flag-off release APK is compiled and is not uploaded. Smoke steps: [`cab-demo-smoke.md`](cab-demo-smoke.md).

## What this build includes

| Area | In the build |
|------|----------------|
| Shell | Nearby, My Health, Learn, More. My Health is the landing tab. First launch asks for the care disclaimer once. Help Now stays in the header. |
| Nearby | Live OpenStreetMap places on the demo APK, with the unvetted disclaimer, walk time, town memory, optional one-shot coarse location, and an opt-in map. |
| My Health | Appointments, medicines, providers, papers, reminders, wallet card, optional PIN, erase. Data stays on the phone. |
| Learn | Six tiles. Two original notes each. Each note links a public page that returned HTTP 200 on 2026-10-07. See [`learn-content.md`](learn-content.md). |
| More | How to Use (steps and captions; no video file), Ask a Peer, Session questions, Wellness goals, Helper Mode, About, Notifications, Settings, How This App Protects You, Erase. |
| Help Now | 911 first, then 988, Poison Control, ReachNJ, and the Clearinghouse. On the shared APK those buttons are demo-only and do not dial. The peer warmline and “My Wellness Center” rows stay samples until CSPNJ confirms the numbers. |

Session question answers stay on the phone. Erase deletes them. They are not uploaded.

## Decisions recorded here

These close the GitHub tracker. They do not change the feature spec’s version.

**Nearby (#41).** The study build ships live OSM behind `LIVE_NEARBY`. The flag-off list stays the offline sample and is not the file we hand out. There is no curated CWC overlay. Spec FIND-1 is not rewritten. A curated NJ directory would be a new issue.

**Multilingual (#34).** Spanish and other languages stay out of this award. This build is English only. No half-translated strings.

**Usability testing (#36).** The engineering pack is the demo APK plus [`cab-demo-smoke.md`](cab-demo-smoke.md). Sessions with members and peer support specialists are research work, not an open code issue.

**Non-goals (#42).** Do not build food or product recall alerts. Do not build automatic medication-interaction checks. Both need ongoing data and clinical judgment this app does not have.

**Tracker (#22, #43).** Priority 1 children #16–#21 and #23–#25 are merged. The P2 issues and the closed P3 code issues are merged. Nothing in that list is still an open engineering task.

**Dependency pull requests.** Do not merge them on the current CI pin.

- `google_maps_flutter` 2.18.2 needs Dart `^3.13`. CI is Flutter 3.44.7 (Dart 3.12). The pin stays `^2.18.1`.
- `geolocator` 14.1.1 is not merged. That release declares a foreground location service. This app uses one-shot coarse location only. The pin stays `^14.0.3`.

## Still outside this build

- A CSPNJ-confirmed warmline number and a member’s real CWC number.
- A signed iPhone build. `flutter build ios --no-codesign` can succeed outside iCloud Drive. CI does not build iOS. TestFlight needs a signing owner.
- How-to video files. Steps and captions are in the app.
- CAB approval of the Learn note text.
- A physical-phone pass of Call, Text, and Directions. An emulator pass opened the dialer, Messages, and Maps and did not place a call or send a text.
