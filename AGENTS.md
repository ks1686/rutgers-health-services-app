# AGENTS.md — CWC Health App

Zero-context handoff for humans and AI agents. **Source documents** (versioned, fuller detail) live in [`CWC_Health_App/`](CWC_Health_App/). Cursor rules in [`.cursor/rules/`](.cursor/rules/) enforce day-to-day constraints.

| Doc | Authority |
|-----|-----------|
| `CWC_Health_App/00_PROJECT_RUNDOWN_CWC_Health_App.md` | Project context |
| `CWC_Health_App/01_CWC_Health_App_Feature_Specification_v0.4.md` | **Behavior** (requirements) |
| `CWC_Health_App/02_CWC_Health_App_Design_Reference_v1.1.md` | **Look** (tokens + screen map) |
| [Figma](https://www.figma.com/design/yAwsNNegakKROue3o0CAMJ) (`yAwsNNegakKROue3o0CAMJ`) | Canonical visuals |

---

## 1. One-paragraph summary

Funded, IRB-approved Rutgers pilot (OVPR BHEI, ~$40K, 06/30/2025–06/29/2027): co-design a smartphone app that centralizes health information and healthcare/wellness navigation for adults with mental health, substance use, and/or co-occurring physical conditions who live in poverty—many currently or formerly unhoused. Work happens in **Community Wellness Centers (CWCs)** run by **CSPNJ** across NJ. Three aims: (1) needs assessment via focus groups, (2) co-design + student-built app, (3) usability testing + peer-led training materials. As of August 2026 (~M14): pre-surveys analyzed; spec v0.4 + Final Design v1.1 (Rutgers Scarlet) drafted; Flutter study build on `main` has four tabs + Help Now, **live Nearby** (Google soft-fail → OSM, `LIVE_NEARBY`, default off; one-shot coarse GPS + FIND-4 overhead map), and **interactive My Health** (on-device encrypted store). Local engineering demo is **Android** with live Nearby on. Flutter **web is not a ship target**.

## 2. Formal identity

- **Title:** Facilitating Access to Digital Health Information for Individuals with Multifaceted Health and Social Needs: Smartphone App Co-design in Community Wellness Centers
- **IRB:** Rutgers eIRB **Pro2025002116**
- **Home:** Rutgers Institute for Health / Center for Population Behavioral Health (PI Sartor)
- **Partner:** Collaborative Support Programs of New Jersey (CSPNJ) — CWCs + NJ peer warmline services

### Team (know the names)

| Role | People |
|------|--------|
| Corresponding PI | Dr. Carolyn Sartor |
| Co-Is | Dr. Peggy Swarbrick, Dr. Amy Spagnolo, Dr. Sasan Haghani (ECE; student builders + usability) |
| RAs | Samaa, Marley, Jada |
| CAB (decision-making co-design body) | Adam Chrone, Vincent DiGioia-Laird, Arielle Estes, Lasheema Sanders-Edwards |

CAB meets monthly; they shape recruitment, analysis, features, training, dissemination—not rubber stamps.

## 3. Users and constraints from data

**Members (n≈40 completed pre-survey):** ~38% no smartphone; among owners ~21 Android / 6 Apple; comfort bimodal; health-app use rare; ~half unhoused; high receptivity to an app. Top info needs: physical health, mental health, exercise, nutrition, medications, preventive care. Prefer help via video, PSS, step-by-step tutorials.

**PSS (n≈11):** phones + data universal; often iPhone; high comfort; role = helper/trainer.

**Design implications:** Android-first, offline-first, shared/kiosk devices, large type, no hidden nav, peer help as a first-class UI, walk/transit distances, minimal data collection, trust-first permission prompts.

## 4. Product (MVP) — behavior summary

Authoritative detail + evidence tags: feature spec v0.4. Working names subject to CAB/[PENDING FG].

**IA:** Bottom tabs **Nearby | My Health | Learn | More** (no hamburger/drawer). Persistent **Help Now** in every header. Max two taps from a tab root to a core task. **Nearby** is default landing.

| Area | MVP |
|------|-----|
| **Nearby** | Spec MVP: curated NJ directory (cached offline); region/town picker; walk-time; optional OSM map. **Study build:** live OSM pharmacies/clinics behind `LIVE_NEARBY` (Open now / Closed expands weekday hours when OSM tags parse; one-shot coarse GPS + nearest-first sort; opt-in FIND-4 overhead map) |
| **My Health** | Manual appointments, meds, providers/portal *link-outs* (no credentials), offline wallet card; optional PIN (never gates Nearby/Learn/Help Now) |
| **Learn** | Six domains; ~6th-grade; source-labeled; offline; **no AI answers** in study build |
| **Help Now** | One tap, never PIN-blocked, offline: 988 call+text, 911, Poison Control, member’s CWC, NJ peer warmline; optional emergency card (off by default) |
| **More** | Tutorials + ≤90s Wi‑Fi-downloadable videos, Ask a Peer, PSS Helper Mode (demo data), settings, plain-language privacy, one-tap erase |

**Tech:** Flutter (this repo); Android 8+ era / low-RAM test device; &lt;~40MB; offline-first; remote-config/hosted JSON for directory + Learn + Help Now numbers; WCAG 2.1 AA, ≥48dp targets, 18pt+ body + OS scaling, TalkBack/VoiceOver; open-source/low-cost stack.

**Out of scope this award:** symptom tracking / clinical assessment; diagnosis/treatment advice; EHR/portal credential storage or integration; member messaging; social feeds; gamification; AI answers; Spanish; crisis logic beyond the static Help Now set. Portal integration, Spanish, guarded AI → follow-on grant narrative.

## 5. Design tokens (Final Design v1.1 — Rutgers Scarlet)

Figma is canonical; mockup type uses Inter at 360×800 frames. Production must honor ACC-1 (18pt base + OS scaling)—mock sizes are visual approximations.

| Token | Hex | Use |
|-------|-----|-----|
| `primary` | `#CC0033` | Rutgers Scarlet — actions, active tab, Help Now, filled support buttons |
| `primary-tint` | `#FAE7EC` | Soft scarlet tint |
| `ink` | `#21262B` | Primary text |
| `sub` | `#5F6A72` | Rutgers Gray PMS 431 — secondary text |
| `line` | `#E4E1DB` | Hairlines / borders |
| `surface` | `#FCFBF9` | Warm off-white background (non-clinical) |
| `card` | `#FFFFFF` | Cards |
| `neutral-emphasis` | `#0D0D0D` | Rutgers Black — 911 + Erase (scarlet owns “red”) |

Preserve: supportive language (“Help Now” not “EMERGENCY”); color never sole meaning; scarlet as action on calm surfaces, not alarm wash. Ask CAB how scarlet *feels* (trust).

**Screens (spec IDs):** Nearby (NAV/FIND) · My Health (MYH/ONB/PRIV) · Learn (LRN) · More (HELP/PRIV) · Help Now (NOW). Sample data in mocks is fake-but-realistic (e.g. Dr. Rivera, Metformin).

## 6. Evidence tags (keep using them)

| Tag | Source |
|-----|--------|
| `[PROP]` | Funded proposal |
| `[SURV-M]` / `[SURV-P]` | Member / PSS pre-surveys |
| `[CAB]` | Advisory board |
| `[LIT]` | Literature library |
| `[TEAM]` | Team design decisions |
| `[PENDING FG]` | **Hypothesis** — confirm with focus-group synthesis + CAB; do not treat as final |

## 7. Privacy / IRB (non-negotiable)

- Survey exports and similar files may contain **names, emails, IPs, geolocation**. IRB-governed.
- Agents: **aggregates only**; never paste raw identifiable rows into external tools or commit them.
- App study build: local-first personal health data; no ads; no third-party analytics SDKs; no location tracking; GPS only transient/on-device if opted in for Nearby distances.
- Before shipping Help Now: verify NJ peer warmline number/hours with CSPNJ; CAB-approve contents.

## 8. Ground rules for agents

1. **The community decides.** Preserve `[PENDING FG]`; don’t present choices as final without CAB/FG.
2. **Protect participant data** (§7).
3. **Match project values in artifacts:** ~6th-grade plain language, offline-first, Android-first, no dark patterns, no unnecessary collection, peer support as a first-class feature.
4. **Cite evidence** when adding requirements or claims.
5. **Version, don’t overwrite.** New spec/design revisions get new version numbers; refresh rundown “Last updated.”
6. **Scope discipline.** Award ends 06/29/2027 at ≤$40K with student developers. Stay inside MVP + explicit out-of-scope list.

## 9. Open co-design questions (do not silently “solve”)

Phone-less members (~40%) — including CAB interest in a simple website / non-phone path; tab names/icons; Help Now set/label/tone; resource categories beyond health; distance framing / map desire; trust markers + location wording (PRIV-3: personal My Health data is on-device only, not a cloud profile); notifications (CAB recovery/appointment reminder interest vs. shared phones + local-only study build — MVP-safe path remains optional on-device MYH reminders); PSS Helper Mode needs (group intro + periodic check-ins; short videos / live workshops); wallet-card / emergency-card priority and defaults.

**Follow-on only (out of scope this award):** personalized early-recovery push/notification packs; gamification for habit/retention. Capture for grant narrative — do not implement in the study build.

## 10. Doc hygiene

- Read order for humans: `CWC_Health_App/README.txt` → `00` → `01` → `02` + Figma.
- `CWC_Health_App/archive/` = superseded specs (v0.1–v0.3); not authoritative.
- Prefer editing source markdown in `CWC_Health_App/` when requirements or design intent change, then sync this file and `.cursor/rules/` so agents stay aligned.
- Engineering plans/specs for agents live under `docs/` (committed). `.cursor/plans/` is local/gitignored — prefer `docs/superpowers/` for shared work.

## 11. Engineering track — Nearby (Aug 2026)

**Priority:** Nearby / locator. **Local demo = live-on Android.** Compile-time `LIVE_NEARBY` still defaults off so meeting APKs stay on the fake list.

**Shared docs (start here):**

| Doc | Role |
|-----|------|
| [`docs/engineering/nearby-live-data.md`](docs/engineering/nearby-live-data.md) | Collaborator handoff + as-built + next work |
| [`docs/superpowers/specs/2026-08-11-nearby-live-data-design.md`](docs/superpowers/specs/2026-08-11-nearby-live-data-design.md) | Live-data spike design (implemented) |
| [`docs/superpowers/plans/2026-08-11-nearby-live-data.md`](docs/superpowers/plans/2026-08-11-nearby-live-data.md) | Tasks 1–6 done; Task 7 docs written |
| [`docs/superpowers/specs/2026-09-03-nearby-map-design.md`](docs/superpowers/specs/2026-09-03-nearby-map-design.md) | FIND-4 overhead map (implemented) |

**Locked approach (this spike):** Google Places HTTP (optional, **no billing** → expected soft-fail) → **OSM Overpass** fallback; Nominatim for town geocode; pure Dart on iOS+Android; **no** curated CWC overlay; gate behind `LIVE_NEARBY` (default off).

**Implementation: complete on `main`.** Tasks 1–2 by ks1686; Tasks 3–6 by kholaif (PRs #3–#7). Hours expand is on `main` (flag default still off). Study-build hardening (2026-08-15): member-safe empty vs unavailable, Nominatim timeout, persistent last-success cache, 18pt body + 48dp Help Now, honest PIN/Erase copy, gated `HELP_NOW_LIVE`. Live Nearby on Android: one-shot coarse GPS, nearest-first sort, town fallback, FIND-4 opt-in map (Google when keyed, OSM `flutter_map` study default). Still open: physical Android/iOS tap of Call. Spec FIND-1 is still the curated-directory MVP — do not silently rewrite it.

**CI:** PRs to `main` run `.github/workflows/flutter-ci.yml` — format/analyze/unit+widget tests, `integration_test` navigation smoke, debug APK, and unsigned release APK. **No web job** (web is not a ship target).

**Run (local):** `flutter run -d android --dart-define=LIVE_NEARBY=true`

---

## Learned User Preferences

- Prefer Cursor’s Simple Browser only if a temporary web spike exists; **study-build demos are Android** (`flutter run -d android`). Flutter web is not a ship target.
- Distill `CWC_Health_App/` into AGENTS.md and `.cursor/rules/` for agents while keeping those markdown files as the versioned source of truth.
- Nearby is the current engineering priority. Local review uses **live Nearby** (`LIVE_NEARBY=true`) on Android; the flag-off static list is not the working demo.
- Prefer GitHub Actions CI that covers format, analyze, unit/widget/integration tests, and Android compile—not format/lint alone.
- Prefer Nearby (and other feature) work in a git worktree under `/Users/ks1686/Documents/Worktrees/rutgers-health-services-app/<branch>` rather than dirtying the main checkout.
- For parallel agents on this repo, use separate worktrees per slice (e.g. Nearby vs My Health) so agents do not collide.

## Learned Workspace Facts

- Flutter package at repo root is `cwc_health_app`; Android application id is `org.rutgers.cwc.cwc_health_app`.
- Study build on `main`: four tabs + Help Now; live Nearby (Google soft-fail → OSM) behind `LIVE_NEARBY` (default off); My Health CRUD + Keystore/Keychain encryption + optional PIN + Erase. Live cards show Open now / Closed (expand weekday hours when OSM tags parse). Other tabs still use static demo data and “Demo only” snackbars.
- Live Nearby device path: one-shot coarse GPS on load (coordinates transient / not cached); list sorted by proximity; town picker is the fallback when location is denied or unavailable; NJ region guardrail is skipped on the device-location path so travel out of state still works.
- Live Nearby map (FIND-4): opt-in overhead map; Google Maps when `GOOGLE_MAPS_API_KEY` is set on native, else OSM/`flutter_map` (study default on Android); pins follow the shared category filter; no pan-to-refetch.
- `.cursor/rules/` is committed; other `.cursor/*` paths remain gitignored — put shared plans under `docs/`.
- Flutter web is **not** a ship or CI target (`web/` removed). Use Android emulator/device for local demos.
- GitHub remote `origin` is the private repo `ks1686/rutgers-health-services-app`.
- Flutter CI is `.github/workflows/flutter-ci.yml`.
