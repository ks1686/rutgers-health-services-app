#!/usr/bin/env python3
"""Report whether a TCP port is in LISTEN state.

A listen socket is busy even when this user cannot see the process that holds it.
"""

import os
import sys


def listen_inodes(port):
    hexport = f"{port:04X}"
    found = set()
    for name in ("/proc/net/tcp", "/proc/net/tcp6"):
        try:
            lines = open(name, encoding="utf-8").read().splitlines()[1:]
        except OSError:
            continue
        for line in lines:
            parts = line.split()
            if len(parts) < 10 or parts[3] != "0A":
                continue
            if parts[1].rsplit(":", 1)[-1].upper() != hexport:
                continue
            inode = parts[9]
            if inode and inode != "0":
                found.add(inode)
    return found


def pid_for(inodes):
    if not inodes:
        return None
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        fd_dir = f"/proc/{pid}/fd"
        try:
            fds = os.listdir(fd_dir)
        except OSError:
            continue
        for fd in fds:
            try:
                target = os.readlink(f"{fd_dir}/{fd}")
            except OSError:
                continue
            if (
                target.startswith("socket:[")
                and target.endswith("]")
                and target[8:-1] in inodes
            ):
                return pid
    return None


def classify(inodes, pid):
    if not inodes:
        return "free"
    if pid:
        return f"busy {pid}"
    return "busy unknown"


def status(port):
    inodes = listen_inodes(port)
    return classify(inodes, pid_for(inodes) if inodes else None)


def self_test():
    assert classify(set(), None) == "free"
    assert classify({"5"}, None) == "busy unknown"
    assert classify({"5"}, "9") == "busy 9"


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        self_test()
        print("port self-test ok")
        raise SystemExit(0)
    print(status(int(sys.argv[1])))
