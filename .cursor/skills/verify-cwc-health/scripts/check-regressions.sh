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
fixture_pid=''
spare_pid=''
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
  if [[ -n "${fixture_pid:-}" ]]; then
    kill "$fixture_pid" 2>/dev/null || true
  fi
  if [[ -n "${spare_pid:-}" ]]; then
    kill "$spare_pid" 2>/dev/null || true
  fi
}
cleanup_sandbox() {
  finish_bg
  if [[ -n "${sandbox:-}" && -d "$sandbox" ]]; then
    chmod -R u+w "$sandbox" 2>/dev/null || true
    rm -rf "$sandbox"
  fi
  if [[ -n "${foreign_home:-}" ]]; then
    sudo -n rm -rf "$foreign_home" 2>/dev/null || rm -rf "$foreign_home" 2>/dev/null || true
  fi
  rm -f "${out:-}" "${out}.2" "${out}.3" "${out}.4" "${out}.5" 2>/dev/null || true
  if [[ -n "${e1:-}" ]]; then
    rm -rf "$e1"
  fi
  if [[ -n "${e2:-}" ]]; then
    rm -rf "$e2"
  fi
}
trap cleanup_sandbox EXIT

if grep -nE '^[[:space:]]*(source|\.)[[:space:]]' "$VERIFY"; then
  fail "verify-cwc sources a file"
fi
pass "H1 run.env is not sourced"

# H1: a traversing run id must not delete or create anything.
h1=$(mktemp -d "$sandbox/h1.XXXX")
mkdir -p "$h1/home" "$h1/victim"
echo important >"$h1/victim/keep.txt"
unset CWC_VERIFY_HOME
default_root=$(state_home)
legacy_root=/tmp/cwc-verify
if [[ -d "$default_root" ]]; then
  default_before=$(listing "$default_root")
else
  default_before='__absent__'
fi
if [[ -d "$legacy_root" ]]; then
  legacy_before=$(listing "$legacy_root")
else
  legacy_before='__absent__'
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
if [[ -d "$legacy_root" ]]; then
  legacy_after=$(listing "$legacy_root")
else
  legacy_after='__absent__'
fi
[[ "$legacy_before" == "$legacy_after" ]] || fail "H1 touched the legacy state root"
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
fact_lines=()
while IFS= read -r line || [[ -n "$line" ]]; do
  fact_lines+=("$line")
done <"$sandbox/leader.facts"
start=${fact_lines[0]}
pgrp=${fact_lines[1]}
uid=${fact_lines[2]}
cmdline=$(printf '%s' "${fact_lines[3]}" | base64 -d)
ps_pgrp=$(ps -o pgid= -p "$leader" | tr -d ' ')
[[ "$ps_pgrp" == "$pgrp" ]] || fail "M1 proc_facts pgrp $pgrp != ps $ps_pgrp"
[[ "$pgrp" == "$leader" ]] || fail "M1 leader $leader is not its process group $pgrp"
kids=()
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue
  kids+=("$line")
done < <(ps -o pid= --ppid "$leader" | awk '{print $1}')
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
[[ ! -e /tmp/cwc-verify/regclick && ! -e "$default_root/regclick" ]] || fail "M3 click created state"
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

# N1: a loose or foreign state home is refused before any planted file runs.
loose_home=$(mktemp -d "$sandbox/loose.XXXX")
chmod 0777 "$loose_home"
loose_marker="$sandbox/loose-ran"
cat >"$sandbox/loose-evil.mjs" <<EOF
import fs from 'node:fs';
fs.writeFileSync('${loose_marker}', 'ran');
EOF
mkdir -m 0777 "$loose_home/looseid"
python3 - "$loose_home/looseid/run.env" "$sandbox/loose-evil.mjs" <<'PY'
import sys
path, evil = sys.argv[1:]
open(path, "w", encoding="utf-8").write(
    "\n".join(
        [
            "RUN_ID=looseid",
            "PORT=9",
            "URL=http://127.0.0.1:9",
            f"NODE_DAEMON={evil}",
            "RUN_HOME=/tmp/cwc-not-a-home",
            f"FLUTTER_BIN={evil}",
            "READY=yes",
            "",
        ]
    )
)
PY
python3 -c 'import socket,time,sys; s=socket.socket(socket.AF_UNIX,socket.SOCK_STREAM); s.bind(sys.argv[1]); s.listen(1); time.sleep(30)' \
  "$loose_home/looseid/browser.sock" &
holder=$!
set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_HOME="$loose_home" CWC_VERIFY_RUN_ID=looseid \
  "$VERIFY" browser opens >"$out" 2>&1
code=$?
set -e
printf -- '--- N1 loose home (exit %s) ---\n' "$code"
cat "$out"
[[ "$code" -ne 0 ]] || fail "N1 loose home exited 0"
grep -q 'group or world writable' "$out" || fail "N1 loose home missing refusal"
[[ ! -e "$loose_marker" ]] || fail "N1 loose home executed a planted daemon"
[[ -f "$loose_home/looseid/run.env" ]] || fail "N1 loose home deleted the planted file"
kill "$holder" 2>/dev/null || true
holder=''
pass "N1 refuses a group or world writable state home"

foreign_home=/tmp/cwc-foreign-$$
sudo -n rm -rf "$foreign_home"
sudo -n -u nobody mkdir -m 0777 "$foreign_home"
echo keep >"$foreign_home/keep.txt"
foreign_marker="$sandbox/foreign-ran"
cat >"$sandbox/foreign-evil.mjs" <<EOF
import fs from 'node:fs';
fs.writeFileSync('${foreign_marker}', 'ran');
EOF
set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_HOME="$foreign_home" CWC_VERIFY_RUN_ID=owned \
  "$VERIFY" cleanup >"$out" 2>&1
code=$?
set -e
printf -- '--- N1 foreign home (exit %s) ---\n' "$code"
cat "$out"
[[ "$code" -ne 0 ]] || fail "N1 foreign home exited 0"
grep -q 'owned by uid' "$out" || fail "N1 foreign home missing refusal"
[[ ! -e "$foreign_marker" ]] || fail "N1 foreign home executed a planted daemon"
[[ -f "$foreign_home/keep.txt" ]] || fail "N1 foreign home removed a file"
pass "N1 refuses a foreign state home"

# A private home still must not execute paths stored in run.env.
plant_home=$(mktemp -d "$sandbox/plant.XXXX")
plant_id=regplant
plant_state="$plant_home/$plant_id"
plant_marker="$sandbox/plant-ran"
mkdir -m 700 "$plant_state" "$plant_state/home" "$plant_state/tools"
cp "$DAEMON" "$plant_state/tools/browser-daemon.mjs"
cat >"$sandbox/plant-evil.mjs" <<EOF
import fs from 'node:fs';
fs.writeFileSync('${plant_marker}', 'ran');
EOF
python3 - "$plant_state/run.env" "$sandbox/plant-evil.mjs" "$plant_state/home" <<'PY'
import sys
path, evil, home = sys.argv[1:]
open(path, "w", encoding="utf-8").write(
    "\n".join(
        [
            "RUN_ID=regplant",
            "PORT=9",
            "URL=http://127.0.0.1:9",
            "PID=1",
            f"EVIDENCE={home}",
            f"NODE_DAEMON={evil}",
            "RUN_HOME=/tmp/cwc-planted-home-missing",
            f"FLUTTER_BIN={evil}",
            "READY=yes",
            "",
        ]
    )
)
PY
python3 -c 'import socket,sys; s=socket.socket(socket.AF_UNIX,socket.SOCK_STREAM); s.bind(sys.argv[1]); s.listen(1); c,_=s.accept(); c.close()' \
  "$plant_state/browser.sock" &
holder=$!
flutter_kept=$(
  CWC_VERIFY_RUN_ID=$plant_id
  FLUTTER_BIN=/usr/bin/true
  load_state_file "$plant_state/run.env"
  printf '%s' "$FLUTTER_BIN"
)
[[ "$flutter_kept" == /usr/bin/true ]] || fail "N1 run.env replaced FLUTTER_BIN"
set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_HOME="$plant_home" CWC_VERIFY_RUN_ID="$plant_id" \
  "$VERIFY" browser opens >"$out" 2>&1
code=$?
set -e
printf -- '--- N1 planted paths (exit %s) ---\n' "$code"
cat "$out"
[[ "$code" -ne 0 ]] || fail "N1 planted browser opens exited 0"
grep -q 'no isolated home' "$out" && fail "N1 used RUN_HOME from the state file"
[[ ! -e "$plant_marker" ]] || fail "N1 executed NODE_DAEMON from the state file"
kill "$holder" 2>/dev/null || true
holder=''
pass "N1 ignores daemon, home, and flutter paths in run.env"

# L-N2: cleanup deletes a run only when its run.env is ours.
doc_home=$(mktemp -d "$sandbox/doc.XXXX")
mkdir -m 700 "$doc_home/Documents"
echo thesis >"$doc_home/Documents/thesis.txt"
set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_HOME="$doc_home" CWC_VERIFY_RUN_ID=Documents \
  "$VERIFY" cleanup >"$out" 2>&1
code=$?
set -e
printf -- '--- cleanup without run.env (exit %s) ---\n' "$code"
cat "$out"
[[ "$code" -ne 0 ]] || fail "cleanup without run.env exited 0"
[[ -f "$doc_home/Documents/thesis.txt" ]] || fail "cleanup deleted a folder with no run.env"
echo 'this is not a state file' >"$doc_home/Documents/run.env"
set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_HOME="$doc_home" CWC_VERIFY_RUN_ID=Documents \
  "$VERIFY" cleanup >"$out" 2>&1
code=$?
set -e
[[ "$code" -ne 0 ]] || fail "cleanup of a bad run.env exited 0"
[[ -f "$doc_home/Documents/thesis.txt" ]] || fail "cleanup deleted a folder with a bad run.env"
pass "cleanup leaves a directory that has no run.env of ours"

# Evidence directories the caller already has are not chmodded.
ev755=$(mktemp -d "$sandbox/ev755.XXXX")
chmod 755 "$ev755"
(
  CWC_VERIFY_EVIDENCE=$ev755 prepare_evidence
)
[[ "$(stat -c %a "$ev755")" == 755 ]] || fail "prepare_evidence chmodded a private directory"
ev777=$(mktemp -d "$sandbox/ev777.XXXX")
chmod 777 "$ev777"
set +e
(
  CWC_VERIFY_EVIDENCE=$ev777 prepare_evidence
)
code=$?
set -e
[[ "$code" -ne 0 ]] || fail "world-writable evidence was accepted"
[[ "$(stat -c %a "$ev777")" == 777 ]] || fail "world-writable evidence was chmodded"
pass "evidence directory mode is left alone"

# Start time must match before a kill. A full match is killed.
start_proc() {
  python3 -c 'import os
pid = os.fork()
if pid == 0:
    os.setsid()
    fd = os.open("/dev/null", os.O_RDWR)
    os.dup2(fd, 0)
    os.dup2(fd, 1)
    os.dup2(fd, 2)
    os.execv("/bin/sleep", ["flutter run -d web-server --web-port 18991 --dart-define=HELP_NOW_LIVE=false", "120"])
else:
    print(pid)'
}
write_gate_env() {
  python3 - "$1" "$2" "$3" "$4" "$5" "$6" "$7" <<'PY'
import sys
path, pid, start, uid, pgrp, evidence, run_id = sys.argv[1:]
open(path, "w", encoding="utf-8").write(
    "\n".join(
        [
            f"RUN_ID={run_id}",
            f"PID={pid}",
            "PORT=18991",
            "URL=http://127.0.0.1:18991",
            f"EVIDENCE={evidence}",
            f"FLUTTER_START={start}",
            f"FLUTTER_UID={uid}",
            f"FLUTTER_PGRP={pgrp}",
            "BROWSER_PID=",
            "READY=yes",
            "",
        ]
    )
)
PY
}
gate_home=$(mktemp -d "$sandbox/gate.XXXX")
gate_ev=$(mktemp -d "$sandbox/gate-ev.XXXX")
echo stay >"$gate_ev/stay.txt"
spare_pid=$(start_proc)
sleep 0.3
kill -0 "$spare_pid" || fail "start-time process exited early"
read_proc "$spare_pid" || fail "could not read the start-time process"
[[ "$PROC_CMD" == *web-server* && "$PROC_CMD" == *HELP_NOW_LIVE=false* && "$PROC_CMD" == *18991* ]] || fail "start-time cmdline was $PROC_CMD"
[[ "$PROC_PGRP" == "$spare_pid" ]] || fail "start-time process is not its group leader"
read_proc_ps "$spare_pid" || fail "ps fallback could not read the process"
[[ "$PROC_UID" == "$(id -u)" && "$PROC_CMD" == *sleep* || "$PROC_CMD" == *HELP_NOW_LIVE=false* ]] || fail "ps fallback uid or command"
read_proc "$spare_pid"
real_start=$PROC_START
real_uid=$PROC_UID
real_pgrp=$PROC_PGRP
mkdir -m 700 "$gate_home/regtime"
write_gate_env "$gate_home/regtime/run.env" "$spare_pid" "$((real_start + 1))" "$real_uid" "$real_pgrp" "$gate_ev" regtime
set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_HOME="$gate_home" CWC_VERIFY_RUN_ID=regtime \
  "$VERIFY" cleanup >"$out" 2>&1
code=$?
set -e
printf -- '--- start time mismatch (exit %s) ---\n' "$code"
cat "$out"
[[ "$code" -eq 0 ]] || fail "start time mismatch cleanup failed"
grep -q "skip pid $spare_pid (start time differs)" "$out" || fail "start time gate missing skip"
kill -0 "$spare_pid" || fail "start time gate killed the process"
[[ -f "$gate_ev/stay.txt" ]] || fail "start time gate removed evidence"
pass "cleanup skips a pid whose start time differs"

mkdir -m 700 "$gate_home/regkill"
write_gate_env "$gate_home/regkill/run.env" "$spare_pid" "$real_start" "$real_uid" "$real_pgrp" "$gate_ev" regkill
set +e
env -u CWC_VERIFY_EVIDENCE CWC_VERIFY_HOME="$gate_home" CWC_VERIFY_RUN_ID=regkill \
  "$VERIFY" cleanup >"$out" 2>&1
code=$?
set -e
printf -- '--- genuine cleanup (exit %s) ---\n' "$code"
cat "$out"
[[ "$code" -eq 0 ]] || fail "genuine cleanup failed"
if kill -0 "$spare_pid" 2>/dev/null; then
  fail "genuine cleanup left the process alive"
fi
spare_pid=''
[[ -f "$gate_ev/stay.txt" ]] || fail "genuine cleanup removed evidence"
pass "cleanup kills a process whose facts all match"

# Live snapshot and screenshot, including paths that must be refused.
fix_state=$(mktemp -d "$sandbox/fix-state.XXXX")
fix_ev=$(mktemp -d "$sandbox/fix-ev.XXXX")
chmod 750 "$fix_ev"
cp "$DAEMON" "$tools/browser-daemon.mjs"
CWC_STATE="$fix_state" CWC_EVIDENCE="$fix_ev" CWC_SKILL_DIR="$SCRIPT_DIR" \
  node "$tools/browser-daemon.mjs" serve-fixture >"$sandbox/fixture.log" 2>&1 &
fixture_pid=$!
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40; do
  [[ -S "$fix_state/browser.sock" ]] && break
  sleep 0.25
done
[[ -S "$fix_state/browser.sock" ]] || {
  cat "$sandbox/fixture.log" >&2 || true
  fail "fixture browser did not open a socket"
}
set +e
CWC_EVIDENCE="$fix_ev" CWC_STATE="$fix_state" CWC_SKILL_DIR="$SCRIPT_DIR" \
  node "$tools/browser-daemon.mjs" client "$fix_state/browser.sock" \
  '{"cmd":"click","role":"button","name":"Poison Control","exact":false}' >"$out" 2>&1
code=$?
set -e
printf -- '--- contains phone row (exit %s) ---\n' "$code"
cat "$out"
[[ "$code" -ne 0 ]] || fail "contains click of Poison Control exited 0"
grep -q 'refusing to tap a phone or text row' "$out" || fail "contains click missed the rendered name"
CWC_EVIDENCE="$fix_ev" CWC_STATE="$fix_state" CWC_SKILL_DIR="$SCRIPT_DIR" \
  node "$tools/browser-daemon.mjs" client "$fix_state/browser.sock" \
  '{"cmd":"click","role":"button","name":"Sample control","exact":true}' >"$out"
grep -q 'clicked button Sample control' "$out" || fail "fixture click missed Sample control"
CWC_EVIDENCE="$fix_ev" CWC_STATE="$fix_state" CWC_SKILL_DIR="$SCRIPT_DIR" \
  node "$tools/browser-daemon.mjs" client "$fix_state/browser.sock" \
  "{\"cmd\":\"snapshot\",\"path\":\"$fix_ev/nested/page.txt\"}" >"$out"
[[ -f "$fix_ev/nested/page.txt" ]] || fail "live snapshot did not write"
[[ "$(stat -c %a "$fix_ev/nested/page.txt")" == 600 ]] || fail "live snapshot mode"
[[ "$(stat -c %a "$fix_ev")" == 750 ]] || fail "live snapshot chmodded the evidence root"
CWC_EVIDENCE="$fix_ev" CWC_STATE="$fix_state" CWC_SKILL_DIR="$SCRIPT_DIR" \
  node "$tools/browser-daemon.mjs" client "$fix_state/browser.sock" \
  "{\"cmd\":\"screenshot\",\"path\":\"$fix_ev/page.png\"}" >"$out"
[[ -f "$fix_ev/page.png" && "$(stat -c %a "$fix_ev/page.png")" == 600 ]] || fail "live screenshot"
abs_target="/tmp/cwc-abs-escape-$$.txt"
set +e
CWC_EVIDENCE="$fix_ev" CWC_STATE="$fix_state" CWC_SKILL_DIR="$SCRIPT_DIR" \
  node "$tools/browser-daemon.mjs" client "$fix_state/browser.sock" \
  "{\"cmd\":\"snapshot\",\"path\":\"$abs_target\"}" >"$out" 2>&1
code=$?
CWC_EVIDENCE="$fix_ev" CWC_STATE="$fix_state" CWC_SKILL_DIR="$SCRIPT_DIR" \
  node "$tools/browser-daemon.mjs" client "$fix_state/browser.sock" \
  "{\"cmd\":\"snapshot\",\"path\":\"$fix_state/evil.txt\"}" >"$out.2" 2>&1
code2=$?
ln -s "/tmp/cwc-no-file-$$" "$fix_ev/dangling-file"
ln -s "/tmp/cwc-no-dir-$$" "$fix_ev/dangling-dir"
CWC_EVIDENCE="$fix_ev" CWC_STATE="$fix_state" CWC_SKILL_DIR="$SCRIPT_DIR" \
  node "$tools/browser-daemon.mjs" client "$fix_state/browser.sock" \
  "{\"cmd\":\"snapshot\",\"path\":\"$fix_ev/dangling-file\"}" >"$out.3" 2>&1
code3=$?
CWC_EVIDENCE="$fix_ev" CWC_STATE="$fix_state" CWC_SKILL_DIR="$SCRIPT_DIR" \
  node "$tools/browser-daemon.mjs" client "$fix_state/browser.sock" \
  "{\"cmd\":\"snapshot\",\"path\":\"$fix_ev/dangling-dir/out.txt\"}" >"$out.4" 2>&1
code4=$?
set -e
printf -- '--- live path refusals (exits %s %s %s %s) ---\n' "$code" "$code2" "$code3" "$code4"
cat "$out" "$out.2" "$out.3" "$out.4"
[[ "$code" -ne 0 && "$code2" -ne 0 && "$code3" -ne 0 && "$code4" -ne 0 ]] || fail "live snapshot allowed an escaping path"
[[ ! -e "$abs_target" && ! -e "$fix_state/evil.txt" && ! -e "/tmp/cwc-no-file-$$" && ! -e "/tmp/cwc-no-dir-$$" ]] || fail "live snapshot wrote outside"
[[ "$(stat -c %a "$fix_ev")" == 750 ]] || fail "refused snapshot chmodded the evidence root"
kill "$fixture_pid" 2>/dev/null || true
fixture_pid=''
pass "live snapshot stays inside a private evidence directory"
pass "contains match refuses a rendered phone row"

# HOME isolation leaves the caller home unchanged.
canary=$(mktemp -d "$sandbox/canary.XXXX")
echo secret >"$canary/keep"
canary_before=$(ls -A "$canary" | sort)
iso_state=$(mktemp -d "$sandbox/iso.XXXX")
(
  HOME=$canary
  isolate_home "$iso_state"
  touch "$HOME/from-run"
  [[ "$HOME" == "$iso_state/home" ]]
  [[ "$GOTELEMETRY" == off ]]
  [[ "$PUB_CACHE" == "$USER_HOME/.pub-cache" || "$PUB_CACHE" == "$SAVED_PUB_CACHE" ]]
)
[[ -f "$iso_state/home/from-run" ]] || fail "isolated home did not receive the write"
canary_after=$(ls -A "$canary" | sort)
[[ "$canary_before" == "$canary_after" ]] || fail "isolated home wrote into the caller home"
grep -q 'CFFIXED_USER_HOME' "$VERIFY" || fail "macOS home override is missing"
grep -q 'GOTELEMETRY=off' "$VERIFY" || fail "Go telemetry is not turned off"
pass "isolated home leaves the caller home unchanged"

echo REGRESSIONS PASS
