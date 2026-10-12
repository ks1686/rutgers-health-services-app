#!/usr/bin/env bash
#
# Pre-CAB smoke check for the CWC Health App.
#
# Runs the same gates as CI (format, analyze, tests), builds the live-Nearby
# release APK, then prints the short manual checklist for the phone walkthrough.
#
#   scripts/smoke.sh                 # everything
#   scripts/smoke.sh --skip-build    # gates only, no APK
#   scripts/smoke.sh --skip-format   # ignore local/CI formatter version drift
#   scripts/smoke.sh --help
#
# Safety: HELP_NOW_LIVE defaults to false. In a meeting room a tap must not open
# the 911 dialer. Set HELP_NOW_LIVE=true only when Karim wants real Help Now
# dialing in that specific room.
#
# Exit code is non-zero if any step fails, so CI or a hook can call this.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

LIVE_NEARBY="${LIVE_NEARBY:-true}"
HELP_NOW_LIVE="${HELP_NOW_LIVE:-false}"
APK="build/app/outputs/flutter-apk/app-release.apk"
SMOKE_DOC="docs/engineering/cab-demo-smoke.md"

skip_build=0
skip_format=0

for arg in "$@"; do
  case "$arg" in
    --skip-build)  skip_build=1 ;;
    --skip-format) skip_format=1 ;;
    -h|--help)     sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg (try --help)" >&2; exit 2 ;;
  esac
done

step=0
run_step() {
  step=$((step + 1))
  printf '\n\033[1m[%d/%d] %s\033[0m\n' "$step" "$TOTAL_STEPS" "$1"
}

# 4 steps when building, 3 when not.
if [ "$skip_build" -eq 1 ]; then TOTAL_STEPS=3; else TOTAL_STEPS=4; fi

echo "CWC Health App — pre-CAB smoke"
echo "repo:    $(git rev-parse --short HEAD 2>/dev/null || echo 'not a git checkout')"
echo "flutter: $(flutter --version 2>/dev/null | head -1)"
echo "defines: LIVE_NEARBY=$LIVE_NEARBY HELP_NOW_LIVE=$HELP_NOW_LIVE"

command -v flutter >/dev/null 2>&1 || { echo "flutter not found on PATH" >&2; exit 1; }

# ---------------------------------------------------------------- format
if [ "$skip_format" -eq 1 ]; then
  printf '\n\033[1m[format] skipped by flag\033[0m\n'
else
  run_step "Check Dart formatting"
  # CI pins Flutter 3.44.7. A newer local SDK may reformat files CI considers
  # correct (see commit 398694a). If only that shows up, re-run with --skip-format
  # and let CI be the judge.
  dart format --output=none --set-exit-if-changed .
fi

# ---------------------------------------------------------------- analyze
run_step "Analyze (flutter analyze --fatal-infos)"
flutter analyze --fatal-infos

# ---------------------------------------------------------------- test
run_step "Unit and widget tests (flutter test)"
# Deliberately no --dart-define=LIVE_NEARBY here. Three tests assert the flag
# defaults off and that the fake demo listings render; live mode is supposed to
# hide that demo data, so those failures are by design.
flutter test

# ---------------------------------------------------------------- build
if [ "$skip_build" -eq 0 ]; then
  run_step "Build live-Nearby release APK"
  flutter build apk --release \
    --dart-define=LIVE_NEARBY="$LIVE_NEARBY" \
    --dart-define=HELP_NOW_LIVE="$HELP_NOW_LIVE"
fi

# ---------------------------------------------------------------- report
echo
echo "=============================================================="
if [ "$skip_build" -eq 0 ]; then
  echo "Gates passed. Install file:"
  echo "  $APK"
  echo "  size:  $(du -h "$APK" | awk '{print $1}')"
  if command -v shasum >/dev/null 2>&1; then
    echo "  sha256: $(shasum -a 256 "$APK" | cut -c1-64)"
  fi
  echo
  echo "LIVE_NEARBY is compiled in. Nearby must show real places and the"
  echo "line 'They are not checked by our team.' If you see the sample"
  echo "'Main Street Pharmacy' list, this is the wrong APK — do not use it."
  if [ "$HELP_NOW_LIVE" = "false" ]; then
    echo
    echo "HELP_NOW_LIVE=false: Help Now buttons show the demo-only line and"
    echo "do NOT open the dialer. Nearby Call/Text/Directions do launch."
  fi
else
  echo "Gates passed. APK build skipped."
fi
echo "=============================================================="

cat <<CHECKLIST

Phone walkthrough (full version: $SMOKE_DOC)
  [ ] Uninstall any older CWC Health App first. Each build is signed with a
      new debug key, so an in-place upgrade can fail.
  [ ] Install, open. First launch shows "Before you continue" -> "I understand".
  [ ] Lands on My Health. Help Now is in the header.
  [ ] Nearby: live places for the remembered town (default New Brunswick) and
      the line "They are not checked by our team." NOT the sample list.
      If the network fails it must say the list is unavailable, not show an
      empty screen. "This is a saved copy" after a rate limit is a pass.
  [ ] On one live card: Call, then Text, then Directions each open the phone's
      own app once. Back out without placing a call.
  [ ] Learn: six tiles (Physical Health, Mental Health, Stress Management,
      Nutrition, Preventive Care, Sleep). No Medications tile, no Exercise tile.
      Open one topic and one note; the note names its source.
  [ ] Help Now: 911 Emergency is first. Page says demo-only, does not dial.
  [ ] More: Ask a Peer, Session questions, How This App Protects You, and
      How to Use This App all open and return with the bottom tabs.
  [ ] Answer one Session question, force-stop the app, reopen: the answer is
      still selected.

CHECKLIST

echo "Full checklist and pass line: $SMOKE_DOC"