# Health Information Access App — Feature Specification & Requirements Document

**Project:** Facilitating Access to Digital Health Information for Individuals with Multifaceted Health and Social Needs: Smartphone App Co-design in Community Wellness Centers
**Funder:** Rutgers OVPR / Behavioral Health and Equity Initiative pilot award
**Investigators:** Sartor (PI), Swarbrick, Spagnolo, Haghani
**Document version:** v0.4 (pre–focus group synthesis draft)
**Status:** Working draft for research team and Stakeholder Advisory Committee review
**Companion documents:** `00_PROJECT_RUNDOWN_CWC_Health_App.md` (project context / agent handoff) · `02_CWC_Health_App_Design_Reference_v1.1.md` (visual design) · Figma file "CWC Health App — Lo-Fi Wireframes v0.1" at https://www.figma.com/design/yAwsNNegakKROue3o0CAMJ (canonical design artifact; contains both the lo-fi wireframes and the Final Design v1.1 (Rutgers Scarlet) presentation page)

**Changes in v0.4:** Captured Aug 2026 CAB discussion (MacWhisper: "Personalized App for Recovery Support") into open questions and privacy wording — no MVP requirement expansions. Enriched §9 Q1/Q7/Q8 with `[CAB]` notes; clarified PRIV-3 that My Health personal data is on-device only (not a cloud identity profile); tagged ONB-5 with CAB interest in a simple non-phone path; noted follow-on backlog items under §8 (personalized recovery notifications; FG gamification interest) while keeping them out of scope for this award.
**Changes in v0.3:** Added cross-references to the design artifacts (Figma file + Design Reference doc); marked wireframe/design step complete in §10. No requirement changes.
**Changes in v0.2:** Revised information architecture (resource-first home, bottom tab bar with visible "More" screen replacing hamburger-menu concept); region-picker-first location approach with optional map; new "Help Now" quick-access section (§6.6); related updates to onboarding, privacy, open questions.

---

## 1. Purpose of this document

This document translates what is currently known — from the funded proposal, the pre–focus group survey data, Community Advisory Board (CAB) input, and the supporting literature — into a concrete, testable set of requirements for the smartphone app to be built in Aim 2. It is deliberately structured as a *living* specification: every requirement is tagged with its evidence source, and requirements that depend on focus group findings still being collected under Aim 1 are explicitly flagged as **[PENDING FG]** so the Stakeholder Advisory Committee can confirm, revise, or reject them as qualitative analysis proceeds. Nothing in this document should be treated as fixed until it has been reviewed with the advisory committee, consistent with the project's equity-centered, end-user-driven design commitment.

**Evidence source tags used throughout:**

| Tag | Source |
|---|---|
| [PROP] | Funded BHEI proposal / research narrative |
| [SURV-M] | Member pre-survey (Qualtrics export, n=40 completed) |
| [SURV-P] | Peer Support Specialist pre-survey (n=11 completed) |
| [CAB] | Community Advisory Board meeting notes |
| [LIT] | Supporting literature in project library |
| [TEAM] | Research team design decision (this document's revision discussions) |
| [PENDING FG] | To be confirmed/refined by focus group thematic analysis |

---

## 2. Background and problem statement

People living with mental health, substance use, and co-occurring physical health conditions — particularly those experiencing poverty and housing instability — face substantial barriers to finding, understanding, and using health information through digital tools. Personal health information (test results, prescriptions, appointments) is increasingly delivered only through patient portals with complex logins and menus, while reliable general health information is scattered across websites of varying credibility. Low eHealth literacy in this population is associated with lower engagement in health-promoting behavior and worse outcomes. [PROP]

Community Wellness Centers (CWCs) operated by Collaborative Support Programs of New Jersey (CSPNJ) provide a trusted, low-barrier, peer-delivered setting serving exactly this population. The app will be co-designed in six CWCs across northern, central, and southern New Jersey with two user groups: **members** (people with lived experience of mental health and/or substance use challenges) and **peer support specialists (PSS)** employed at the centers. [PROP]

The core product concept: **a single, simple, trusted app that consolidates (a) an individual's personal health information touchpoints, (b) local health and wellness resources, and (c) vetted general health information — designed for the real devices, connectivity, literacy levels, and trust context of CWC members, with peer support specialists as the built-in human support layer.** [PROP]

---

## 3. What the data already tells us

### 3.1 Member pre-survey (n=40 completed)

- **Device access is the single biggest design constraint.** Only 25 of 40 members reported having access to a smartphone; 15 did not, and most of those without a phone also lacked regular access to someone else's. This gap is substantially larger than in comparable published samples (e.g., 86% ownership in the Deshais et al. wellness-enhanced contingency management study). [SURV-M] [LIT]
- **Android dominates.** Among members with phones: 21 Android vs. 6 Apple. Several lack a data plan or reliable internet. [SURV-M]
- **Comfort is bimodal.** Half of phone-owning members rated smartphone comfort 4/4, but a meaningful minority rated 2/4; confidence finding and understanding health information similarly spans 2–4. [SURV-M]
- **Health app use is currently rare.** "Rarely" or "Never" was the modal response for health-app use even among daily smartphone users. [SURV-M]
- **Housing instability is pervasive.** Roughly half the completed member sample is unhoused (sheltered or unsheltered). Phones may be lost, stolen, replaced, or have interrupted service. Many members likely do not drive; walking and transit are the default modes of travel. [SURV-M]
- **Interest is high.** 24 of 27 members who answered said a smartphone health app would be helpful. [SURV-M]
- **Top information needs (members):** physical health (17), mental health (15), exercise/fitness (11), nutrition (10), medications (10), preventive care (9). [SURV-M]
- **Current information sources:** internet search, health websites, social media, friends/family, healthcare providers, community organizations — and, notably, several respondents already report asking AI assistants. One wrote in a named resource specialist at their center as their information source, underscoring the trusted-person pathway. [SURV-M]
- **Preferred help formats:** video walkthrough (10), peer support specialist (8), step-by-step tutorial (7), in-person workshop (6), phone/chat support (5). [SURV-M]

### 3.2 Peer support specialist pre-survey (n=11 completed)

- Universal smartphone access with data plans; slight Apple majority (6 Apple, 4 Android, 1 other). [SURV-P]
- Very high smartphone comfort (10 of 11 at 4/4) but, like members, low current health-app use. [SURV-P]
- 10 of 11 view a health app as helpful. PSS are stably housed and employed — a distinctly different user profile from members, well positioned for the trainer/helper role envisioned in the proposal. [SURV-P]

### 3.3 CAB and protocol input

- Recruitment and communication must not assume voicemail use; text-accessible contact channels matter. Materials need high visual salience and large-font contact information. These same principles (visual clarity, large type, multiple contact modalities) carry into app design — including offering text as well as call options wherever a phone number appears. [CAB]
- Survey administration experience showed participants completing forms on a mix of personal devices and center-borrowed devices — a preview of how the app itself will be used. [CAB]

### 3.4 Key lessons from the literature library

- **Data limits, not just ownership, break engagement.** Participants on government-issued phones frequently exhaust cellular data mid-month, degrading or disabling app use. [LIT: Deshais et al.]
- **Trust, privacy, and perceived surveillance are decisive adoption factors** for people who have experienced stigma or system surveillance. [PROP] [LIT: Whitehead; Ding et al.]
- **Digital literacy support must be actionable, not just measured** — pairing skill assessment with concrete matched supports (the Dwyer Technology Use Survey / Module Matching model). [LIT]
- **Perceived usefulness and ease of use drive adoption** (Technology Acceptance Model framing used in the Foundry BC qualitative work); tools that feel clinical, complicated, or monitoring-oriented are abandoned. [LIT: Ding et al.]
- **Peer co-design and co-leadership produce more relevant, trusted tools** and are feasible at every project stage. [LIT: Darcey et al.; Incze et al.; co-production principles papers]

---

## 4. Users and personas

**P1 — "Member with own Android phone" (primary persona).** 35–64, high school education or less, unemployed or receiving SSI/SSDI, housing unstable. Uses the phone daily for communication and social media but rarely for health. May run out of data. Comfort 3–4/4 but low confidence evaluating health information. Wants medication info, appointment help, and nearby resources. Travels by foot or transit.

**P2 — "Member without a personal phone."** Uses a center-borrowed device or occasional access. Cannot rely on persistent personal login, push notifications, or app-store installs on a personal device. Needs the app (or a companion mode) to work in short, assisted, shared-device sessions.

**P3 — "Lower-comfort member."** Owns a phone but rates comfort 2/4; uses apps rarely. Needs large targets, minimal navigation depth, plain language, and human help pathways. Hidden navigation patterns (drawers, gestures) are likely to fail this persona entirely.

**P4 — "Peer support specialist."** High digital comfort, employed at a CWC, often on iPhone. Uses the app both personally and as a *helper* — walking members through setup and tasks, running trainings. Needs a demonstration/training mode and the ability to help without accessing a member's private information.

**P5 — Research/administrative user (internal).** Study team members configuring resource directory content and, during Aim 3, capturing usability feedback.

---

## 5. Design principles

1. **Nothing about us without us.** All features in Section 6 are hypotheses to be confirmed, reprioritized, or replaced by focus group findings and Stakeholder Advisory Committee decisions. [PROP]
2. **Design for the worst connection, the cheapest phone, and the shared device.** [SURV-M] [LIT]
3. **Trust before features.** No feature ships if it undermines the plain-language privacy story. Collect the minimum, explain everything, never surprise the user. Permission requests (especially location) are treated as trust moments and are always optional, contextual, and explained in one sentence. [PROP] [LIT] [TEAM]
4. **Peer support is a feature, not an afterthought.** Human help pathways are first-class UI elements. [SURV-M] [PROP]
5. **One thing per screen; nothing hidden.** Cognitive and emotional accessibility: shallow navigation, consistent layout, forgiving interactions, no dead ends — and **no concealed navigation**. Every feature has a visible, labeled entry point; the app uses no hamburger menu or slide-out drawer. [PROP] [TEAM]
6. **The app is a bridge, not a silo.** It links people to portals, providers, and places; it does not attempt to replace clinical systems or become a medical record. [PROP]

---

## 6. Feature requirements

Features are grouped into **MVP (alpha/usability-test build)** and **Post-MVP (refinement phase or future funding)**. Requirement IDs use the pattern *area-number*.

### 6.1 Information architecture & navigation

The app uses a **persistent bottom tab bar** with four icon+label tabs, plus a **persistent "Help Now" button** in the header of every screen (see §6.6). There is no hamburger menu or navigation drawer: hidden navigation sharply reduces feature discoverability, and this effect is strongest for exactly the lower-comfort users this app must serve (persona P3). Drawers also introduce gesture conflicts for users with motor difficulties and complicate screen-reader navigation. [TEAM] [LIT: TAM/ease-of-use findings]

- **NAV-1 (MVP).** Bottom tab bar with four tabs (working names, subject to co-design): **Nearby | My Health | Learn | More**. Tabs are icon + text label, minimum 48dp touch targets, always visible. [TEAM] [PENDING FG — naming and iconography to be co-designed]
- **NAV-2 (MVP).** **Nearby (the local resource directory, §6.3) is the default landing tab.** It is the most universally useful feature, requires no personal data, and works fully in guest/kiosk mode — so the app is immediately useful to every persona, including members using borrowed devices. [TEAM] [SURV-M]
- **NAV-3 (MVP).** The **More** tab opens a plain, large-type, scrollable list screen — not a drawer — containing: Get Help Using This App (tutorials & videos, §6.5), Ask a Peer, PSS Helper Mode, Settings, "How this app protects you," and Erase My Information. It behaves like any other screen: visible entry point, standard back behavior, screen-reader friendly. [TEAM]
- **NAV-4 (MVP).** Maximum navigation depth of two taps from any tab root to any core task.
- **NAV-5 (MVP).** Persistent "Help Now" affordance in the header of every screen, visually distinct from the tab bar (§6.6). [TEAM]

### 6.2 My Health (personal health organizer)

- **MYH-1 (MVP).** Appointment keeper: store provider name, date/time, location, phone number, and a free-text note; optional local reminder. Manual entry only in MVP (no EHR integration). [PROP]
- **MYH-2 (MVP).** Medication list: name, what it's for (plain-language free text), dosage/schedule as entered by the user; optional reminder. Explicitly framed as a personal memory aid, not medical advice. [SURV-M]
- **MYH-3 (MVP).** My providers & portals: a personal list of care contacts with one-tap call, one-tap text where available, and one-tap link to that provider's patient portal login page. The app links out; it never stores portal credentials. [PROP] [CAB]
- **MYH-4 (MVP).** Wallet card: a single screen the user can show at an appointment (medications, providers, emergency contact). Works fully offline. Also surfaced, at the user's option, from the Help Now screen (§6.6). [TEAM]
- **MYH-5 (Post-MVP).** Optional secure export/backup of My Health data (e.g., printout or file) to survive device loss — a real risk given housing instability. [SURV-M] [PENDING FG]
- **MYH-6 (Post-MVP, contingent).** Direct patient-portal integration (e.g., SMART on FHIR) — out of scope for this award; candidate for the follow-on federal application. [PROP]

### 6.3 Nearby (local resource directory — default landing screen)

- **FIND-1 (MVP).** Curated, study-team-maintained directory of local resources: pharmacies, clinics/FQHCs, urgent care, vaccination sites, CWCs themselves, and wellness supports; each entry has name, address, phone (tap-to-call **and tap-to-text** where available), hours, and a one-line plain-language description. [PROP] [CAB]
- **FIND-2 (MVP).** **Region/town picker is the primary location method.** On first use the screen asks "Where are you looking?" with a simple picker (North / Central / South NJ, then town), remembered for next time. Device location (GPS) is offered as an optional shortcut ("Use my location instead?") with a one-sentence plain-language explanation, requested only in that moment, never at app launch. Declining location never blocks any functionality. Rationale: permission prompts are trust moments for a population with surveillance concerns, and a picker works offline where GPS+map does not. [TEAM] [LIT: Whitehead; Ding] [SURV-M]
- **FIND-3 (MVP).** **List-first presentation with human-scale distance.** Results display as a large-type list. When a location or town anchor is known, each entry shows an approximate **walk time** ("about a 15 min walk") rather than raw miles, reflecting that many members travel on foot or by transit; transit hints (e.g., nearby bus route) are included in directory entries where the team can curate them. [TEAM] [SURV-M: housing/transport context] [PENDING FG — confirm distance formats members find meaningful]
- **FIND-4 (MVP).** **Optional map view** as a secondary toggle from the list, for users who want spatial context. Implemented with free/open tiles (e.g., OpenStreetMap) to avoid API costs and account requirements; map tiles load only on demand and degrade gracefully offline (list remains fully functional). NJ-only coverage keeps pre-caching of coarse tiles feasible. [TEAM] [TECH-3]
- **FIND-5 (MVP).** Directory data is cached on-device and fully browsable offline; filter by category and by region. [SURV-M] [LIT: Deshais]
- **FIND-6 (Post-MVP).** Additional social-determinant categories (food, transportation, benefits assistance) if prioritized by focus groups. [PENDING FG]
- **FIND-7 (MVP, admin).** Lightweight content-management path for the research team to update directory entries without an app-store release (remote config or hosted JSON pulled when connected).

### 6.4 Learn (vetted health information)

- **LRN-1 (MVP).** Library of short, plain-language entries in the six member-priority domains: physical health, mental health, nutrition, exercise/fitness, medications, preventive care. [SURV-M]
- **LRN-2 (MVP).** Every entry links only to vetted sources approved by the research team and advisory committee; sources are labeled ("From: CDC", etc.) to make trustworthiness visible. [PROP] [PENDING FG]
- **LRN-3 (MVP).** All original text written at approximately a 6th-grade reading level; validated with readability tooling and advisory committee review. [PROP]
- **LRN-4 (MVP).** Entries cached for offline reading. [SURV-M]
- **LRN-5 (Post-MVP).** Optional read-aloud (text-to-speech) for entries. [P3] [PENDING FG]
- **LRN-6 (Explicitly deferred).** No AI chat/answer feature in the study build, despite survey evidence that some members already ask AI assistants health questions. Rationale: credibility-vetting is a core project value and an uncontrolled generative feature would undermine it. Revisit for future funding with guardrails. [SURV-M] [PROP]

### 6.5 Get Help Using This App (support layer — lives under More)

- **HELP-1 (MVP).** Step-by-step tutorials with screenshots for every core task (add an appointment, find a pharmacy, etc.). [SURV-M]
- **HELP-2 (MVP).** Short (≤90-second) video walkthroughs for the same tasks, downloadable at the CWC on Wi-Fi so they play offline. [SURV-M]
- **HELP-3 (MVP).** "Ask a Peer" pathway: prominent option that surfaces the user's CWC contact info (call and text) and frames PSS as the go-to human help. [SURV-M] [PROP] [CAB]
- **HELP-4 (MVP).** PSS Helper Mode: a demonstration mode with sample data that a peer support specialist can use on their own phone (including iPhone) to walk a member through any task without viewing the member's real data. Doubles as the training-delivery vehicle for Aim 3 materials. [SURV-P] [PROP]
- **HELP-5 (Post-MVP).** Phone/chat support line integration if the project or CSPNJ can staff it. [SURV-M] [PENDING FG]

### 6.6 Help Now (quick-access support screen) — NEW in v0.2

A single screen reachable in **one tap from anywhere in the app**, in all modes (including guest/kiosk), and **never blocked by the PIN lock** — a member in distress, or a bystander or first responder holding the member's phone, must not hit a passcode wall. [TEAM]

- **NOW-1 (MVP).** Persistent, high-contrast "Help Now" button in the header of every screen. Deliberately labeled in supportive rather than alarm language ("Help Now" / "Quick Help," not "EMERGENCY") so the app reads as supportive, not clinical, and everyday use of the app doesn't feel crisis-adjacent. [TEAM] [PENDING FG — label and tone to be co-designed]
- **NOW-2 (MVP).** **Layer 1 — always available, fully offline:** large tap-to-call and tap-to-text actions for 988 (call *and* text — voice-only cannot be assumed [CAB]), 911, Poison Control (1-800-222-1222), the member's own CWC phone number, and the NJ peer-run **warmline** (peer-operated, lower-stakes than crisis lines, and operated within the CSPNJ service model — a trusted, mission-aligned default). [TEAM] [CAB] [PENDING FG — confirm the exact resource set with the advisory committee]
- **NOW-3 (MVP).** **Layer 2 — optional personal emergency card:** the member may choose to make their wallet card (emergency contact, medications, conditions; §6.2 MYH-4) visible from the Help Now screen for first responders. Off by default; enabling it requires an explicit, plainly-worded choice, since it exposes health information on an unlocked screen. [TEAM]
- **NOW-4 (MVP).** All Help Now content is bundled with the app and functions with no connectivity and no personal data. Numbers are updatable via the same remote-config path as the directory (FIND-7).
- **NOW-5 (Co-design activity).** Focus groups should be asked directly: *"What would you want one tap away if you needed help fast?"* Anticipated answers may include specific shelter intake lines, named trusted staff, or warmlines rather than hotlines — resources the team would not guess. [PENDING FG]

### 6.7 Onboarding, accounts, and shared-device use

- **ONB-1 (MVP).** First-run onboarding is skippable, under two minutes, and repeatable from More → Settings. Collects nothing beyond an optional first name and optional PIN. No location permission is requested during onboarding (see FIND-2). [TEAM]
- **ONB-2 (MVP).** No account, email, or phone number required to use the app. All personal data stored locally on-device by default. [Design principle 3]
- **ONB-3 (MVP).** Optional PIN/biometric lock protecting the My Health area — important on shared, borrowed, or shelter-environment devices. The PIN never gates Nearby, Learn, tutorials, or Help Now. [P2] [TEAM]
- **ONB-4 (MVP).** Guest/kiosk mode for center-owned devices: full access to Nearby, Learn, tutorials, and Help Now with no personal data retained between sessions. [P2] [CAB]
- **ONB-5 (Post-MVP).** Companion web version of the non-personal content (directory + Learn) for members without smartphones. [SURV-M] [CAB: Aug 2026 discussion also raised a simple website / non-phone path] [PENDING FG]

### 6.8 Accessibility & literacy (cross-cutting)

- **ACC-1 (MVP).** Minimum 18pt base body text with an in-app "larger text" toggle; respects OS-level font scaling. [CAB]
- **ACC-2 (MVP).** Touch targets ≥ 48dp; high-contrast color palette meeting WCAG 2.1 AA; never color-only meaning.
- **ACC-3 (MVP).** All copy at ~6th-grade reading level; icons always paired with text labels. [PROP]
- **ACC-4 (MVP).** Full compatibility with TalkBack (Android) and VoiceOver (iOS); no gesture-only interactions (another reason drawers are excluded, NAV-1). [TEAM]
- **ACC-5 (Post-MVP).** Spanish-language version — explicitly named in the proposal as future-scale work, not this award. [PROP]

### 6.9 Privacy, security, and trust (cross-cutting)

- **PRIV-1 (MVP).** Local-first data storage; no personal health data transmitted off-device in the study build. [Design principle 3]
- **PRIV-2 (MVP).** No advertising, no third-party analytics SDKs, no location tracking. If the user opts into device location for Nearby, coordinates are used transiently on-device for distance display and are never stored or transmitted. Any usage analytics for the study are opt-in, aggregate, and IRB-approved. [PROP] [LIT] [TEAM]
- **PRIV-3 (MVP).** A one-screen, plain-language "How this app protects you" page reachable from More, co-written with the advisory committee; includes a plain explanation of what the optional location shortcut does and does not do. Trust copy should make clear that My Health personal entries (appointments, meds, providers) stay **on this device only** — not a cloud account or identity profile the project can see — so “local personal memory aids” are not confused with collecting identifying health information off-device. [PENDING FG] [TEAM] [CAB]
- **PRIV-4 (MVP).** On-device data encrypted at rest using platform keystore; PIN-locked areas hidden from app-switcher previews. Help Now remains outside the PIN boundary by design (NOW-1). [TEAM]
- **PRIV-5 (MVP).** One-tap "erase my information" (under More) that fully clears personal data — supports shared devices and personal safety.

---

## 7. Platform & technical requirements

- **TECH-1.** Cross-platform framework (Flutter or React Native) targeting Android and iOS from one codebase, per the funded proposal; suitable for undergraduate ECE student development under Dr. Haghani. [PROP]
- **TECH-2.** **Android-first optimization**: minimum SDK supporting Android 8+ era budget and government-program devices; test matrix must include at least one low-RAM (~2GB) device. [SURV-M] [LIT]
- **TECH-3.** Installed app size target under ~40MB; no mandatory large downloads at first run; videos and map tiles fetched only on Wi-Fi or on explicit user action. [LIT]
- **TECH-4.** Offline-first architecture: every MVP feature except the optional map view and external links must function with no connectivity; content syncs opportunistically when connected. The Nearby list, Learn entries, tutorials, and Help Now are always available offline. [SURV-M] [TEAM]
- **TECH-5.** Resource directory, Learn content, and Help Now numbers delivered from a simple hosted content file the research team can edit (FIND-7, NOW-4), avoiding app-store releases for content updates.
- **TECH-6.** Map view uses open/free tile services (e.g., OpenStreetMap) — no commercial map API keys, accounts, or per-use costs; coarse NJ tiles may be pre-bundled or cached at CWCs on Wi-Fi. [TEAM]
- **TECH-7.** Instrumentation for Aim 3 usability sessions (e.g., task-completion timing) must be a build-flag, present only in the research build, and disclosed in consent. [PROP]
- **TECH-8.** Open-source or low-cost licensing throughout, consistent with the sustainability commitment. [PROP]

---

## 8. Explicitly out of scope for this award

Symptom tracking or clinical assessment; diagnosis or treatment advice; EHR/portal credential storage or direct integration; messaging between members; social feeds; gamification/incentive systems; AI-generated answers; Spanish localization (deferred to future funding); crisis intervention functionality beyond the static, vetted Help Now resource set. Several of these (portal integration, Spanish version, AI with guardrails) are natural components of the follow-on federal or foundation proposal. [PROP]

**Follow-on backlog (do not build in this award; keep for grant narrative):** CAB members described interest in highly personalized early-recovery notification packs (e.g., morning meditation reminders, NA/sponsor/step-work cues, parole/appointment “be here” alerts, optional “call a hotline before you use” prompts) — these imply identity/history and push infrastructure beyond local-first study-build privacy. [CAB] Focus-group discussion also surfaced gamification / habit-retention ideas; those remain out of scope here but may inform a later award. [CAB] [PENDING FG]

## 9. Open questions for focus groups and the Stakeholder Advisory Committee

1. How should the app serve the ~40% of members without personal smartphones — companion web version, kiosk mode emphasis, center-device lending workflows, or something the team hasn't considered? [SURV-M] [CAB: Aug 2026 discussion again raised a simple website / non-phone information path]
2. What are the right names, icons, and groupings for the four tabs? (Co-design activity candidate.) [NAV-1]
3. *"What would you want one tap away if you needed help fast?"* — the Help Now resource set, label, and tone should come from members, not assumptions. [NOW-5]
4. Which resource categories matter most beyond the health-service basics — food, transportation, benefits? [FIND-6]
5. What distance/travel framing is most meaningful — walk time, transit hints, miles? Do members want a map at all? [FIND-3, FIND-4]
6. What specifically makes members trust or distrust a health app, and what visible trust markers follow from that — including how the optional location shortcut should be worded? [PROP] [FIND-2]
7. Do members want reminders/notifications at all, and if so how (given phone number changes, shared/borrowed devices, and data limits)? CAB interest includes early-recovery and appointment-style reminders, but that desire must be balanced against local-only data and no mandatory accounts in the study build. Optional **on-device** med/appointment reminders (MYH-1/MYH-2) remain the MVP-safe path until co-design settles push vs. local. [CAB] [PENDING FG]
8. What do PSS need in Helper Mode to make peer-led training practical — and what should the Aim 3 training manual assume the app already teaches? CAB discussion favored a **group intro** plus **periodic check-ins** (“who’s using it / who’s stuck?”), with training formats leaning toward short videos and live workshops (also one-pagers / one-on-one coaching as options). [CAB] [SURV-P]
9. Should the wallet card / device-loss backup be prioritized higher given the housing-instability profile of the sample? Should the optional emergency-card exposure on Help Now (NOW-3) default differently?

## 10. Traceability & next steps

Every requirement above is tagged to its evidence source, and [PENDING FG] items should be revisited as the thematic analysis of the 12 focus groups is completed (Aim 1, months 7–9).

**Design artifacts (completed).** The visual design realizing these requirements lives in the Figma file at https://www.figma.com/design/yAwsNNegakKROue3o0CAMJ — page "00 · Lo-Fi Exploration" holds grayscale wireframes for hands-on co-design exercises; page "01 · Final Design v1.1 (Rutgers Scarlet)" holds the presentation-ready high-fidelity screens with spec-traceable captions (requirement IDs annotated under every screen) and the "Why it looks this way" evidence panel. Color, typography, and screen-to-requirement mapping are documented in `02_CWC_Health_App_Design_Reference_v1.1.md`. The design and this spec version together: any requirement change here should trigger a design review, and any design change there should be reflected in a new spec version.

Suggested sequence from here: (1) advisory committee review of this spec + the Final Design v1.1 (Rutgers Scarlet) screens, (2) update both into v1.0 after focus group synthesis, (3) Flutter/React Native framework decision and student development plan, (4) alpha build for internal testing per the project timeline (months 10–15).
