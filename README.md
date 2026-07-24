# CWC Health App

Navigation prototype (v1) for co-design feedback. Rutgers Scarlet chrome, four bottom tabs (**Nearby | My Health | Learn | More**), and a persistent **Help Now** control. All content is **static demo data** — no accounts, permissions, persistence, maps, or real calls/SMS.

## Run

```bash
flutter pub get
flutter run -d chrome          # quick desktop review
# or: flutter run -d <android|ios device id>
```

## What’s in this build

| Tab / screen | Demo behavior |
|--------------|---------------|
| Nearby | New Brunswick sample resources; category chips; map toggle placeholder |
| My Health | Sample appointments / meds / providers; wallet card screen |
| Learn | Six topics → short articles with source labels |
| More | List to placeholder pages; Erase → “Demo only” snackbar |
| Help Now | Full-screen support actions (demo only); emergency-card toggle UI |

## Project docs

- [`AGENTS.md`](AGENTS.md) — agent handoff
- [`CWC_Health_App/`](CWC_Health_App/) — requirements + design reference
- Figma: https://www.figma.com/design/yAwsNNegakKROue3o0CAMJ

## Feedback questions this prototype supports

- Can you find Nearby vs My Health?
- Is Help Now always one tap away?
- Does More feel like a visible list (not a hidden menu)?
- Does scarlet branding feel supportive or alarming?

Draft for co-design — nothing is final until the community says so.
