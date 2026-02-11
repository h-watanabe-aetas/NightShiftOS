#!/usr/bin/env python3
"""
Generate behave step stubs from Gherkin feature files.

This script is idempotent and overwrites the generated file.
"""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


FEATURE_DIR = Path("docs/tests/acceptance")
OUTPUT_FILE = FEATURE_DIR / "steps" / "generated_steps.py"
STEP_PATTERN = re.compile(r"^\s*(Given|When|Then|And|But)\s+(.+?)\s*$")


def safe_name(text: str) -> str:
    digest = hashlib.sha1(text.encode("utf-8")).hexdigest()[:8]
    return f"step_{digest}"


def collect_steps() -> list[str]:
    steps: list[str] = []
    for path in sorted(FEATURE_DIR.glob("*.feature")):
        for line in path.read_text(encoding="utf-8").splitlines():
            m = STEP_PATTERN.match(line)
            if m:
                steps.append(m.group(2))
    # Deduplicate while keeping order.
    seen = set()
    unique: list[str] = []
    for step in steps:
        if step not in seen:
            seen.add(step)
            unique.append(step)
    return unique


def render_module(steps: list[str]) -> str:
    lines: list[str] = []
    lines.append('"""Auto-generated behave step stubs. Do not edit manually."""')
    lines.append("")
    lines.append("from behave import step")
    lines.append("")
    lines.append("")
    for text in steps:
        fn = safe_name(text)
        escaped = text.replace("\\", "\\\\").replace("'", "\\'")
        lines.append(f"@step('{escaped}')")
        lines.append(f"def {fn}(context):")
        lines.append(f"    raise NotImplementedError('Step not implemented: {escaped}')")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    steps = collect_steps()
    OUTPUT_FILE.write_text(render_module(steps), encoding="utf-8")
    print(f"generated {OUTPUT_FILE} with {len(steps)} steps")


if __name__ == "__main__":
    main()
