#!/usr/bin/env python3
"""Resolve [%key:NAMESPACE::PATH%] references in a translations file.

Required because HA Core's build pipeline rewrites these references at release
time, while our sync just copies strings.json verbatim into translations/en.json.

Namespaces:
- common::<path>           -> homeassistant/strings.json under `common.<path>`
- component::<name>::<path> -> homeassistant/components/<name>/strings.json under `<path>`
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

RE_REF = re.compile(r"\[%key:([a-z0-9_]+(?:::(?:[a-z0-9_-]+))+)%\]")

_cache: dict[Path, dict] = {}


def load_json(path: Path) -> dict:
    if path not in _cache:
        with path.open(encoding="utf-8") as f:
            _cache[path] = json.load(f)
    return _cache[path]


def resolve_key(core_repo: Path, key: str) -> str:
    parts = key.split("::")
    if parts[0] == "common":
        data = load_json(core_repo / "homeassistant" / "strings.json")
        path = parts
    elif parts[0] == "component":
        domain = parts[1]
        data = load_json(
            core_repo / "homeassistant" / "components" / domain / "strings.json"
        )
        path = parts[2:]
    else:
        raise ValueError(f"Unknown reference namespace: {parts[0]!r} in {key!r}")

    cur = data
    for p in path:
        cur = cur[p]
    if not isinstance(cur, str):
        raise ValueError(f"Reference {key!r} does not resolve to a string")
    return substitute(core_repo, cur)


def substitute(core_repo: Path, value: str) -> str:
    while True:
        new = RE_REF.sub(lambda m: resolve_key(core_repo, m.group(1)), value)
        if new == value:
            return new
        value = new


def walk(core_repo: Path, obj):
    if isinstance(obj, dict):
        return {k: walk(core_repo, v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [walk(core_repo, v) for v in obj]
    if isinstance(obj, str):
        return substitute(core_repo, obj)
    return obj


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Usage: resolve-references.py <core-repo-root> <target-file>",
            file=sys.stderr,
        )
        return 2

    core_repo = Path(sys.argv[1])
    target = Path(sys.argv[2])

    data = json.loads(target.read_text(encoding="utf-8"))
    resolved = walk(core_repo, data)
    target.write_text(
        json.dumps(resolved, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f">> Resolved [%key:...%] references in {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
