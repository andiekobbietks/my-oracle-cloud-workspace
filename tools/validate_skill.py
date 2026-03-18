#!/usr/bin/env python3
"""
tools/validate_skill.py
Usage: python tools/validate_skill.py path/to/SKILL.md
Exits 0 if OK, non-zero on error. Prints diagnostic messages.
"""
import sys
import os
import re
import glob
import subprocess
import yaml

RE_SECRET = re.compile(
    r"AKIA[0-9A-Z]{16}|BEGIN .*PRIVATE KEY|password\s*=|token\s*=|\bsecret\b",
    re.I,
)

REQUIRED_FIELDS = ["name", "description"]
OPTIONAL_BUT_RECOMMENDED = ["usage", "applyTo"]


def load_frontmatter(path):
    text = open(path, "r", encoding="utf-8").read()
    if text.startswith("---"):
        parts = text.split("---", 2)
        if len(parts) >= 3:
            try:
                return yaml.safe_load(parts[1]), parts[2]
            except Exception as e:
                print(f"ERROR: could not parse YAML frontmatter in {path}: {e}")
                return None, parts[2]
    return None, text


def check_presence(d, path):
    ok = True
    for f in REQUIRED_FIELDS:
        if f not in d or not d[f]:
            print(f"ERROR: missing required field '{f}' in {path}")
            ok = False
    for f in OPTIONAL_BUT_RECOMMENDED:
        if f not in d or not d[f]:
            print(f"WARN: recommended field '{f}' missing in {path}")
    return ok


def check_usage_trigger(d, path):
    desc = d.get("description", "")
    if ":" not in desc and "use when" not in desc.lower() and "/" not in desc:
        print(
            f"WARN: description in {path} should include a short trigger phrase or example invocation"
        )
    return True


def find_asset_refs(md_body):
    # Match common asset references inside parentheses or after a colon
    return re.findall(
        r"(?:\(|:)\s*([^\s\)\'\"]+\.(?:md|js|py|sh|mustache|yaml|yml))",
        md_body,
    )


def _asset_exists(path, base_dir):
    p = path.strip()
    if p.startswith("http://") or p.startswith("https://"):
        return True
    # direct filesystem check
    candidate = os.path.join(base_dir, p)
    if os.path.exists(candidate):
        return True
    # glob expansion relative to base_dir
    try:
        matches = glob.glob(os.path.join(base_dir, p), recursive=True)
        if matches:
            return True
    except Exception:
        pass
    # try repo-root checks (use git to find repo root)
    try:
        proc = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=base_dir,
            capture_output=True,
            text=True,
            check=True,
        )
        repo_root = proc.stdout.strip()
    except Exception:
        repo_root = os.getcwd()

    candidate_repo = os.path.join(repo_root, p)
    if os.path.exists(candidate_repo):
        return True
    try:
        matches = glob.glob(os.path.join(repo_root, p), recursive=True)
        if matches:
            return True
    except Exception:
        pass
    # try git to see if file is tracked (works when invoked inside a git repo)
    try:
        res = subprocess.run([
            "git",
            "ls-files",
            "--error-unmatch",
            p,
        ], cwd=base_dir, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if res.returncode == 0:
            return True
    except Exception:
        pass
    return False


def check_assets(asset_list, base_dir):
    ok = True
    for p in asset_list:
        p_clean = p.strip()
        if not _asset_exists(p_clean, base_dir):
            print(f"ERROR: referenced asset not found: {p_clean}")
            ok = False
    return ok


def secret_scan(text, path):
    hits = RE_SECRET.findall(text)
    if hits:
        # Show only a short sample
        sample = list(dict.fromkeys(hits))[:5]
        print(f"ERROR: possible secret patterns found in {path}: {', '.join(sample)}")
        return False
    return True


def main():
    if len(sys.argv) < 2:
        print("Usage: tools/validate_skill.py path/to/SKILL.md")
        sys.exit(2)
    path = sys.argv[1]
    if not os.path.exists(path):
        print("File not found:", path)
        sys.exit(2)
    front, body = load_frontmatter(path)
    ok = True
    if front is None:
        print(f"ERROR: no YAML frontmatter found in {path}")
        ok = False
    else:
        ok &= check_presence(front, path)
        check_usage_trigger(front, path)
        assets = front.get("assets", []) if isinstance(front, dict) else []
        base_dir = os.path.dirname(path)
        for a in assets:
            if not os.path.exists(os.path.join(base_dir, a)):
                print(f"ERROR: asset listed in frontmatter not found: {a}")
                ok = False
    refs = find_asset_refs(body)
    if refs:
        base_dir = os.path.dirname(path)
        ok &= check_assets(refs, base_dir)
    ok &= secret_scan(yaml.dump(front) if front else "", path)
    ok &= secret_scan(body, path)
    if ok:
        print(f"OK: {path}")
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
