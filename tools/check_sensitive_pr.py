#!/usr/bin/env python3
"""
Check changed files in a PR and fail if any touch a sensitive path pattern.

This script expects to run in CI where the repo is checked out and `origin` is available.
It reads the base ref from the environment variable `BASE_REF` (e.g., 'main').
"""
import os
import subprocess
import sys
from fnmatch import fnmatch


SENSITIVE_PATTERNS = [
    ".github/workflows/**",
    "scripts/rotate-oci-key.sh",
    "scripts/bootstrap-example.sh",
    "scripts/install-oci-noninteractive.sh",
    "infra/**",
    "terraform/**",
    "secrets/**",
    "**/*.pem",
    "**/*.key",
    ".env*",
]


def git_changed_files(base_ref: str):
    subprocess.check_call(["git", "fetch", "origin", base_ref])
    cmd = ["git", "diff", "--name-only", f"origin/{base_ref}...HEAD"]
    out = subprocess.check_output(cmd, text=True)
    return [l.strip() for l in out.splitlines() if l.strip()]


def matches_sensitive(path: str):
    # Normalize to posix-style
    p = path.replace("\\", "/")
    for pat in SENSITIVE_PATTERNS:
        # fnmatch with recursive ** support
        if fnmatch(p, pat):
            return True
    return False


def main():
    base = os.environ.get("BASE_REF") or os.environ.get("GITHUB_BASE_REF") or "main"
    try:
        changed = git_changed_files(base)
    except subprocess.CalledProcessError as e:
        print("Failed to get changed files:", e, file=sys.stderr)
        sys.exit(1)

    sensitive = [f for f in changed if matches_sensitive(f)]
    if sensitive:
        print("ERROR: PR modifies sensitive files which require manual review:")
        for s in sensitive:
            print(" -", s)
        print("If this change is intentional, please open a ticket and request an exception.")
        sys.exit(2)

    print("No sensitive-file modifications detected.")


if __name__ == "__main__":
    main()
