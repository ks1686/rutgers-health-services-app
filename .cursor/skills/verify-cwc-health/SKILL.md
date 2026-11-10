---
name: verify-cwc-health
description: "Drive the CWC Health App (Flutter, Android and iOS study build) the way a member does, and capture evidence. Use for verify-cwc, a UI proof of Nearby, My Health, Learn, More, or Help Now, or when a change needs a real launch instead of widget tests."
---

# Verify CWC Health

The study build is a Flutter phone app. Members use four tabs (Nearby, My Health, Learn, More) and a Help Now button on every header. There is no account. Personal health data stays on the device. Cold start always shows **Before you continue**, then opens My Health.

This skill's helper drives a Flutter web stand-in, because that is the surface a Linux checkout can click. Android and iOS are the real targets. Their steps are below and stay unverified until a run on a simulator or phone does them. Do not treat a green web run as a phone run.

Package `cwc_health_app`. Android application id `org.rutgers.cwc.cwc_health_app`. iOS bundle id `org.rutgers.cwc.cwcHealthApp`. CI Flutter is 3.47.8 (`.github/workflows/flutter-ci.yml`).

## Launch

One instance per `CWC_VERIFY_RUN_ID`. Launch creates a new id when that variable is unset and prints `run_id:`. Doctor, browser, and cleanup refuse to run until you export that id. There is no shared default id. The default port is `8773`. A second run needs its own port. Each run copies tracked files to a temp directory, copies the web scaffold into that copy only, and starts Flutter there. The product tree has no `web/` folder and must not gain one. `flutter create` rewrites `pubspec.lock` and `analysis_options.yaml`, so the helper never runs it.

From the repo root:

```bash
.cursor/skills/verify-cwc-health/scripts/verify-cwc launch
```

Useful environment:

- `CWC_VERIFY_RUN_ID` isolates the process, port, and browser storage. Export the `run_id:` line from launch.
- `CWC_VERIFY_PORT` is the web port. Default `8773`.
- `CWC_VERIFY_EVIDENCE` is the proof directory. When unset, launch creates a private directory with `mktemp` (mode 700). Cleanup never deletes it.
- `CWC_VERIFY_REPO` defaults to this repo.

Launch is finished only when a headless Chrome session can see **Before you continue** and **I understand**. HTTP 200 by itself is not ready. The helper passes `HELP_NOW_LIVE=false`, `HELP_NOW_UNCONFIRMED=false`, and `SHOW_SESSION_QUESTIONS=false`. `HELP_NOW_LIVE=false` changes the Help Now sentence. The row buttons still have phone URLs in app code, so the helper never presses them and drops `tel:` and `sms:` `window.open` calls.

The helper needs `flutter` on `PATH` (3.47.8), `node`, `python3`, `tar`, `curl`, and Google Chrome. It treats a LISTEN socket in `/proc/net/tcp` as a busy port even when the holding process cannot be inspected. The first launch runs `npm ci` in the run's private state directory for `playwright-core`. It does not install `node_modules` into the repo. Flutter and Chrome use a private `HOME` under that state directory.

### Android emulator (real target, unverified on a Linux VM without an emulator)

```bash
flutter emulators
flutter emulators --launch <emulator id>
flutter run -d android
```

Ready when **Before you continue** is on screen. Do not `adb shell pm clear` a device this run did not boot. Do not drive a phone that already has a member's data. TalkBack reads the same visible labels this skill clicks. There is no Enable accessibility control on Android.

### iOS Simulator (real target, needs a Mac)

Follow `docs/engineering/ios-simulator.md`. Short form:

```bash
scripts/smoke.sh --ios
xcrun simctl boot "iPhone 18 Pro"
flutter install -d "iPhone 18 Pro"
xcrun simctl launch booted org.rutgers.cwc.cwcHealthApp
```

Ready when **Before you continue** is on screen. The simulator has no cell radio. A `tel:` tap cannot prove a phone would dial.

### What the web stand-in does that a phone does not

- Adds `web/` only inside the run's state directory (`<state home>/<run id>/app`) from `scripts/web-scaffold/`. The default state home is `cwc-verify-<uid>` under `XDG_RUNTIME_DIR`, or under `/tmp` when that is unset. That folder is verification scaffolding. Do not commit it as `web/` at the repo root.
- Serves `flutter run -d web-server --release`. Debug mode on this VM stopped on the HTML shell while DDC was still loading scripts, so the disclaimer never appeared. Release mode is the same member UI and is the bundle the helper waits on.
- Clicks the Flutter placeholder `flt-semantics-placeholder` by dispatching a DOM click. The placeholder is 1 pixel at `(-1, -1)`, so a normal Playwright click never lands. Phones expose semantics to TalkBack and VoiceOver without that click.
- Uses a 430 by 1200 CSS pixel viewport so a Learn note fits. The HTML page does not scroll. Flutter scrolls inside the view.
- Drops `tel:` and `sms:` `window.open` calls inside the page. Other opens still go to the browser. A phone opens its own dialer when a member presses a row. This helper does not press those rows.
- Stores My Health in the browser origin for that port once Save has written the record. A reload in the same browser keeps that record. That is not Android Keystore or iOS Keychain. The Dose / schedule box is multiline. The helper types into it and leaves the field, because assigning the semantics value does not reach the form and Save then stops.

## Doctor

Run this before the first drive, and again after anything surprising.

```bash
.cursor/skills/verify-cwc-health/scripts/verify-cwc doctor
```

It is read-only. Exit 0 prints `ok: yes`. It checks the Flutter pid this run started, that the port's listener is still that process or a child of it, HTTP 200, the recorded git SHA against the checkout, the Flutter version line captured at launch, and that launch already saw the disclaimer. The app has no account (`auth: none`). A wedged screen can still pass doctor. If a drive fails and doctor is healthy, run `verify-cwc browser start` only when the old browser is gone, or `verify-cwc cleanup` and launch again. Do not keep clicking a session you have not health-checked since it last misbehaved.

## Drive

The helper keeps one Chrome tab open. A new tab starts the Dart app over, so the disclaimer returns. Widget `ValueKey`s (`tab-learn`, `nearby-town-chip`, and the rest) are for `flutter test` and `integration_test`. They are not DOM ids. On the web stand-in, click the accessibility role and accessible name.

```bash
V=.cursor/skills/verify-cwc-health/scripts/verify-cwc
$V browser start
$V browser click --role button --name "I understand"
$V browser click --role tab --name "Learn"
$V browser expect-text --text "Physical Health Everyday care for your body."
$V browser snapshot --path "$CWC_VERIFY_EVIDENCE/learn/topics.aria.txt" --feature learn
$V browser screenshot --path "$CWC_VERIFY_EVIDENCE/learn/topics.png"
```

Commands:

- `browser start` opens the app and enables semantics. The disclaimer is showing.
- `browser click --role ROLE --name NAME` uses an exact accessible name. `--contains` switches to a substring. `--within-role` and `--within-name` scope the click (the within name is a substring). After the element matches, the helper reads its rendered accessible name. Exact and `--contains` both refuse a phone or text row. That includes 911, 988, and any row whose rendered name says it opens your phone, such as Poison Control when the request only contains that label.
- `browser expect-order --text A --text B` waits until those strings appear in that order in the accessibility tree.
- `browser opens` prints `tel:` and `sms:` URLs the page tried to open. A run that did not press a phone row prints `(none)`.
- `browser fill --role textbox --name NAME --value VALUE` clicks the field, types the value, and leaves the field so a multiline Flutter box keeps the text.
- `browser expect-text --text TEXT` polls the accessibility tree for up to 10 seconds.
- `browser expect-absent --text TEXT` waits until the text is gone. Use it after a navigation that should remove the previous screen.
- `browser snapshot` and `browser screenshot` write only inside this run's evidence directory. The helper resolves symlinks and refuses a path that leaves that directory.
- `browser scroll-into-view --text TEXT` wheels the Flutter list until that text's box sits in the viewport.
- `browser reload` reloads the page, enables semantics again, and waits for the disclaimer. Storage for that origin is kept. The in-memory disclaimer acknowledgement is not.

Match names from the feature file. Do not click by coordinates.

## Evidence

Write proofs to the evidence directory launch printed (`evidence:`). When `CWC_VERIFY_EVIDENCE` is unset, `mktemp` creates a mode 700 directory that is not derived from the run id. When it is set to an existing directory, that directory must already be owned by you and not writable by the group or others. The helper does not change its mode. Files written there are mode 600.

A proof shows the action and the resulting state. For a screen, save an accessibility snapshot and a screenshot. The snapshot header includes the page URL and title `CWC Health App`. For a save, reload with `browser reload`, acknowledge the disclaimer again, and read the value back from My Health. For Help Now, record the row names and their order. Do not press a row. Do not place a 911, 988, or poison-control call.

Mocks are not used. Nearby calls the real Overpass servers. If the list fails to load, the run fails. The error text is not a pass.

## Cleanup

```bash
.cursor/skills/verify-cwc-health/scripts/verify-cwc cleanup
```

Cleanup reads the state file as data. It deletes the run directory only when that file is present, parses, and names this run. A directory with no `run.env` from this helper is left in place. Tool paths, the isolated home, and the Flutter binary are taken from the state directory and the current `PATH`, not from values stored in the file. It signals the browser pid and the Flutter pid only when the command line, the owner, and the start time still match the process this run started. On Linux the start time comes from `/proc`. Without `/proc` it comes from `ps -o lstart=`. It signals the process group only when that pid is still the leader of that same process. It does not signal an unrelated pid. It copies `flutter.log` into the evidence directory first. It does not delete the evidence directory, and it does not kill processes by name.

After cleanup, confirm the snapshot and screenshot are still in the evidence directory.

## Helpers

Both files live in `.cursor/skills/verify-cwc-health/scripts/`.

- `verify-cwc` is the command above. It is executable.
- `browser-daemon.mjs` is the Chrome session. `verify-cwc` calls it. Do not invoke it yourself.
- `check-regressions.sh` checks the run id, cleanup, evidence paths, and phone-open guards.
- `web-scaffold/` is the temporary `web/` tree. `scripts/web-scaffold/SCAFFOLD.txt` says why it exists.

`npm ci` runs in the private state directory when `playwright-core` is missing. `scripts/package.json` pins `playwright-core`. The helper removes `scripts/node_modules` if it is present so the package tree stays out of the repo.

## Feature map

Read `features/README.md`, then the feature file. One convenient screen is not a substitute for the others. Drive the entry points that file lists.

## Maintenance

When the app changes, run `/maintain-verification-skill` against `.cursor/skills/verify-cwc-health/`. Update this skill when a label, route, or launch command drifts. Do not paper over a product bug by weakening a journey.
