#!/usr/bin/env python3
import pathlib, sys, yaml, subprocess, re

ROOT = pathlib.Path(".")
SKILL_DIR = ROOT / ".github" / "skills"
CANONICAL = [
  ".github/workflows/**",
  ".github/actions/**",
  ".github/skills/**",
  "infra/**",
  "terraform/**",
  "scripts/**",
  "secrets/**",
  "credentials/**",
  "cloud-credentials/**",
  "**/*.pem",
  "**/*.key",
  "**/*.p12",
  ".env*",
  ".docker/config.json",
  "kms/**",
  "keys/**",
  "ci/**",
]

def load_text(p):
    return p.read_text(encoding="utf-8")

def write_text(p, s):
    p.write_text(s, encoding="utf-8")

def merge_frontmatter(text):
    if not text.startswith("---"):
        return text, False
    parts = text.split("---", 2)
    # parts: ['', frontmatter, rest]
    fm_text = parts[1]
    rest = parts[2] if len(parts) > 2 else ""
    try:
        fm = yaml.safe_load(fm_text) or {}
    except Exception:
        # Try sanitizing unquoted list items (e.g. glob patterns like **/*.pem)
        def repl(m):
            item = m.group(1).strip()
            if item.startswith('"') or item.startswith("'"):
                return m.group(0)
            item_escaped = item.replace('"', '\\"')
            return "- \"" + item_escaped + "\""
        fm_text_sanitized = re.sub(r'^\s*-\s+(.+)$', repl, fm_text, flags=re.MULTILINE)
        fm = yaml.safe_load(fm_text_sanitized) or {}
    existing = fm.get("do_not_edit_paths", [])
    merged = list(dict.fromkeys(existing + CANONICAL))
    fm["do_not_edit_paths"] = merged
    new_fm_text = yaml.safe_dump(fm, sort_keys=False).strip()+"\n"
    new_text = "---\n" + new_fm_text + "---" + rest
    return new_text, True


def validate_yaml_in_frontmatter_text(text):
    if not text.startswith("---"):
        return False, "no frontmatter"
    parts = text.split("---", 2)
    fm_text = parts[1]
    try:
        yaml.safe_load(fm_text)
        return True, ""
    except Exception as e:
        return False, str(e)

def ensure_guidance(text):
    guidance = "Agent guidance: Do not modify files listed in `do_not_edit_paths` without explicit human approval; produce a draft and open a ticket.\n"
    if guidance in text:
        return text, False
    # insert guidance after frontmatter
    if text.startswith("---"):
        parts = text.split("---", 2)
        rest = parts[2] if len(parts) > 2 else ""
        new_text = parts[0] + "---" + parts[1] + "---\n" + guidance + rest
        return new_text, True
    else:
        return guidance + "\n" + text, True

def validate_yaml_in_frontmatter(path):
    text = load_text(path)
    if not text.startswith("---"):
        return False, "no frontmatter"
    parts = text.split("---",2)
    fm_text = parts[1]
    try:
        yaml.safe_load(fm_text)
        return True, ""
    except Exception as e:
        return False, str(e)

def main():
    changed = []
    for d in SKILL_DIR.iterdir():
        if not d.is_dir():
            continue
        f = d / "SKILL.md"
        if not f.exists():
            continue
        txt = load_text(f)
        txt, changed1 = merge_frontmatter(txt)
        txt, changed2 = ensure_guidance(txt)
        if changed1 or changed2:
            valid, err = validate_yaml_in_frontmatter(f)
            if not valid:
                print(f"WARNING: original frontmatter for {f} failed YAML validation: {err}")
            write_text(f, txt)
            changed.append(str(f))
    if not changed:
        print("No files changed.")
        return
    print("Files updated:\n" + "\n".join(changed))
    # Commit & push
    subprocess.run(["git", "add"] + changed, check=True)
    subprocess.run(["git", "commit", "-m", "chore(agent-safety): add canonical do_not_edit_paths to skills"], check=True)
    subprocess.run(["git", "push", "origin", "main"], check=True)
    print("Committed and pushed to main.")

if __name__ == "__main__":
    main()