#!/usr/bin/env python3
"""Merge dotclaude/settings.hooks.json into ~/.claude/settings.json.

Merged rather than symlinked because settings.json also holds machine-local
state (permission allowlists with absolute paths, enabled plugins).
"""
import json
import os
import re
import sys

HOME = os.path.expanduser("~")
TARGET = os.path.join(HOME, ".claude", "settings.json")
FRAGMENT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "settings.hooks.json")


def script_key(entry):
    """Identity for upsert: match on script basename so re-running replaces
    rather than appends."""
    names = set()
    for h in entry.get("hooks", []):
        for m in re.findall(r"[\w.-]+\.(?:sh|py)", str(h.get("command", ""))):
            names.add(os.path.basename(m))
    return frozenset(names)


def main():
    with open(FRAGMENT) as fh:
        fragment = json.load(fh)

    if os.path.exists(TARGET):
        with open(TARGET) as fh:
            try:
                settings = json.load(fh)
            except json.JSONDecodeError as exc:
                print(f"error: {TARGET} is not valid JSON ({exc}) -- refusing to touch it")
                return 1
    else:
        settings = {}

    settings.setdefault("hooks", {})
    changed = False

    for event, entries in fragment.get("hooks", {}).items():
        existing = settings["hooks"].setdefault(event, [])
        for entry in entries:
            key = script_key(entry)
            if not key:
                continue
            for i, cur in enumerate(existing):
                if script_key(cur) == key:
                    if cur != entry:
                        existing[i] = entry
                        changed = True
                        print(f"updated {event} hook: {' '.join(sorted(key))}")
                    break
            else:
                existing.append(entry)
                changed = True
                print(f"added {event} hook: {' '.join(sorted(key))}")

    if not changed:
        print("claude hooks already up to date")
        return 0

    os.makedirs(os.path.dirname(TARGET), exist_ok=True)
    tmp = TARGET + ".tmp"
    with open(tmp, "w") as fh:
        json.dump(settings, fh, indent=2)
        fh.write("\n")
    os.replace(tmp, TARGET)
    print(f"wrote {TARGET}")
    return 0


sys.exit(main())
