#!/usr/bin/env bash
# Proves the verification helper stays inside its own run.
set -euo pipefail
umask 077

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VERIFY="$SCRIPT_DIR/verify-cwc"
DAEMON="$SCRIPT_DIR/browser-daemon.mjs"
REPO=$(cd "$SCRIPT_DIR/../../.." && pwd)
# shellcheck source=verify-cwc
source "$VERIFY"
ROOT=$REPO

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }

listing() {
  find "$1" -printf '%p\n' | sort
}

same_tree() {
  local before=$1 after=$2 label=$3
  if [[ "$before" != "$after" ]]; then
    printf 'tree changed during %s\n' "$label" >&2
    diff -u <(printf '%s\n' "$before") <(printf '%s\n' "$after") >&2 || true
    fail "$label"
  fi
}

sandbox=$(mktemp -d)
leader=''
holder=''
finish_bg() {
  if [[ -n "${leader:-}" ]] && kill -0 "$leader" 2>/dev/null; then
    local child
    for child in $(ps -o pid= --ppid "$leader" 2>/dev/null || true); do
      kill "$child" 2>/dev/null || true
    done
    kill "$leader" 2>/dev/null || true
  fi
  if [[ -n "${holder:-}" ]]; then
    kill "$holder" 2>/dev/null || true
  fi
}
trap finish_bg EXIT

if grep -nE '^[[:space:]]*(source|\.)[[:space:]]' "$VERIFY"; then
  fail "verify-cwc sources a file"
fi
pass "H1 run.env is not sourced"

# H1: a traversing run id must not delete or create anything.
h1=$(mktemp -d "$sandbox/h1.XXXX")
mkdir -p "$h1/home" "$h1/victim"
echo important >"$h1/victim/keep.txt"
default_root=/tmp/cwc-verify
if [[ -d "$default_root" ]]; then
  default_before=$(listing "$default_root")
else
  default_before='__absent__'
fi
before=$(listing "$h1")
out=$(mktemp)
set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_HOME="$h1/home" CWC_VERIFY_RUN_ID='../victim' \
  "$VERIFY" cleanup >"$out" 2>&1
code=$?
set -e
printf -- '--- H1 cleanup ../victim (exit %s) ---\n' "$code"
cat "$out"
[[ "$code" -ne 0 ]] || fail "H1 cleanup ../victim exited 0"
grep -q 'refusing run id' "$out" || fail "H1 cleanup ../victim missing refusal"
same_tree "$before" "$(listing "$h1")" "H1 cleanup ../victim"
[[ -f "$h1/victim/keep.txt" ]] || fail "H1 victim file missing"
pass "H1 cleanup ../victim"

before=$(listing "$h1")
evil="x';touch ${h1}/PWNED;'"
set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_HOME="$h1/home" CWC_VERIFY_RUN_ID="$evil" \
  "$VERIFY" launch >"$out" 2>&1
code=$?
set -e
printf -- '--- H1 launch injection (exit %s) ---\n' "$code"
cat "$out"
[[ "$code" -ne 0 ]] || fail "H1 launch injection exited 0"
grep -q 'refusing run id' "$out" || fail "H1 launch injection missing refusal"
same_tree "$before" "$(listing "$h1")" "H1 launch injection"
[[ ! -e "$h1/PWNED" ]] || fail "H1 injection created PWNED"
pass "H1 launch injection"

before=$(listing "$h1")
set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_HOME="$h1/home" CWC_VERIFY_RUN_ID="$evil" \
  "$VERIFY" cleanup >"$out" 2>&1
code=$?
set -e
[[ "$code" -ne 0 ]] || fail "H1 cleanup injection exited 0"
same_tree "$before" "$(listing "$h1")" "H1 cleanup injection"
[[ ! -e "$h1/PWNED" ]] || fail "H1 cleanup injection created PWNED"
pass "H1 cleanup injection"

for bad in '.' '..'; do
  before=$(listing "$h1")
  set +e
  env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_HOME="$h1/home" CWC_VERIFY_RUN_ID="$bad" \
    "$VERIFY" cleanup >"$out" 2>&1
  code=$?
  set -e
  [[ "$code" -ne 0 ]] || fail "H1 id $bad exited 0"
  same_tree "$before" "$(listing "$h1")" "H1 id $bad"
  pass "H1 rejects $bad"
done

if [[ -d "$default_root" ]]; then
  default_after=$(listing "$default_root")
else
  default_after='__absent__'
fi
[[ "$default_before" == "$default_after" ]] || fail "H1 touched the default state root"
pass "H1 default state root untouched"

if ( validate_run_id 'a.b' ); then
  pass "H1 accepts a.b"
else
  fail "H1 rejected a.b"
fi

# A state file is data. A command substitution in a value must not run.
parse_home="$sandbox/parse-home"
parse_id=regparse
parse_state="$parse_home/$parse_id"
parse_evidence=$(mktemp -d "$sandbox/parse-evidence.XXXX")
echo stay >"$parse_evidence/stay.txt"
mkdir -p "$parse_state"
pwned="$sandbox/PWNED_PARSE"
python3 - "$parse_state/run.env" "$pwned" "$parse_evidence" <<'PY'
import sys
path, pwned, evidence = sys.argv[1:]
open(path, "w", encoding="utf-8").write(
    "RUN_ID=regparse\n"
    f"PID=$(touch {pwned})\n"
    "PORT=8773\n"
    "URL=http://127.0.0.1:9\n"
    f"EVIDENCE={evidence}\n"
    "READY=yes\n"
)
PY
set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_HOME="$parse_home" CWC_VERIFY_RUN_ID="$parse_id" \
  "$VERIFY" cleanup >"$out" 2>&1
code=$?
set -e
printf -- '--- H1 parser cleanup (exit %s) ---\n' "$code"
cat "$out"
[[ "$code" -eq 0 ]] || fail "H1 parser cleanup failed"
[[ ! -e "$pwned" ]] || fail "H1 parser executed a state value"
[[ -f "$parse_evidence/stay.txt" ]] || fail "H1 parser removed evidence"
[[ ! -d "$parse_state" ]] || fail "H1 parser left the state directory"
pass "H1 parser does not execute state values"

# M1: cleanup must not signal an unrelated process group.
m1_home="$sandbox/m1-home"
m1_id=regm1
m1_state="$m1_home/$m1_id"
m1_evidence=$(mktemp -d "$sandbox/m1-evidence.XXXX")
echo stay >"$m1_evidence/stay.txt"
mkdir -p "$m1_state/home"
(
  exec setsid bash -c 'sleep 400 & sleep 400 & wait'
) &
leader=$!
sleep 0.4
kill -0 "$leader" || fail "M1 leader exited before cleanup"
python3 "$SCRIPT_DIR/proc_facts.py" "$leader" >"$sandbox/leader.facts"
mapfile -t fact_lines <"$sandbox/leader.facts"
start=${fact_lines[0]}
pgrp=${fact_lines[1]}
uid=${fact_lines[2]}
cmdline=$(printf '%s' "${fact_lines[3]}" | base64 -d)
ps_pgrp=$(ps -o pgid= -p "$leader" | tr -d ' ')
[[ "$ps_pgrp" == "$pgrp" ]] || fail "M1 proc_facts pgrp $pgrp != ps $ps_pgrp"
[[ "$pgrp" == "$leader" ]] || fail "M1 leader $leader is not its process group $pgrp"
mapfile -t kids < <(ps -o pid= --ppid "$leader" | awk '{print $1}')
[[ "${#kids[@]}" -ge 1 ]] || fail "M1 leader has no children"
python3 - "$m1_state/run.env" "$leader" "$start" "$uid" "$pgrp" "$cmdline" "$m1_evidence" <<'PY'
import sys
path, pid, start, uid, pgrp, cmdline, evidence = sys.argv[1:]
open(path, "w", encoding="utf-8").write(
    "\n".join(
        [
            "RUN_ID=regm1",
            f"PID={pid}",
            "PORT=8773",
            "URL=http://127.0.0.1:9",
            f"EVIDENCE={evidence}",
            f"FLUTTER_START={start}",
            f"FLUTTER_UID={uid}",
            f"FLUTTER_PGRP={pgrp}",
            f"FLUTTER_CMDLINE={cmdline}",
            "BROWSER_PID=",
            "READY=yes",
            "",
        ]
    )
)
PY
set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_HOME="$m1_home" CWC_VERIFY_RUN_ID="$m1_id" \
  "$VERIFY" cleanup >"$out" 2>&1
code=$?
set -e
printf -- '--- M1 cleanup (exit %s) ---\n' "$code"
cat "$out"
[[ "$code" -eq 0 ]] || fail "M1 cleanup failed"
grep -q "skip pid $leader (cmdline does not match)" "$out" || fail "M1 missing skip message"
kill -0 "$leader" || fail "M1 cleanup killed the unrelated leader"
for child in "${kids[@]}"; do
  kill -0 "$child" || fail "M1 cleanup killed child $child"
done
[[ -f "$m1_evidence/stay.txt" ]] || fail "M1 removed evidence"
[[ ! -d "$m1_state" ]] || fail "M1 left the state directory"
pass "M1 cleanup skips an unrelated pid"
finish_bg
leader=''

# Unique ids, private evidence, tracked copy, busy port.
unset CWC_VERIFY_RUN_ID
prepare_run_id launch
first=$CWC_VERIFY_RUN_ID
unset CWC_VERIFY_RUN_ID
prepare_run_id launch
second=$CWC_VERIFY_RUN_ID
[[ "$first" != "$second" && "$first" != local && "$second" != local ]] || fail "M1 default run id"
if ( unset CWC_VERIFY_RUN_ID; prepare_run_id doctor ); then
  fail "doctor invented a run id"
fi
pass "M1 run ids are unique and required"

unset CWC_VERIFY_EVIDENCE
prepare_evidence
e1=$EVIDENCE
unset CWC_VERIFY_EVIDENCE
prepare_evidence
e2=$EVIDENCE
[[ "$e1" != "$e2" ]] || fail "L5 evidence paths collided"
[[ "$e1" != *cwc-verify-evidence* && "$e2" != *cwc-verify-evidence* ]] || fail "L5 predictable evidence path"
[[ "$(stat -c %a "$e1")" == 700 && "$(stat -c %a "$e2")" == 700 ]] || fail "L5 evidence mode"
rm -rf "$e1" "$e2"
unset CWC_VERIFY_EVIDENCE
pass "L5 evidence directory is private and unpredictable"

copy_src=$(mktemp -d "$sandbox/copy-src.XXXX")
copy_dst=$(mktemp -d "$sandbox/copy-dst.XXXX")
mkdir -p "$copy_src/android" "$copy_src/sub"
echo tracked >"$copy_src/tracked.txt"
echo nested >"$copy_src/sub/nested.txt"
echo secret >"$copy_src/.env"
echo key >"$copy_src/android/key.properties"
git -C "$copy_src" init -q
git -C "$copy_src" add tracked.txt sub/nested.txt
copy_tracked "$copy_src" "$copy_dst"
[[ -f "$copy_dst/tracked.txt" && -f "$copy_dst/sub/nested.txt" ]] || fail "L1 missed tracked files"
[[ ! -e "$copy_dst/.env" && ! -e "$copy_dst/android/key.properties" ]] || fail "L1 copied untracked secrets"
pass "L1 copy keeps untracked secrets out"

python3 "$SCRIPT_DIR/port_status.py" --self-test
pass "L2 hidden holder is busy unknown"
port_file="$sandbox/port.txt"
python3 - "$port_file" <<'PY' &
import socket, sys, time
path = sys.argv[1]
sock = socket.socket()
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(("127.0.0.1", 0))
open(path, "w", encoding="utf-8").write(str(sock.getsockname()[1]))
sock.listen(1)
time.sleep(60)
PY
holder=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do
  [[ -s "$port_file" ]] && break
  sleep 0.1
done
busy_port=$(cat "$port_file")
busy_status=$(python3 "$SCRIPT_DIR/port_status.py" "$busy_port")
printf 'L2 live status: %s\n' "$busy_status"
[[ "$busy_status" == busy\ * ]] || fail "L2 live port looked free"
port_home="$sandbox/port-home"
set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_HOME="$port_home" CWC_VERIFY_RUN_ID=regport \
  CWC_VERIFY_PORT="$busy_port" "$VERIFY" launch >"$out" 2>&1
code=$?
set -e
printf -- '--- L2 launch on a busy port (exit %s) ---\n' "$code"
cat "$out"
[[ "$code" -ne 0 ]] || fail "L2 launch exited 0"
grep -q 'already in use' "$out" || fail "L2 launch missing busy message"
[[ ! -e "$port_home" ]] || fail "L2 launch created state for a busy port"
pass "L2 busy port refuses launch"
kill "$holder" 2>/dev/null || true
holder=''

set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_HOME="$sandbox/badport-home" CWC_VERIFY_RUN_ID=regbadport \
  CWC_VERIFY_PORT='12;touch' "$VERIFY" launch >"$out" 2>&1
code=$?
set -e
[[ "$code" -ne 0 ]] || fail "bad port exited 0"
[[ ! -e "$sandbox/badport-home" ]] || fail "bad port created state"
[[ ! -e "$sandbox/touch" ]] || fail "bad port executed a suffix"
pass "L2 bad port is refused"

# M2: evidence paths cannot leave the run folder.
ev_parent=$(mktemp -d "$sandbox/ev.XXXX")
ev="$ev_parent/evidence"
outside="$ev_parent/outside"
mkdir -m 700 "$ev" "$outside"
ln -s "$outside" "$ev/link"
ln -s "$outside/viafile.txt" "$ev/alias.txt"
set +e
CWC_EVIDENCE="$ev" node "$DAEMON" check-path "$ev/../escape.txt" >"$out" 2>&1
c1=$?
CWC_EVIDENCE="$ev" node "$DAEMON" check-path "$ev/link/through.txt" >"$out.2" 2>&1
c2=$?
CWC_EVIDENCE="$ev" node "$DAEMON" write-text "$ev/link/through.txt" hello >"$out.3" 2>&1
c3=$?
CWC_EVIDENCE="$ev" node "$DAEMON" write-text "$ev/alias.txt" hello >"$out.4" 2>&1
c4=$?
set -e
printf -- '--- M2 refusals (exits %s %s %s %s) ---\n' "$c1" "$c2" "$c3" "$c4"
cat "$out" "$out.2" "$out.3" "$out.4"
[[ "$c1" -ne 0 && "$c2" -ne 0 && "$c3" -ne 0 && "$c4" -ne 0 ]] || fail "M2 allowed an escaping path"
[[ ! -e "$ev_parent/escape.txt" && ! -e "$outside/through.txt" && ! -e "$outside/viafile.txt" ]] || fail "M2 wrote outside"
CWC_EVIDENCE="$ev" node "$DAEMON" write-text "$ev/nested/ok.txt" hello >"$out.5"
[[ -f "$ev/nested/ok.txt" ]] || fail "M2 rejected an inside path"
[[ "$(stat -c %a "$ev/nested/ok.txt")" == 600 ]] || fail "M2 file mode"
[[ "$(stat -c %a "$ev")" == 700 && "$(stat -c %a "$ev/nested")" == 700 ]] || fail "M2 directory mode"
pass "M2 evidence paths stay inside the run folder"

# Phone taps are refused before a browser exists.
set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_RUN_ID=regclick \
  "$VERIFY" browser click --role button --name "Call 911, emergency. Opens your phone dialer." \
  >"$out" 2>&1
code=$?
set -e
printf -- '--- M3 click refusal (exit %s) ---\n' "$code"
cat "$out"
[[ "$code" -ne 0 ]] || fail "M3 click exited 0"
grep -q 'refusing to tap a phone or text row' "$out" || fail "M3 click missing refusal"
[[ ! -e /tmp/cwc-verify/regclick ]] || fail "M3 click created state"
set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_RUN_ID=regclick \
  "$VERIFY" browser click --role button --name "I understand" --expect-open tel:911 \
  >"$out" 2>&1
code=$?
set -e
[[ "$code" -ne 0 ]] || fail "M3 expect-open exited 0"
grep -q 'refusing to watch a phone or text open' "$out" || fail "M3 expect-open missing refusal"
pass "M3 phone clicks are refused"

# The page stub must not call the real window.open for tel: or sms:.
tools=$(mktemp -d "$sandbox/tools.XXXX")
tools_home=$(mktemp -d "$sandbox/tools-home.XXXX")
cp "$SCRIPT_DIR/package.json" "$SCRIPT_DIR/package-lock.json" "$DAEMON" "$tools/"
HOME="$tools_home" npm ci --prefix "$tools" --omit=dev --no-fund --no-audit
cat >"$tools/stub-test.mjs" <<'EOF'
import { chromium } from 'playwright-core';
import { OPEN_STUB } from './browser-daemon.mjs';

async function launch() {
  const attempts = [
    { channel: 'chrome', args: ['--disable-dev-shm-usage'] },
    {
      executablePath: '/usr/bin/google-chrome',
      args: ['--disable-dev-shm-usage', '--no-sandbox'],
    },
  ];
  let last;
  for (const opts of attempts) {
    try {
      return await chromium.launch({ headless: true, ...opts });
    } catch (err) {
      last = err;
    }
  }
  throw last;
}

const browser = await launch();
const page = await browser.newPage();
await page.addInitScript(() => {
  window.__origCalls = [];
  const orig = window.open.bind(window);
  window.open = function open(href, ...rest) {
    window.__origCalls.push(String(href));
    return orig(href, ...rest);
  };
});
await page.addInitScript(OPEN_STUB);
await page.goto('about:blank');
const result = await page.evaluate(() => {
  const tel = window.open('tel:911');
  const sms = window.open('sms:988');
  return { tel, sms, opens: window.__cwcOpens, orig: window.__origCalls };
});
await browser.close();
if (result.tel !== null || result.sms !== null) {
  console.error(JSON.stringify(result));
  process.exit(1);
}
if (result.orig.length !== 0) {
  console.error(JSON.stringify(result));
  process.exit(1);
}
const opens = result.opens.join('\n');
if (!opens.includes('tel:911') || !opens.includes('sms:988')) {
  console.error(JSON.stringify(result));
  process.exit(1);
}
console.log(`no real window.open ${JSON.stringify(result)}`);
EOF
HOME="$tools_home" \
  XDG_CACHE_HOME="$tools_home/.cache" \
  XDG_CONFIG_HOME="$tools_home/.config" \
  node "$tools/stub-test.mjs"
[[ ! -d "$SCRIPT_DIR/node_modules" ]] || fail "L4 node_modules landed in the repo"
[[ ! -d "$ROOT/web" ]] || fail "web/ landed in the repo"
pass "M3 tel and sms do not call window.open"
pass "L4 node_modules stayed out of the repo"

echo REGRESSIONS PASS
