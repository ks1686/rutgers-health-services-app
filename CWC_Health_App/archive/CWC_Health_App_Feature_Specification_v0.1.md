# Health Information Access App — Feature Specification & Requirements Document

**Project:** Facilitating Access to Digital Health Information for Individuals with Multifaceted Health and Social Needs: Smartphone App Co-design in Community Wellness Centers
**Funder:** Rutgers OVPR / Behavioral Health and Equity Initiative pilot award
**Investigators:** Sartor (PI), Swarbrick, Spagnolo, Haghani
**Document version:** v0.1 (pre–focus group synthesis draft)
**Status:** Working draft for research team and Stakeholder Advisory Committee review

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
- **Housing instability is pervasive.** Roughly half the completed member sample is unhoused (sheltered or unsheltered). Phones may be lost, stolen, replaced, or have interrupted service. [SURV-M]
- **Interest is high.** 24 of 27 members who answered said a smartphone health app would be helpful. [SURV-M]
- **Top information needs (members):** physical health (17), mental health (15), exercise/fitness (11), nutrition (10), medications (10), preventive care (9). [SURV-M]
- **Current information sources:** internet search, health websites, social media, friends/family, healthcare providers, community organizations — and, notably, several respondents already report asking AI assistants. One wrote in a named resource specialist at their center as their information source, underscoring the trusted-person pathway. [SURV-M]
- **Preferred help formats:** video walkthrough (10), peer support specialist (8), step-by-step tutorial (7), in-person workshop (6), phone/chat support (5). [SURV-M]

### 3.2 Peer support specialist pre-survey (n=11 completed)

- Universal smartphone access with data plans; slight Apple majority (6 Apple, 4 Android, 1 other). [SURV-P]
- Very high smartphone comfort (10 of 11 at 4/4) but, like members, low current health-app use. [SURV-P]
- 10 of 11 view a health app as helpful. PSS are stably housed and employed — a distinctly different user profile from members, well positioned for the trainer/helper role envisioned in the proposal. [SURV-P]

### 3.3 CAB and protocol input

- Recruitment and communication must not assume voicemail use; text-accessible contact channels matter. Materials need high visual salience and large-font contact information. These same principles (visual clarity, large type, multiple contact modalities) carry into app design. [CAB]
- Survey administration experience showed participants completing forms on a mix of personal devices and center-borrowed devices — a preview of how the app itself will be used. [CAB]

### 3.4 Key lessons from the literature library

- **Data limits, not just ownership, break engagement.** Participants on government-issued phones frequently exhaust cellular data mid-month, degrading or disabling app use. [LIT: Deshais et al.]
- **Trust, privacy, and perceived surveillance are decisive adoption factors** for people who have experienced stigma or system surveillance. [PROP] [LIT: Whitehead; Ding et al.]
- **Digital literacy support must be actionable, not just measured** — pairing skill assessment with concrete matched supports (the Dwyer Technology Use Survey / Module Matching model). [LIT]
- **Perceived usefulness and ease of use drive adoption** (Technology Acceptance Model framing used in the Foundry BC qualitative work); tools that feel clinical, complicated, or monitoring-oriented are abandoned. [LIT: Ding et al.]
- **Peer co-design and co-leadership produce more relevant, trusted tools** and are feasible at every project stage. [LIT: Darcey et al.; Incze et al.; co-production principles papers]

---

## 4. Users and personas

**P1 — "Member with own Android phone" (primary persona).** 35–64, high school education or less, unemployed or receiving SSI/SSDI, housing unstable. Uses the phone daily for communication and social media but rarely for health. May run out of data. Comfort 3–4/4 but low confidence evaluating health information. Wants medication info, appointment help, and nearby resources.

**P2 — "Member without a personal phone."** Uses a center-borrowed device or occasional access. Cannot rely on persistent personal login, push notifications, or app-store installs on a personal device. Needs the app (or a companion mode) to work in short, assisted, shared-device sessions.

**P3 — "Lower-comfort member."** Owns a phone but rates comfort 2/4; uses apps rarely. Needs large targets, minimal navigation depth, plain language, and human help pathways.

**P4 — "Peer support specialist."** High digital comfort, employed at a CWC, often on iPhone. Uses the app both personally and as a *helper* — walking members through setup and tasks, running trainings. Needs a demonstration/training mode and the ability to help without accessing a member's private information.

**P5 — Research/administrative user (internal).** Study team members configuring resource directory content and, during Aim 3, capturing usability feedback.

---

## 5. Design principles

1. **Nothing about us without us.** All features in Section 6 are hypotheses to be confirmed, reprioritized, or replaced by focus group findings and Stakeholder Advisory Committee decisions. [PROP]
2. **Design for the worst connection, the cheapest phone, and the shared device.** [SURV-M] [LIT]
3. **Trust before features.** No feature ships if it undermines the plain-language privacy story. Collect the minimum, explain everything, never surprise the user. [PROP] [LIT]
4. **Peer support is a feature, not an afterthought.** Human help pathways are first-class UI elements. [SURV-M] [PROP]
5. **One thing per screen.** Cognitive and emotional accessibility: shallow navigation, consistent layout, forgiving interactions, no dead ends. [PROP]
6. **The app is a bridge, not a silo.** It links people to portals, providers, and places; it does not attempt to replace clinical systems or become a medical record. [PROP]

---

## 6. Feature requirements

Features are grouped into **MVP (alpha/usability-test build)** and **Post-MVP (refinement phase or future funding)**. Requirement IDs use the pattern *area-number*.

### 6.1 Home & navigation

- **HOME-1 (MVP).** Home screen presents at most four large, icon+label tiles corresponding to the app's core areas (working names: *My Health*, *Find Help Nearby*, *Learn*, *Get Help Using This App*). No carousel, no feed, no notifications center on v1 home. [PROP; P3] [PENDING FG — naming and grouping to be co-designed]
- **HOME-2 (MVP).** Maximum navigation depth of two taps from home to any core task.
- **HOME-3 (MVP).** Persistent, always-visible "back to home" affordance.

### 6.2 My Health (personal health organizer)

- **MYH-1 (MVP).** Appointment keeper: store provider name, date/time, location, phone number, and a free-text note; optional local reminder. Manual entry only in MVP (no EHR integration). [PROP: "storing names and dates of appointments with health providers"]
- **MYH-2 (MVP).** Medication list: name, what it's for (plain-language free text), dosage/schedule as entered by the user; optional reminder. Explicitly framed as a personal memory aid, not medical advice. [SURV-M: medications among top info needs]
- **MYH-3 (MVP).** My providers & portals: a personal list of care contacts with one-tap call and one-tap link to that provider's patient portal login page. The app links out; it never stores portal credentials. [PROP]
- **MYH-4 (MVP).** Wallet card: a single screen the user can show at an appointment (medications, providers, emergency contact). Works fully offline.
- **MYH-5 (Post-MVP).** Optional secure export/backup of My Health data (e.g., to a printout or file) to survive device loss — a real risk given housing instability. [SURV-M] [PENDING FG]
- **MYH-6 (Post-MVP, contingent).** Direct patient-portal integration (e.g., via SMART on FHIR) — out of scope for this award; candidate for the follow-on federal application. [PROP: future funding question]

### 6.3 Find Help Nearby (local resource directory)

- **FIND-1 (MVP).** Curated, study-team-maintained directory of local resources: pharmacies, clinics/FQHCs, urgent care, vaccination sites, CWCs themselves, and wellness supports; each entry has name, address, phone (tap-to-call and tap-to-text where available), hours, and a one-line plain-language description. [PROP] [CAB: text-accessible contact channels]
- **FIND-2 (MVP).** Directory is cached on-device and fully browsable offline; location features degrade gracefully to "browse by town/region" when GPS or data is unavailable. [SURV-M: data-plan gaps] [LIT: Deshais]
- **FIND-3 (MVP).** Filter by category and by region (North / Central / South NJ, matching the six study sites). [PROP]
- **FIND-4 (Post-MVP).** Additional social-determinant categories (food, transportation, benefits assistance) if prioritized by focus groups. [PENDING FG]
- **FIND-5 (MVP, admin).** Lightweight content-management path for the research team to update directory entries without an app-store release (remote config or hosted JSON pulled when connected).

### 6.4 Learn (vetted health information)

- **LRN-1 (MVP).** Library of short, plain-language entries in the six member-priority domains: physical health, mental health, nutrition, exercise/fitness, medications, preventive care. [SURV-M]
- **LRN-2 (MVP).** Every entry links only to vetted sources approved by the research team and advisory committee; sources are labeled ("From: CDC", etc.) to make trustworthiness visible. [PROP] [PENDING FG — trust markers to be co-designed]
- **LRN-3 (MVP).** All original text written at approximately a 6th-grade reading level; validated with readability tooling and advisory committee review. [PROP: literacy needs]
- **LRN-4 (MVP).** Entries cached for offline reading. [SURV-M]
- **LRN-5 (Post-MVP).** Optional read-aloud (text-to-speech) for entries. [P3] [PENDING FG]
- **LRN-6 (Explicitly deferred).** No AI chat/answer feature in the study build, despite survey evidence that some members already ask AI assistants health questions. Rationale: credibility-vetting is a core project value and an uncontrolled generative feature would undermine it. Revisit for future funding with guardrails. [SURV-M] [PROP]

### 6.5 Get Help Using This App (support layer)

- **HELP-1 (MVP).** Step-by-step tutorials with screenshots for every core task (add an appointment, find a pharmacy, etc.). [SURV-M: tutorial preferred by 7]
- **HELP-2 (MVP).** Short (≤90-second) video walkthroughs for the same tasks, downloadable at the CWC on Wi-Fi so they play offline. [SURV-M: video preferred by 10]
- **HELP-3 (MVP).** "Ask a Peer" pathway: prominent option that surfaces the user's CWC contact info and frames PSS as the go-to human help. [SURV-M: PSS preferred by 8] [PROP: peer-led training model]
- **HELP-4 (MVP).** PSS Helper Mode: a demonstration mode with sample data that a peer support specialist can use on their own phone (including iPhone) to walk a member through any task without viewing the member's real data. Doubles as the training-delivery vehicle for Aim 3 materials. [SURV-P] [PROP]
- **HELP-5 (Post-MVP).** Phone/chat support line integration if the project or CSPNJ can staff it. [SURV-M] [PENDING FG]

### 6.6 Onboarding, accounts, and shared-device use

- **ONB-1 (MVP).** First-run onboarding is skippable, under two minutes, and repeatable from settings. Collects nothing beyond an optional first name and optional PIN.
- **ONB-2 (MVP).** No account, email, or phone number required to use the app. All personal data stored locally on-device by default. [Design principle 3]
- **ONB-3 (MVP).** Optional PIN/biometric lock protecting the My Health area — important on shared, borrowed, or shelter-environment devices. [P2] [SURV-M: housing data]
- **ONB-4 (MVP).** Guest/kiosk mode for center-owned devices: full access to Find Help Nearby, Learn, and tutorials with no personal data retained between sessions. [P2] [CAB: borrowed-device pattern]
- **ONB-5 (Post-MVP).** Companion web version of the non-personal content (directory + Learn) for members without smartphones. [SURV-M: 15 of 40 without phone access] [PENDING FG — the focus groups should directly inform how the project serves non-phone-owners]

### 6.7 Accessibility & literacy (cross-cutting)

- **ACC-1 (MVP).** Minimum 18pt base body text with an in-app "larger text" toggle; respects OS-level font scaling. [CAB: large-font feedback]
- **ACC-2 (MVP).** Touch targets ≥ 48dp; high-contrast color palette meeting WCAG 2.1 AA; never color-only meaning.
- **ACC-3 (MVP).** All copy at ~6th-grade reading level; icons always paired with text labels. [PROP]
- **ACC-4 (MVP).** Full compatibility with TalkBack (Android) and VoiceOver (iOS).
- **ACC-5 (Post-MVP).** Spanish-language version — explicitly named in the proposal as future-scale work, not this award. [PROP]

### 6.8 Privacy, security, and trust (cross-cutting)

- **PRIV-1 (MVP).** Local-first data storage; no personal health data transmitted off-device in the study build. [Design principle 3]
- **PRIV-2 (MVP).** No advertising, no third-party analytics SDKs, no location tracking; any usage analytics for the study are opt-in, aggregate, and IRB-approved. [PROP] [LIT: surveillance mistrust]
- **PRIV-3 (MVP).** A one-screen, plain-language "How this app protects you" page reachable from home, co-written with the advisory committee. [PENDING FG — trust messaging to be co-designed]
- **PRIV-4 (MVP).** On-device data encrypted at rest using platform keystore; PIN-locked areas hidden from app-switcher previews.
- **PRIV-5 (MVP).** One-tap "erase my information" that fully clears personal data — supports shared devices and personal safety.

---

## 7. Platform & technical requirements

- **TECH-1.** Cross-platform framework (Flutter or React Native) targeting Android and iOS from one codebase, per the funded proposal; suitable for undergraduate ECE student development under Dr. Haghani. [PROP]
- **TECH-2.** **Android-first optimization**: minimum SDK supporting Android 8+ era budget and government-program devices; test matrix must include at least one low-RAM (~2GB) device. [SURV-M: 21 of 27 phones are Android] [LIT: Deshais]
- **TECH-3.** Installed app size target under ~40MB; no mandatory large downloads at first run; videos fetched only on Wi-Fi by user action. [LIT: data limits]
- **TECH-4.** Offline-first architecture: every MVP feature except live map/location and external links must function with no connectivity; content syncs opportunistically when connected. [SURV-M]
- **TECH-5.** Resource directory and Learn content delivered from a simple hosted content file the research team can edit (see FIND-5), avoiding app-store releases for content updates.
- **TECH-6.** Instrumentation for Aim 3 usability sessions (e.g., task-completion timing) must be a build-flag, present only in the research build, and disclosed in consent. [PROP: think-aloud and task-completion protocols]
- **TECH-7.** Open-source or low-cost licensing throughout, consistent with the sustainability commitment. [PROP: Questions Document §5]

---

## 8. Explicitly out of scope for this award

Symptom tracking or clinical assessment; diagnosis or treatment advice; EHR/portal credential storage or direct integration; messaging between members; social feeds; gamification/incentive systems; AI-generated answers; Spanish localization (deferred to future funding); crisis intervention functionality beyond static, vetted resource listings. Several of these (portal integration, Spanish version, AI with guardrails) are natural components of the follow-on federal or foundation proposal. [PROP]

## 9. Open questions for focus groups and the Stakeholder Advisory Committee

1. How should the app serve the ~40% of members without personal smartphones — companion web version, kiosk mode emphasis, center-device lending workflows, or something the team hasn't considered? [SURV-M]
2. What are the right names, icons, and groupings for the four core areas? (Co-design activity candidate.)
3. Which resource categories matter most beyond the health-service basics — food, transportation, benefits? [PENDING FG]
4. What specifically makes members trust or distrust a health app, and what visible trust markers follow from that? (Maps directly to existing focus group questions.) [PROP]
5. Do members want reminders/notifications at all, and if so how (given phone number changes and data limits)?
6. What do PSS need in Helper Mode to make peer-led training practical — and what should the Aim 3 training manual assume the app already teaches?
7. Should the wallet card / device-loss backup be prioritized higher given the housing-instability profile of the sample?

## 10. Traceability & next steps

Every requirement above is tagged to its evidence source, and [PENDING FG] items should be revisited as the thematic analysis of the 12 focus groups is completed (Aim 1, months 7–9). Suggested sequence: (1) advisory committee review of this draft, (2) update after focus group synthesis into v1.0 requirements, (3) low-fidelity wireframes of the four core areas for advisory committee co-design sessions, (4) Flutter/React Native framework decision and student development plan, (5) alpha build for internal testing per the project timeline (months 10–15).
