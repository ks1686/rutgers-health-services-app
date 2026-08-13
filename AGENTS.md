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

Funded, IRB-approved Rutgers pilot (OVPR BHEI, ~$40K, 06/30/2025–06/29/2027): co-design a smartphone app that centralizes health information and healthcare/wellness navigation for adults with mental health, substance use, and/or co-occurring physical conditions who live in poverty—many currently or formerly unhoused. Work happens in **Community Wellness Centers (CWCs)** run by **CSPNJ** across NJ. Three aims: (1) needs assessment via focus groups, (2) co-design + student-built app, (3) usability testing + peer-led training materials. As of August 2026 (~M14): pre-surveys analyzed; spec v0.4 + Final Design v1.1 (Rutgers Scarlet) drafted; Flutter v1 static navigation prototype exists; **Nearby live-data** is the next engineering plan (docs under `docs/engineering/` — implement only when explicitly requested).

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

**Design implications:** Android-first, offline-first, shared/kiosk devices, large type, no hidden nav, peer help as first-class UI, walk/transit distances, minimal data collection, trust-first permission prompts.

## 4. Product (MVP) — behavior summary

Authoritative detail + evidence tags: feature spec v0.4. Working names subject to CAB/[PENDING FG].

**IA:** Bottom tabs **Nearby | My Health | Learn | More** (no hamburger/drawer). Persistent **Help Now** in every header. Max two taps from a tab root to a core task. **Nearby** is default landing.

| Area | MVP |
|------|-----|
| **Nearby** | Curated NJ directory (cached offline); region/town picker primary; GPS optional + explained; list-first with walk-time; optional OSM map |
| **My Health** | Manual appointments, meds, providers/portal *link-outs* (no credentials), offline wallet card; optional PIN (never gates Nearby/Learn/Help Now) |
| **Learn** | Six domains; ~6th-grade; source-labeled; offline; **no AI answers** in study build |
| **Help Now** | One tap, never PIN-blocked, offline: 988 call+text, 911, Poison Control, member’s CWC, NJ peer warmline; optional emergency card (off by default) |
| **More** | Tutorials + ≤90s Wi‑Fi-downloadable videos, Ask a Peer, PSS Helper Mode (demo data), settings, plain-language privacy, one-tap erase |

**Tech:** Flutter (chosen track for this repo) or RN per proposal; Android 8+ era / low-RAM test device; &lt;~40MB; offline-first; remote-config/hosted JSON for directory + Learn + Help Now numbers; WCAG 2.1 AA, ≥48dp targets, 18pt+ body + OS scaling, TalkBack/VoiceOver; open-source/low-cost stack.

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

## 11. Engineering track — Nearby live data (Aug 2026)

**Priority:** Nearby / locator. Static demo remains default for meetings and pre-usability.

**Shared docs (start here):**

| Doc | Role |
|-----|------|
| [`docs/engineering/nearby-live-data.md`](docs/engineering/nearby-live-data.md) | Collaborator handoff + locked decisions |
| [`docs/superpowers/specs/2026-08-11-nearby-live-data-design.md`](docs/superpowers/specs/2026-08-11-nearby-live-data-design.md) | Design |
| [`docs/superpowers/plans/2026-08-11-nearby-live-data.md`](docs/superpowers/plans/2026-08-11-nearby-live-data.md) | Task-by-task implementation plan |

**Locked approach:** Google Places HTTP (optional, **no billing** → expected soft-fail) → **OSM Overpass** fallback; Nominatim for town geocode; pure Dart on iOS+Android; **no** curated CWC overlay; gate behind `LIVE_NEARBY` (default off).

**Implementation:** Tasks 1–2 complete on `main` (models + OSM Nominatim/Overpass, by ks1686). **Task 3 (Google Places soft-fail) is claimed by kholaif.** Leave Task 3 files alone unless you are kholaif. Spec FIND-1/TECH-6 tension is documented in the handoff — do not silently rewrite the feature spec.

**CI:** PRs to `main` run `.github/workflows/flutter-ci.yml` — format/analyze/unit+widget tests, `integration_test` navigation smoke, `flutter build web`, and `flutter build apk --debug`.

---

## Learned User Preferences

- Prefer barebones navigation prototypes with static demo data before adding permissions, persistence, or dynamic behavior.
- Prefer browser (Chrome/web) for demos and meeting showcases over the Android emulator when both are options.
- Distill `CWC_Health_App/` into AGENTS.md and `.cursor/rules/` for agents while keeping those markdown files as the versioned source of truth.
- Nearby is the current engineering priority; keep the static Nearby prototype for demos; share live-data work via committed `docs/` plans so humans and agents can collaborate before code lands.

## Learned Workspace Facts

- Flutter package at repo root is `cwc_health_app`; Android application id is `org.rutgers.cwc.cwc_health_app`.
- Current app stage is a v1 static navigation prototype (Nearby | My Health | Learn | More + Help Now) with fake demo data and “Demo only” snackbars.
- `.cursor/rules/` is committed; other `.cursor/*` paths remain gitignored — put shared plans under `docs/`.
- No local Android AVD is currently configured (former `VM_Phone` was deleted); Flutter web is the usual local demo path.
- GitHub remote `origin` is the private repo `ks1686/rutgers-health-services-app`.
- Nearby live-data plan: Google soft-fail → OSM Overpass; no curated CWC overlay; `LIVE_NEARBY` default false once implemented.
