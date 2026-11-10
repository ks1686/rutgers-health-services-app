#!/usr/bin/env python3
"""Print start time, process group, uid, and base64 cmdline for one pid."""

import base64
import sys


def main():
    pid = sys.argv[1]
    stat = open(f"/proc/{pid}/stat", encoding="utf-8").read()
    raw = open(f"/proc/{pid}/cmdline", "rb").read()
    raw = raw.replace(b"\0", b" ").replace(b"\n", b" ")
    status = open(f"/proc/{pid}/status", encoding="utf-8").read()
    end = stat.rfind(")")
    fields = stat[end + 2 :].split()
    if len(fields) < 20:
        raise SystemExit(1)
    uid = ""
    for line in status.splitlines():
        if line.startswith("Uid:"):
            uid = line.split()[1]
            break
    if not uid:
        raise SystemExit(1)
    # Field 5 (pgrp) is index 2 after comm. Field 22 (starttime) is index 19.
    start = fields[19]
    pgrp = fields[2]
    encoded = base64.b64encode(raw).decode("ascii")
    sys.stdout.write(f"{start}\n{pgrp}\n{uid}\n{encoded}\n")


if __name__ == "__main__":
    main()
