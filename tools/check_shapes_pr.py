#!/usr/bin/env python3
"""
Scan changed files against a whitelist of allowed OCI shapes.

Usage:
  tools/check_shapes_pr.py [--base BASE_REF]

Looks at files changed relative to BASE_REF (default: origin/main) and extracts
occurrences of `shape` values in Terraform/JSON/CLI usages. Fails with exit
code 1 if any disallowed shapes are found.
"""
import argparse
import json
import os
import re
import shlex
import subprocess
import sys


def load_whitelist(path="config/allowed_shapes.json"):
    try:
        with open(path, "r") as f:
            data = json.load(f)
            return set(data.get("allowed_shapes", []))
    except FileNotFoundError:
        print(f"Whitelist file not found: {path}")
        return set()


def git_changed_files(base_ref):
    # Ensure base ref exists locally
    try:
        subprocess.run(["git", "fetch", "origin", base_ref], check=False, stdout=subprocess.DEVNULL)
    except Exception:
        pass
    cmd = ["git", "diff", "--name-only", f"{base_ref}...HEAD"]
    out = subprocess.run(cmd, check=False, stdout=subprocess.PIPE, text=True)
    files = [l.strip() for l in out.stdout.splitlines() if l.strip()]
    return files


SHAPE_PATTERNS = [
    re.compile(r"shape\s*=\s*\"?([A-Za-z0-9._-]+)\"?"),
    re.compile(r"\"shape\"\s*:\s*\"?([A-Za-z0-9._-]+)\"?"),
    re.compile(r"--shape\s+([A-Za-z0-9._-]+)"),
    re.compile(r"shape:\s*([A-Za-z0-9._-]+)")
]


def extract_shapes_from_text(text):
    found = []
    for p in SHAPE_PATTERNS:
        for m in p.findall(text):
            found.append(m)
    return found


def scan_files(file_list):
    shapes = {}
    for path in file_list:
        if not os.path.exists(path):
            continue
        try:
            with open(path, "r", errors="ignore") as f:
                txt = f.read()
        except Exception:
            continue
        found = extract_shapes_from_text(txt)
        if found:
            shapes[path] = found
    return shapes


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="origin/main", help="Base ref to diff against")
    ap.add_argument("--whitelist", default="config/allowed_shapes.json")
    args = ap.parse_args()

    allowed = load_whitelist(args.whitelist)
    if not allowed:
        print("Warning: allowed shapes whitelist is empty. Update config/allowed_shapes.json to control checks.")

    files = git_changed_files(args.base)
    if not files:
        print("No changed files detected relative to", args.base)
        return 0

    shapes_found = scan_files(files)
    disallowed = []
    for path, vals in shapes_found.items():
        for v in vals:
            if v not in allowed:
                disallowed.append((path, v))

    if disallowed:
        print("ERROR: Disallowed shapes found in PR changes:")
        for p, s in disallowed:
            print(f" - {p}: {s}")
        print("\nAllowed shapes (whitelist):")
        print(" ", ", ".join(sorted(allowed)))
        sys.exit(1)

    print("OK: No disallowed shapes detected.")
    return 0


if __name__ == '__main__':
    sys.exit(main())
