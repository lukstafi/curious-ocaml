#!/usr/bin/env python3
"""Check maintained manuscript structure and explicit example classification."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
paths = [root / f"chapter{i}/README.md" for i in range(1, 13)]
paths += sorted((root / "projects").glob("*/README.md"))
errors = []
for path in paths:
    lines = path.read_text().splitlines()
    fence = False
    for i, line in enumerate(lines):
        match = re.match(r"\s*```(.*)$", line)
        if not match:
            continue
        if fence:
            if match.group(1).strip():
                errors.append(f"{path.relative_to(root)}:{i+1}: nested or unclosed fence")
            fence = False
        else:
            fence = True
            info = match.group(1).strip()
            if not info:
                errors.append(f"{path.relative_to(root)}:{i+1}: classify block as ocaml or text")
            if "skip" in info and not any("book-skip:" in x for x in lines[max(0, i-3):i]):
                errors.append(f"{path.relative_to(root)}:{i+1}: skipped block needs a book-skip reason")
    if fence:
        errors.append(f"{path.relative_to(root)}: unclosed fence")
    if path.parent.name.startswith("chapter"):
        for required in ["**Prerequisites:", "**Route:"]:
            if required not in path.read_text():
                errors.append(f"{path.relative_to(root)}: missing {required}")
first_rule = (root / "dune").read_text().split('(target old_lectures_as_book.md)')[0]
actual = [int(i) for i in re.findall(r'\(cat chapter(\d+)/README.md\)', first_rule)]
expected = [1, 2, 3, 5, 4, 6, 11, 7, 8, 9, 10, 12]
if actual != expected:
    errors.append(f"combined manuscript order {actual} differs from {expected}")
for path in paths[:12]:
    if any(token in path.read_text() for token in ["\nRUNTIME\n", "\nTRANSITION\n", "\nBINDING\n"]):
        errors.append(f"{path}: unresolved authoring placeholder")
if errors:
    raise SystemExit("\n".join(errors))
print(f"Book structure and block classifications: {len(paths)} sources checked.")
