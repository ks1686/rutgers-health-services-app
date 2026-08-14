# PROJECT RUNDOWN — Zero-Context Handoff Document

**READ THIS FIRST.** This document exists so that any collaborator — human or AI agent — with **no prior context** can pick up this project. It is one of a three-document set that must travel together: this rundown explains *the project*, the feature specification (`01_...Specification_v0.4.md`) defines *what the app does*, and the design reference (`02_...Design_Reference_v1.1.md`) plus the linked Figma file define *what the app looks like*.

**Document name (canonical):** `00_PROJECT_RUNDOWN_CWC_Health_App.md`
**Last updated:** August 2026 (project month ~14 of 24) — rev 1.3: Flutter study build on `main` includes live Nearby (OSM, `LIVE_NEARBY`); Flutter chosen as the student track; next Nearby engineering is readable hours + FIND-4 map (not yet in spec as implemented).
**Companion documents:** `01_CWC_Health_App_Feature_Specification_v0.4.md` (requirements) · `02_CWC_Health_App_Design_Reference_v1.1.md` (visual design) · Figma design file: https://www.figma.com/design/yAwsNNegakKROue3o0CAMJ

---

## 1. One-paragraph summary

This is a funded, IRB-approved, two-year community-engaged research project at Rutgers University (June 30, 2025 – June 29, 2027, up to $40,000, Rutgers OVPR Behavioral Health and Equity Initiative pilot award). The team is co-designing a **smartphone app that centralizes health information and facilitates navigation of healthcare and wellness resources** for adults with mental health, substance use, and/or co-occurring physical health conditions who live in poverty — many currently or formerly unhoused. The work happens inside **Community Wellness Centers (CWCs)**: peer-run recovery centers operated by **Collaborative Support Programs of New Jersey (CSPNJ)** across northern, central, and southern New Jersey. The project has three aims: (1) needs assessment via focus groups with CWC members and peer support specialists, (2) co-design and iterative development of the app with undergraduate engineering students, and (3) usability testing, refinement, and development of peer-led training materials. As of August 2026, pre-surveys are analyzed, a v0.4 feature specification (with CAB open-question notes) and Final Design v1.1 (Rutgers Scarlet) are in hand, and the Flutter study build on `main` has the four-tab shell plus **live Nearby** (OpenStreetMap, flag-gated). Readable hours and the FIND-4 map view are the next Nearby engineering plans. Full qualitative synthesis to spec/design v1.0 is still ahead.

## 2. Formal project identity

- **Full title:** Facilitating Access to Digital Health Information for Individuals with Multifaceted Health and Social Needs: Smartphone App Co-design in Community Wellness Centers. (An earlier working title: "Facilitating Digital Access to Key Health Information in a High-need, Vulnerable Population Through Smartphone App Co-design in Peer Recovery Centers.")
- **Funder:** Rutgers Office of the Vice Provost for Research (OVPR), in collaboration with the Behavioral Health and Equity Initiative Provost Strategic Taskforce. Pilot award, up to $40,000 total costs, no indirect costs allowed, no food/drink, no investigator summer salaries.
- **Project period:** 06/30/2025 – 06/29/2027 (two years). Award notification: July 2, 2025.
- **IRB:** Rutgers eIRB protocol **Pro2025002116** (protocol version referenced on recruitment materials: v.2.11.5.2025). All recruitment materials, consent procedures, and surveys are IRB-approved. Participants receive **$50 gift cards** per session (focus group or usability session; also for training-pilot participants).
- **Institutional home:** Rutgers Institute for Health, Health Care Policy and Aging Research — Center for Population Behavioral Health (PI Sartor); budget administered via IFH/RBHS.

## 3. Team

**Principal / senior personnel (interdisciplinary by design — a funding requirement):**
- **Dr. Carolyn Sartor** — Corresponding PI. Psychiatry / population behavioral health (Institute for Health). Contact on recruitment materials: csartor@ifh.rutgers.edu.
- **Dr. Peggy Swarbrick** — Co-I. Psychiatric rehabilitation / wellness model; deep, longstanding partnership with CSPNJ and the CWCs; leads focus group facilitation ("Peggy" in protocols).
- **Dr. Amy Spagnolo** — Co-I. Psychiatric rehabilitation / peer workforce training; co-facilitator ("Amy" in protocols); co-leads training-material development with Swarbrick.
- **Dr. Sasan Haghani** — Co-I. Electrical & Computer Engineering. Supervises undergraduate ECE students who build the app; leads usability testing with students.

**Research assistants (students):** Samaa, Marley, Jada (Jada Padmore appears in data as a Rutgers test respondent). RAs run tech support, consent verification, survey administration, timekeeping, notes.

**Stakeholder Advisory Committee / Community Advisory Board (CAB):** trained peer support specialists with lived experience who have collaborated with Swarbrick/Spagnolo previously. Named members in attendance records and letters of collaboration: **Adam Chrone, Vincent DiGioia-Laird, Arielle Estes, Lasheema Sanders-Edwards** (Sanders-Edwards is also a PSS survey respondent). The CAB meets monthly (standing: first Wednesday, 2pm) and is a **decision-making co-design body**, not an advisory formality — they shape recruitment, protocols, analysis, feature prioritization, training materials, and dissemination.

**Partner organization:** Collaborative Support Programs of New Jersey (CSPNJ), which operates the CWCs (https://cspnj.org/cause/cwc/). CSPNJ staff emails use @cspnj.org. CSPNJ also operates NJ peer warmline services (relevant to the app's "Help Now" feature).

## 4. Population and setting

- **Members:** adults (18+) with lived experience of mental health and/or substance use challenges who have used CWC support services 3+ times. Overall CWC membership demographics cited in the proposal: 58% male, 52% Black, 36% White, 9% Hispanic, 3% other. Many members are unhoused or precariously housed and live below the poverty line.
- **Peer Support Specialists (PSS):** people with lived experience, trained and employed at CWCs to deliver peer support.
- **Sites:** six CWCs across NJ's three regions. Candidate/selected centers discussed at CAB: Paterson/Passaic, Better Life, Plainfield, Jersey City, New Brunswick, Camden, Cape May.
- **Inclusion criteria:** 18+, cognitive ability to consent, sensory ability to engage with app use, English-speaking (Spanish version deferred to future funding).

## 5. Aims and methods

**Aim 1 — Needs assessment.** Focus groups with members and PSS to identify (a) *content* needs: personal health information access (e.g., patient portals), local health resources, other health-supporting information; and (b) *app design* needs: usability, functionality, trust. Planned scale: 12 focus groups across 6 sites, 6–8 participants each (~84 total), mixing members and PSS. $50 gift cards. Sessions audio-recorded, transcribed verbatim, de-identified.

*Protocol reality vs. plan:* the proposal specified in-person groups at CWCs; the team also developed and ran a **virtual (Zoom) protocol** (waiting room, host-only cloud recording, e-consent link in chat with breakout-room support for anyone struggling, Qualtrics pre-survey completed at registration or in-session, RA-run tech support, incentive tracking for e-gift cards). Facilitation: Swarbrick leads, Spagnolo co-facilitates/probes, RAs handle logistics. Recruitment adjustments per CAB: center managers sign members up (cap ~6/group), info sheets instead of call-to-confirm, high-visibility flyers with large-font, text-accessible contact info. Documented sessions include PSS groups on 2/7/2026, 2/23/2026, 2/27/2026, and a virtual PSS group 4/10/2026 (per flyer).

*Pre-focus-group survey (Qualtrics):* demographics (education, work, student status, housing, gender identity, age band, Hispanic/Latino identity, English first language) plus technology access/use (smartphone access, borrowed access, phone type, data/internet, app frequency, health-app frequency, 1–4 comfort), health-information behavior (whether/what/where/how often they seek, 1–4 confidence), and app receptivity (would an app help; members additionally: would they like help using one and preferred help formats).

*Analysis:* collaborative thematic analysis — inductive + deductive coding, codes refined by consensus, themes grouped; deliberately manual (no NVivo dependency) so CAB members without formal training can fully participate. Theme areas pre-specified: information types sought; barriers to finding/understanding/trusting digital health resources; navigating local services; technology comfort and feature preferences; trust/engagement factors; content/layout/functionality suggestions.

**Aim 2 — App development.** Undergraduate ECE students (independent study, supervised by Haghani) build a cross-platform app (Flutter or React Native, Android + iOS) in an agile, iterative cycle, with prototypes driven by Aim 1 findings. Alpha testing is internal (team + CAB). See the companion feature spec for the current requirements draft.

**Aim 3 — Usability testing + training materials.** Structured ~60-minute usability sessions (think-aloud protocols, task-completion assessments) with 2 groups of 6–8 per site (total n≈84), led by Haghani + students; audio-recorded and transcribed. Findings drive app refinement. Then Swarbrick/Spagnolo + CAB develop a peer-led training framework and materials (manuals, in-person and virtual modalities); a 60-minute pilot training at each site (3–4 PSS/site, n≈20, $50 gift cards) generates feedback; materials are revised and CAB-approved. Rationale: training delivered by trusted peers, not external experts, to maximize uptake and sustainability.

**Timeline (months from 06/2025):** M1–3 team/IRB/CAB/recruitment prep · M4–6 focus groups · M7–9 thematic analysis + needs report · M10–12 Aim 1 dissemination (abstracts, manuscript) · M10–15 app development + alpha · M16–18 usability testing · M19–21 refinement · M21–24 training materials + pilot + Aim 2 manuscript. **As of July 2026 (~M13):** the project is roughly on the boundary of Aim 1 analysis and Aim 2 development; focus groups ran Feb–Apr 2026, slightly later than the M4–6 plan.

**Budget notes:** ~$40K total; includes participant incentives (~168 × $50 across focus groups + usability, plus ~20 training pilots), conference travel in year 2 (~$6K), no F&A. Non-federal fringe rates apply (Rutgers template).

## 6. Strategic context (from the funded Questions Document)

The project's innovation claims, useful for framing any downstream writing: (1) interdisciplinary academic team (engineering + psychology/psychiatric rehab + peers as "cultural and contextual translators"); (2) community members as co-designers and decision-makers, not subjects; (3) engineering students engaging directly with the communities their tools serve; (4) an app designed *with a peer-led training model in mind* from day one; (5) a scalable, sustainable model — replicable in other peer-run centers, open-source/low-cost deployment. The team's origin story: Sartor and Swarbrick connected around digital wellness tools when Sartor joined the faculty; the May 6, 2025 BHE Forum catalyzed the collaboration; Haghani was recruited when the need for an app developer became clear. **Future funding:** this pilot is explicitly positioned to seed a larger federal (e.g., NIH) or foundation application — likely including portal integration, a Spanish version, and broader deployment.

## 7. What the data shows so far (descriptive analysis of pre-surveys, June 2026 exports)

**Members (n=41 rows; 40 completed):**
- Smartphone access: **25 yes / 15 no** — a ~38% access gap, far larger than published comparison samples (~86% ownership in Deshais et al.). Most without phones also lack borrowed access.
- Phone type (owners): **21 Android / 6 Apple**; a few without data plans/internet.
- Comfort (1–4): 15 at "4", 8 at "3", 4 at "2" — capable majority, meaningful low-comfort tail.
- Health-app use: modal answer "Rarely"/"Never" even among daily smartphone users.
- Housing: 11 rent, 10 sheltered-unhoused, 10 unsheltered-unhoused, 6 with family/friends, 3 other → **~half unhoused**.
- Age: concentrated 35–64 (55–64 largest band, n=13).
- App receptivity: **24 of 27 answering said yes**, an app would help.
- Top info needs: physical health (17), mental health (15), exercise/fitness (11), nutrition (10), medications (10), preventive care (9).
- Preferred help formats: video walkthrough (10), peer support specialist (8), step-by-step tutorial (7), in-person workshop (6), phone/chat support (5).
- Notable write-ins: several already ask AI assistants (ChatGPT etc.) health questions; one names a specific center resource specialist as their information source.

**Peer Support Specialists (n=15 rows; 11 completed):**
- Smartphone access universal (11/11), all with data; **6 Apple / 4 Android / 1 other** — opposite platform skew from members.
- Comfort: 10 of 11 at "4". Health-app use still low ("Rarely" modal).
- 10 of 11 say an app would help. All stably housed, employed full/part-time; ages skew 45+.

**Data quality cautions for any agent doing analysis:** Qualtrics exports have **three header rows** (variable name, question text, import ID) — drop rows before analysis. Filter on `Finished == True`; there are partial/duplicate attempts (same person restarting, e.g., Aubrey Powell, Luis Morales, Christopher Royster, Sharon Taylor appear twice with differing answers — the later completed record is likely the valid one, but flag rather than silently choose). Some responses came from Rutgers/test contexts (e.g., a Rutgers RA's own response) and batches share IP addresses because they were completed together on center devices — do not treat IP as a person identifier. Dates are Excel serial numbers (e.g., 46094 ≈ March 2026).

**⚠️ PRIVACY:** The survey exports contain **identifiable participant information** (names, emails, IPs, coarse geolocation). These files are IRB-governed research data. Do **not** paste raw rows into external tools, share outside the study team, or include identifiers in any derived document. Any agent processing these files should work with de-identified aggregates only. (This rundown intentionally reports aggregates; the handful of names it mentions are team members, CAB members who signed public-facing letters of collaboration, or flagged duplicates the team must adjudicate internally.)

## 8. Evidence library (what's in the project folder and why it matters)

The folder includes a curated literature set. The load-bearing lessons:
- **Deshais et al., wellness-enhanced contingency management (DIGITAL HEALTH):** closest comparison sample; 86% smartphone ownership, Android-dominant, government-phone **data limits break engagement** mid-month; participants endorse wellness apps.
- **Dwyer et al. (Community Mental Health Journal, two papers):** Technology Use Survey + Module Matching Guide — digital-literacy assessment must lead to *actionable, matched supports*; model for the app's help layer and Aim 3 training.
- **Ding et al. (mHealth adoption, Foundry BC):** Technology Acceptance Model — perceived usefulness + ease of use drive adoption; qualitative co-design methodology template.
- **Whitehead et al.:** barriers/facilitators to digital health for this population — trust, privacy, surveillance concerns are decisive.
- **Darcey et al. (App 4 Independence), Incze et al. (CONNECT):** models for digital-tool co-design with people with SUD and community-engaged research network structure.
- **Co-production principles; lived-experience co-leadership; CBPR papers; Hellman qualitative-quality criteria; Moncada NVivo-vs-Excel:** methodological grounding for the CAB's co-analysis approach.
- **Health Affairs (threat to digital access programs); social prescribing; JAMA Psychiatry viewpoint (Bhui):** policy context — broadband/device subsidy programs and NIH equity funding are under threat, which strengthens the case for offline-capable, low-cost design and for the app as equity infrastructure.
- **Manuscript_submission_822025.docx:** the team's related manuscript (Deshais/Swarbrick collaboration on wellness-enhanced CM interviews/focus groups) — reusable methods language and the comparison statistics above.

## 9. File inventory (project folder, by function)

- **Funding/administrative:** `BHE_RFP_.pdf` (the RFP), `01_BHE_RFP_Overview_Doc.docx`, `01_BHE_RFP_Research_Narrative.docx`, `BHEI_proposal.pdf` (funded proposal), `02_BHE_Research_Timeline.docx`, `03_BHE_Budget_Justification.docx`, `BHE_Budget.xlsx` / `04_BHE_Budget.xlsx`, `05_BHE_Questions_Document.docx`, `06_BHE_Research_Team_Document.docx`, `Sartor_pilot_award_letter_07022025.pdf`.
- **Team credentials:** biosketches for Sartor, Swarbrick, Spagnolo, Haghani (`04_a`–`04_d` and duplicates).
- **Community partnership:** letters of collaboration `07_LOC_*` (Estes, DiGioia, Chrone, Sanders-Edwards), `TeamNotes_CAB_8_6_25.docx`, `CAB_meeting_attendance.xlsx`.
- **Data collection instruments/materials:** `Virtual_Focus_Group_Protocol_and_Script_2-4_.docx`, `Virtual_PSS_Focus_Group.pdf` (flyer), `Final_Sartor_Flyer__PSS_Focus_Group_1.png` (flyer).
- **Data (IDENTIFIABLE — handle per §7 caution):** `Peer_Support_Specialist__Registration_and_Focus_Group_PreSurvey_June_30_2026_08_14.xlsx`, `Wellness_Community_Center_Member__Focus_Group_PreSurvey_June_30_2026_08_09.xlsx`.
- **Literature:** all remaining PDFs (`Articles_of_Interest.docx` is the reading list).
- **Design outputs (this workstream):** `00_PROJECT_RUNDOWN_CWC_Health_App.md` (this file), `01_CWC_Health_App_Feature_Specification_v0.4.md` (v0.1–v0.3 superseded in `archive/`), `02_CWC_Health_App_Design_Reference_v1.1.md`, and the Figma design file "CWC Health App" (https://www.figma.com/design/yAwsNNegakKROue3o0CAMJ) containing the lo-fi wireframes (page 00) and the presentation-ready Final Design v1.1 (Rutgers Scarlet) (page 01) with spec-traceable captions.

## 10. App design status (summary — the spec is authoritative for behavior, the Figma file for visuals)

Current concept, per `01_CWC_Health_App_Feature_Specification_v0.4.md`. The visual design is complete through **Final Design v1.1 (Rutgers Scarlet)** in the Figma file (https://www.figma.com/design/yAwsNNegakKROue3o0CAMJ): five hi-fi screens, cover banner, evidence panel, and requirement-ID captions; design tokens and screen-to-spec mapping are in `02_CWC_Health_App_Design_Reference_v1.1.md`. Feature summary:
- **Architecture:** bottom tab bar **Nearby | My Health | Learn | More** (no hamburger/drawer — explicit design rule), plus a persistent **Help Now** button in every screen header.
- **Nearby** (default landing): curated, offline-cached NJ resource directory; region/town picker primary, optional GPS shortcut; list-first with walk-time distances; optional OpenStreetMap map view.
- **My Health:** manual appointment keeper, medication list, providers/portal links (link-out only, no credentials), offline wallet card.
- **Learn:** vetted, source-labeled, ~6th-grade-reading-level entries in the six member-priority domains; offline; no AI answers in study build (explicitly deferred).
- **Help Now:** one tap everywhere, never PIN-blocked, fully offline; 988 (call+text), 911, Poison Control, member's CWC, NJ peer warmline; optional member emergency card (off by default).
- **More:** tutorials + ≤90s videos (Wi-Fi-downloadable), Ask a Peer, PSS Helper Mode (demo data for peer-led training), settings, plain-language privacy page, one-tap erase.
- **Foundations:** no accounts; local-only encrypted data; optional PIN (never gating Nearby/Learn/Help Now); guest/kiosk mode for center devices; Android-first (budget devices, <~40MB, offline-first); **Flutter** (this repo); remote-config content updates; WCAG 2.1 AA, 48dp targets, 18pt+ text, TalkBack/VoiceOver.
- **Study-build note (not a FIND-1 rewrite):** Nearby in the Flutter app can load live OSM pharmacies/clinics (`LIVE_NEARBY`). The funded MVP narrative is still a curated directory. Map tiles (FIND-4) are specified but not built — the toggle is a placeholder. Details: `docs/engineering/nearby-live-data.md`.
- **Evidence tagging convention:** [PROP] proposal · [SURV-M]/[SURV-P] surveys · [CAB] advisory board · [LIT] literature · [TEAM] design-discussion decisions · **[PENDING FG]** = must be confirmed by focus-group findings. Treat every [PENDING FG] item as a hypothesis, not a decision.

## 11. Open questions and immediate next steps

**Open questions (full list in spec §9):** serving the ~40% of members without smartphones (incl. CAB interest in a simple website path); tab naming/icon co-design; Help Now contents ("what would you want one tap away?"); resource categories beyond health services; distance/travel framing; trust markers and location-permission wording; notification appetite (CAB recovery/appointment reminder interest vs. local-only study build); PSS Helper Mode / group-intro + check-in training needs; wallet-card priority.

**Next steps:** (1) CAB review of spec v0.4 + the Final Design v1.1 (Rutgers Scarlet) screens (wireframes and hi-fi design are DONE — see §10); (2) complete focus-group thematic analysis and update spec + design to v1.0; (3) Nearby engineering on the Flutter study build — readable hours on live cards, then FIND-4 OSM map (spec already requires the map; it is not implemented); (4) physical Android (and iOS) smoke of Call / Text / Directions; (5) verify the NJ peer warmline number/hours directly with CSPNJ before it ships in any build; (6) Aim 1 dissemination (conference abstracts, manuscript).

## 12. Ground rules for any agent joining this project

1. **The community decides.** Do not present design choices as final; everything is subject to CAB and focus-group input. Preserve the [PENDING FG] flags.
2. **Protect participant data** (§7 caution). Aggregates only; no identifiers in outputs.
3. **Match the project's values in any artifact you produce:** plain language (~6th-grade), offline-first, Android-first, no dark patterns, no unnecessary data collection, peer support as a first-class feature.
4. **Cite your evidence.** Continue the source-tagging convention when adding requirements or claims.
5. **Version, don't overwrite.** New spec revisions get a new version number and a change note; the rundown gets its "Last updated" line refreshed.
6. **Scope discipline.** This award ends 06/29/2027 at ≤$40K with student developers. Portal integration, Spanish localization, AI features, and clinical functionality are out of scope here and belong in the follow-on grant narrative.
