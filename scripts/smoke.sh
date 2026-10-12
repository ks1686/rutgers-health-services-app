#!/usr/bin/env bash
#
# Pre-CAB smoke check for the CWC Health App.
#
# Runs the same gates as CI (format, analyze, tests), builds the release APK,
# then prints the short manual checklist for the phone walkthrough.
#
#   scripts/smoke.sh                 # Android gates + release APK
#   scripts/smoke.sh --skip-build    # gates only, no APK
#   scripts/smoke.sh --skip-format   # ignore local/CI formatter version drift
#   scripts/smoke.sh --ios           # also build the iOS Simulator app (Mac)
#   scripts/smoke.sh --help
#
# Help Now dials by default (tel: / sms:). The member still places the call.
# Pass HELP_NOW_LIVE=false only for a build whose taps must not open the dialer.
#
# Exit code is non-zero if any step fails, so CI or a hook can call this.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

HELP_NOW_LIVE="${HELP_NOW_LIVE:-true}"
APK="build/app/outputs/flutter-apk/app-release.apk"
SMOKE_DOC="docs/engineering/cab-demo-smoke.md"
IOS_DOC="docs/engineering/ios-simulator.md"

skip_build=0
skip_format=0
with_ios=0

for arg in "$@"; do
  case "$arg" in
    --skip-build)  skip_build=1 ;;
    --skip-format) skip_format=1 ;;
    --ios)         with_ios=1 ;;
    -h|--help)     sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg (try --help)" >&2; exit 2 ;;
  esac
done

step=0
run_step() {
  step=$((step + 1))
  printf '\n\033[1m[%d/%d] %s\033[0m\n' "$step" "$TOTAL_STEPS" "$1"
}

# Format, analyze, test, optional APK, optional iOS.
if [ "$skip_build" -eq 1 ]; then TOTAL_STEPS=3; else TOTAL_STEPS=4; fi
if [ "$with_ios" -eq 1 ]; then TOTAL_STEPS=$((TOTAL_STEPS + 1)); fi

echo "CWC Health App — pre-CAB smoke"
echo "repo:    $(git rev-parse --short HEAD 2>/dev/null || echo 'not a git checkout')"
echo "flutter: $(flutter --version 2>/dev/null | head -1)"
echo "defines: HELP_NOW_LIVE=$HELP_NOW_LIVE"

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
flutter test

# ---------------------------------------------------------------- build
if [ "$skip_build" -eq 0 ]; then
  run_step "Build release APK"
  flutter build apk --release \
    --dart-define=HELP_NOW_LIVE="$HELP_NOW_LIVE"
fi

# ---------------------------------------------------------------- ios
if [ "$with_ios" -eq 1 ]; then
  run_step "Build iOS Simulator app"
  if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "xcodebuild not found. iOS build needs Xcode on this Mac." >&2
    exit 1
  fi
  # Flutter's prepare script calls codesign without --strip-disallowed-xattrs.
  # On this Mac a copied Flutter.framework keeps com.apple.provenance, and
  # codesign then exits 255. The wrapper adds the flag only for real signing.
  wrap="$(mktemp -d)"
  cat > "$wrap/codesign" <<'WRAP'
#!/bin/sh
for arg in "$@"; do
  case "$arg" in
    -s|--sign) exec /usr/bin/codesign --strip-disallowed-xattrs "$@" ;;
  esac
done
exec /usr/bin/codesign "$@"
WRAP
  chmod +x "$wrap/codesign"
  PATH="$wrap:$PATH" flutter build ios --simulator --no-codesign
  rm -rf "$wrap"
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
  echo "Nearby is always live. The list must be real places and the line"
  echo "'They are not checked by our team.' There is no sample pharmacy list."
  if [ "$HELP_NOW_LIVE" = "false" ]; then
    echo
    echo "HELP_NOW_LIVE=false: Help Now buttons do NOT open the dialer."
    echo "Nearby Call/Text/Directions do launch."
  else
    echo
    echo "Help Now opens the phone number, filled in. You place the call."
    echo "Back out of the dialer without calling."
  fi
else
  echo "Gates passed. APK build skipped."
fi
echo "=============================================================="

cat <<CHECKLIST

Phone walkthrough (full version: $SMOKE_DOC)
  [ ] Uninstall any older CWC Health App first. A debug-signed CI file will
      not upgrade a copy signed with the upload key, and the reverse is also
      true.
  [ ] Install, open. First launch shows "Before you continue" -> "I understand".
  [ ] Lands on My Health. The lists start empty. Help Now is in the header.
  [ ] Nearby: live places for the remembered town (default New Brunswick) and
      the line "They are not checked by our team."
      If the network fails it must say the list is unavailable, not show an
      empty screen. "This is a saved copy" after a rate limit is a pass.
  [ ] On one live card: Call, then Text, then Directions each open the phone's
      own app once. Back out without placing a call.
  [ ] Learn: six tiles (Physical Health, Mental Health, Stress Management,
      Nutrition, Preventive Care, Sleep). No Medications tile, no Exercise tile.
      Open one topic and one note; the note names its source.
  [ ] Help Now: 911 Emergency is first. A tap opens the dialer with the number
      filled in. Back out. Do not place the call. Warmline and wellness-center
      rows are hidden until CSPNJ confirms the numbers.
  [ ] More: Ask a Peer, Session questions, How This App Protects You, and
      How to Use This App all open and return with the bottom tabs.
  [ ] Answer one Session question, force-stop the app, reopen: the answer is
      still selected.

iOS Simulator (scripts/smoke.sh --ios, then see $IOS_DOC)
  [ ] App installs and opens on the booted simulator.
  [ ] Same first-launch, tabs, and Help Now checks as above.
  [ ] A Help Now tap cannot place a real call from the simulator. Confirm the
      button is a tel: link. Do not treat a simulator dialer as a phone test.

CHECKLIST

echo "Full checklist and pass line: $SMOKE_DOC"