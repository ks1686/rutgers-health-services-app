# Design Reference — CWC Health App (Final Design v1.1 — Rutgers Scarlet)

**Purpose:** This document is the durable, local record of the app's visual design. It ties the Figma design file to the feature specification and the project rundown so that any collaborator — human or AI agent — can find, understand, present, or extend the design without prior context.

**Canonical design file (Figma):** https://www.figma.com/design/yAwsNNegakKROue3o0CAMJ
**File name:** CWC Health App — Lo-Fi Wireframes v0.1 *(the file name reflects its origin; it now also contains the Final Design v1.1 page)*
**File key:** `yAwsNNegakKROue3o0CAMJ`
**Companion documents:** `00_PROJECT_RUNDOWN_CWC_Health_App.md` (project context) · `01_CWC_Health_App_Feature_Specification_v0.4.md` (requirements — authoritative for behavior)
**Last updated:** September 2026 — **v1.1** tokens/Figma unchanged. As-built Flutter Nearby notes and Learn tile list under §2 (six study-build tiles; no Medications or Exercise cards) — not a visual rebrand; next look change should bump to v1.2.

**Rule of the three documents:** the rundown explains *the project*, the spec defines *what the app does*, this document + the Figma file define *what the app looks like*. A change in any one should be checked against the other two, and versions should be bumped together.

---

## 1. File structure

The Figma file contains two pages:

- **Page "00 · Lo-Fi Exploration"** — the original grayscale wireframes of the five key screens. **Keep these.** They are the better artifact for hands-on co-design exercises with the Stakeholder Advisory Committee (participants feel freer to change gray boxes than polished screens), and they document the design's evolution.
- **Page "01 · Final Design v1.1 (Rutgers Scarlet)"** — the presentation-ready set:
  - **Cover banner** (top): project title, version, and the framing badge *"Draft for co-design — nothing is final until the community says so."* Present this first; it prevents the polish from reading as a finished product imposed on the community.
  - **Five high-fidelity screens** (left to right): Nearby — Home · My Health · Learn · More · Help Now. Each is a 360×800 frame (Android-baseline width).
  - **Captions under each screen**: one-line rationale + the spec requirement IDs that screen realizes.
  - **"Why it looks this way" panel** (right of the screens): seven evidence-backed design decisions in plain language — this is the built-in talking-points slide.

## 2. Screen inventory & spec traceability

| Screen | What it shows | Spec requirements realized |
|---|---|---|
| Nearby — Home (default landing) | Town chip ("New Brunswick ▾") + optional "Use my location?" link; category filter pills; resource cards with plain-language status and walk-time/transit badges; Call · Text · Directions actions; "See these on a map" opt-in toggle | NAV-1, NAV-2, FIND-1 through FIND-5, design principles 2–3 |
| My Health | "Protected by your PIN — only you can see this" banner; Appointments, Medications, Providers & Portals cards with "+ Add" actions; "Show My Wallet Card" primary button ("works offline") | MYH-1 through MYH-4, ONB-3, PRIV-1 |
| Learn | 2×3 grid of the six member-priority topics (Physical Health, Mental Health, Nutrition, Exercise, Medications, Preventive Care); source-trust footnote | LRN-1 through LRN-4 |
| More | Large-type icon list: How to Use This App · Ask a Peer · Helper Mode · Settings · How This App Protects You · Erase My Information (styled in Rutgers black) | NAV-3, HELP-1 through HELP-4, PRIV-3, PRIV-5 |
| Help Now | Full-screen overlay (Back header, no tab bar); "You're not alone" intro; 988 (call/text), Peer Warmline, My Wellness Center as filled primary buttons; 911 black-outlined; Poison Control neutral-outlined; emergency-card toggle shown off by default with its consequence stated; "works even without internet" note | NOW-1 through NOW-4, deliberate peer-forward hierarchy |

Every screen (except Help Now, which is the destination) carries the persistent **Help Now pill** in the header (NOW-1) and the four-tab bottom bar with the active tab tinted (NAV-1). Sample data in Figma is intentionally realistic-but-fake (Dr. Rivera, Main Street Pharmacy, Metformin/Sertraline) so review conversations focus on structure, not placeholders.

**As built in the Flutter study build (August 2026, not a Figma change):** Nearby can show live OSM rows behind `LIVE_NEARBY` (disclaimer banner; hours currently the raw `opening_hours` tag; “See these on a map” is still a placeholder). Learn in the study build is a six-tile grid: Physical Health, Mental Health, Stress Management, Nutrition, Preventive Care, and Sleep — not the Figma six-topic set. There is no Learn "Medications" or "Exercise" tile; medicine lists live in My Health. Tokens and Figma frames above remain canonical for look. Engineering detail: `docs/engineering/nearby-live-data.md` and `docs/engineering/learn-content.md`.

## 3. Design tokens

For the eventual Flutter/React Native theme and for anyone editing the Figma file. All text is **Inter**.

| Token | Hex | Use |
|---|---|---|
| `primary` | `#CC0033` | **Rutgers Scarlet (Pantone 186)** — primary actions, active tab, Help Now pill, filled support buttons, wallet card, cover banner. White on scarlet ≈ 5.9:1 contrast (WCAG AA pass) |
| `primary-tint` | `#FAE7EC` | Soft scarlet tint — active-tab halo, walk-time badges, PIN banner, map toggle |
| `ink` | `#21262B` | Primary text |
| `sub` | `#5F6A72` | **Rutgers Gray (PMS 431)** — secondary text (WCAG AA on white at body sizes) |
| `line` | `#E4E1DB` | Hairlines, card borders, tab bar top border |
| `surface` | `#FCFBF9` | Screen background (warm off-white — deliberately non-clinical) |
| `card` | `#FFFFFF` | Cards, with soft shadow (y2 / blur8 / ~8% opacity) |
| `neutral-emphasis` | `#0D0D0D` | **Rutgers Black** — 911 outline/text and Erase My Information. Since scarlet now owns "red," destructive/emergency items differentiate with black instead of a second red |
| Canvas (Figma only) | `#F4F1EC` | Presentation page background; not an app color |

Type scale in the mockups: screen titles 24 Bold · card titles 17 Semi Bold · body 14 Regular · secondary 12–13. Production build must honor ACC-1 (18pt base + OS font scaling) — mockup sizes are visual approximations at 360px width, not implementation values.

**Intentional aesthetic choices to preserve:** official Rutgers identity (scarlet with black, gray, and white) so the app is visibly a Rutgers/CSPNJ-partnered product; warm neutrals rather than clinical blue/white; generous corner radii (10–14 cards, pill buttons); supportive language everywhere ("Help Now" not "EMERGENCY," "You're not alone"); color never carries meaning alone (ACC-2).

**One consideration to raise with the CAB:** red can read as urgency/alarm in health contexts. The design mitigates this by keeping scarlet as an *action* color on calm off-white surfaces (not as a background wash), pairing it with supportive language, and moving emergency/destructive items to black. Worth explicitly asking focus-group participants how the scarlet app *feels* — trust question #6 in the spec's open questions.

## 4. Design decisions at a glance (mirrors the in-file panel)

1. **Android-first, offline-first** — 21 of 27 member phones are Android; data plans run out. Everything except the map works with no internet. [SURV-M] [LIT]
2. **Nothing hidden** — no hamburger menus; four visible tabs + a plain "More" list. Hidden navigation fails lower-comfort users first. [TEAM]
3. **Your town, not your GPS** — town picker first; location sharing optional and explained. Permission prompts are trust moments. [TEAM] [LIT]
4. **Walk time, not miles** — many members travel on foot or by bus. [SURV-M]
5. **Help Now: one tap, never locked** — 988 call & text, peer warmline, your center; supportive tone; offline; outside the PIN. [TEAM] [CAB]
6. **Your info stays on your phone** — no accounts, no tracking, optional PIN, one-tap erase. [PROP] [LIT]
7. **Peers built in** — Ask a Peer + Helper Mode make peer support specialists part of the app. [SURV-M] [PROP]

## 5. Presenting the design

Suggested flow for the advisory committee meeting: cover banner → "Why it looks this way" panel → screens left to right (mirrors a user's journey: land on Nearby → personal items behind the PIN → learning → help → crisis support). Invite reactions on the open co-design questions, especially: tab names and icons (NAV-1), the Help Now contents and label (NOW-5 — *"what would you want one tap away?"*), distance framing (FIND-3), and the emergency-card default (NOW-3).

**Exporting for slides or printouts** (for attendees without Figma access): in Figma, select a screen frame → Export panel (right sidebar) → PNG at 2x → Export. Repeat per frame, or select all five frames and export in one action. The captions and panel export the same way.

## 6. Change control

- The Figma file is the canonical visual artifact; this document records its intent and tokens. When the design changes materially, duplicate the "01 · Final Design v1.1 (Rutgers Scarlet)" page, rename the copy to the next version, edit the copy, and bump this document's version to match — never destroy a presented version.
- Any requirement change in the spec triggers a design review; any design change here must be reflected in a new spec version (see spec §10).
- All [PENDING FG] items remain open in the design too: tab names, Help Now contents/label/hierarchy, distance formats, and the emergency-card default are hypotheses awaiting focus-group findings and CAB decisions.
- **Before any build ships:** verify the NJ peer warmline number and hours directly with CSPNJ (they operate NJ peer warmline services); confirm 988 text availability messaging; and have the CAB approve all Help Now contents.
