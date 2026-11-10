# CWC Health verification map

This directory is the maintained source for verifying the member-facing behavior of the CWC Health App. Read this index, then use the matching feature file.

## Baseline preconditions

- The study targets are Android and iOS. The helper on a Linux machine launches the Flutter web stand-in described in `../SKILL.md`.
- Run `verify-cwc launch`, then `verify-cwc doctor`, and require `ok: yes` before any drive.
- Run `verify-cwc browser start` so the session is on **Before you continue**. Acknowledging the disclaimer lasts for that browser tab only. A reload or a new tab shows it again.
- My Health starts empty in a new browser context. Do not reuse Chrome's everyday profile.
- Launch passes `HELP_NOW_LIVE=false` so Help Now says calling is turned off in this build. `SHOW_SESSION_QUESTIONS` is false, so **Session questions** is absent. `HELP_NOW_UNCONFIRMED` is false, so **NJ Peer Warmline** and **My Wellness Center** are absent.
- Launch prints a new run id. Export it before doctor, browser, and cleanup. Two runs also need different ports. Never drive a Flutter process this run did not start.

## Driving conventions

- Start every recipe from the disclaimer unless that file says the session is already past it.
- Prefer the accessibility role and accessible name. `ValueKey`s are for widget tests and are not in the web DOM.
- Treat every command as literal. Keep the quoted names unchanged.
- Run the commands through `.cursor/skills/verify-cwc-health/scripts/verify-cwc`.
- The helper viewport is 430 by 1200 CSS pixels. Scroll a Flutter list with `browser scroll-into-view` when a line sits below the fold.
- Cleanup removes the temporary app and the browser. It does not remove the evidence directory.

## Proof and skip reporting

- Capture the member action and the resulting state, not only the last screen.
- UI proof is an accessibility snapshot plus a screenshot. The snapshot header includes the title `CWC Health App`.
- A saved health record is proved by reloading, acknowledging the disclaimer, and reading the record back.
- Help Now is proved by the row names and their order. Do not press a row. The Android dialer is outside this helper.
- Record the feature id and the entry point with the snapshot (`--feature`).
- Report an unreachable path with the command you ran and the unmet precondition. A failed Nearby lookup is a failure. Do not switch the assertion to the error text.
- Do not report a skipped phone entry point as verified through the web stand-in.

## Feature entry contract

Each feature file starts with an H1 and one paragraph, then these four H2 sections in order.

1. `Sub-features`
2. `How to get to it (user POV)`
3. `Driving it with verify-cwc`
4. `Gotchas`

## Features

- [Learn a topic](./learn.md) covers the cold-start disclaimer, the six Learn tiles, a topic note, and a sourced article.
- [Help Now](./help-now.md) covers the header entry and the row names in order. It does not press a row.
- [My Health medication](./my-health.md) covers an empty list, saving a medicine, and seeing it after a reload.
- [Nearby places](./nearby.md) covers the remembered town, a live place list, and the unvetted-maps notice.
- [More](./more.md) covers the More list, the privacy page, and cancelling erase.
