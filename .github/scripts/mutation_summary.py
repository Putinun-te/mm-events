#!/usr/bin/env python3
"""Print a Markdown summary of a PIT run (target/pit-reports/mutations.xml).

Usage: mutation_summary.py <main_backend dir>  >> "$GITHUB_STEP_SUMMARY"
"""
import re
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path


def main():
    backend = Path(sys.argv[1] if len(sys.argv) > 1 else "main_backend")
    report = backend / "target/pit-reports/mutations.xml"
    out = ["## Mutation testing (PIT)", ""]
    if not report.exists():
        print("\n".join(out + ["No PIT report found.", ""]))
        return

    per_class = defaultdict(lambda: [0, 0])
    survivors = []
    for mutation in ET.parse(report).getroot().iter("mutation"):
        cls = mutation.findtext("mutatedClass", "").rsplit(".", 1)[-1]
        per_class[cls][0] += 1
        if mutation.get("detected") == "true":
            per_class[cls][1] += 1
        else:
            survivors.append((cls, mutation.findtext("lineNumber"), mutation.findtext("description", "")))

    total = sum(t for t, _ in per_class.values())
    killed = sum(k for _, k in per_class.values())
    pom = (backend / "pom.xml").read_text()
    gate = re.search(r"<pit\.mutationThreshold>(\d+)</pit\.mutationThreshold>", pom)

    out.append(f"**Mutation score: {100 * killed / total:.1f}%** ({killed} of {total} mutants killed)"
               + (f", gate {gate.group(1)}%" if gate else ""))
    out += ["", "| Class | Killed | Score |", "|---|---|---|"]
    for cls, (t, k) in sorted(per_class.items(), key=lambda item: item[1][1] / item[1][0]):
        out.append(f"| `{cls}` | {k}/{t} | {100 * k / t:.0f}% |")
    if survivors:
        out += ["", "<details><summary>Surviving mutants</summary>", ""]
        out += [f"- `{c}` line {line}: {desc}" for c, line, desc in survivors[:50]]
        out += ["", "</details>"]
    print("\n".join(out + [""]))


if __name__ == "__main__":
    main()
