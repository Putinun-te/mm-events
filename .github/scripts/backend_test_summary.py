#!/usr/bin/env python3
"""Print a Markdown test + coverage summary for the backend build.

Usage: backend_test_summary.py <main_backend dir>  >> "$GITHUB_STEP_SUMMARY"

Reads surefire/failsafe XML reports, the JaCoCo CSV reports and the coverage
gate from pom.xml. Works with whatever reports exist (e.g. unit tests only).
"""
import csv
import re
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path


def read_junit(report_dir):
    totals = {"tests": 0, "failures": 0, "errors": 0, "skipped": 0, "time": 0.0}
    failed = []
    for xml_file in sorted(Path(report_dir).glob("TEST-*.xml")):
        suite = ET.parse(xml_file).getroot()
        for key in ("tests", "failures", "errors", "skipped"):
            totals[key] += int(suite.get(key, 0))
        totals["time"] += float(suite.get("time", 0) or 0)
        for case in suite.iter("testcase"):
            if case.find("failure") is not None or case.find("error") is not None:
                failed.append(f"{case.get('classname')}.{case.get('name')}")
    return totals, failed


def read_jacoco(csv_file):
    per_pkg = defaultdict(lambda: [0, 0, 0, 0])  # line missed/covered, branch missed/covered
    for row in csv.DictReader(open(csv_file)):
        pkg = row["PACKAGE"]
        values = (row["LINE_MISSED"], row["LINE_COVERED"], row["BRANCH_MISSED"], row["BRANCH_COVERED"])
        for i, value in enumerate(values):
            per_pkg[pkg][i] += int(value)
    total = [sum(v[i] for v in per_pkg.values()) for i in range(4)]
    return per_pkg, total


def pct(missed, covered):
    return 100.0 * covered / (missed + covered) if missed + covered else None


def fmt(value):
    return "n/a" if value is None else f"{value:.1f}%"


def main():
    backend = Path(sys.argv[1] if len(sys.argv) > 1 else "main_backend")
    target = backend / "target"
    out = ["## Backend tests and coverage", ""]

    out += ["| Suite | Tests | Passed | Failed | Errors | Skipped | Test time (sum) |", "|---|---|---|---|---|---|---|"]
    all_failed = []
    for label, folder in (("Unit (surefire)", "surefire-reports"), ("Integration (failsafe)", "failsafe-reports")):
        if not (target / folder).is_dir():
            out.append(f"| {label} | not run | | | | | |")
            continue
        t, failed = read_junit(target / folder)
        passed = t["tests"] - t["failures"] - t["errors"] - t["skipped"]
        out.append(f"| {label} | {t['tests']} | {passed} | {t['failures']} | {t['errors']} | {t['skipped']} | {t['time']:.0f}s |")
        all_failed += failed
    out.append("")
    if all_failed:
        out += ["**Failed tests**", ""] + [f"- `{name}`" for name in all_failed[:50]] + [""]

    pom = (backend / "pom.xml").read_text()
    gate = {k: re.search(rf"<jacoco\.{k}>([0-9.]+)</jacoco\.{k}>", pom) for k in ("minLine", "minBranch")}
    gate = {k: float(m.group(1)) * 100 if m else None for k, m in gate.items()}

    reports = (("Unit + integration", target / "site/jacoco/jacoco.csv"), ("Unit only", target / "site/jacoco-unit/jacoco.csv"))
    shown = False
    for label, csv_file in reports:
        if not csv_file.exists():
            continue
        per_pkg, total = read_jacoco(csv_file)
        line, branch = pct(total[0], total[1]), pct(total[2], total[3])
        out += [f"### Coverage: {label}", ""]
        out += ["| | Line | Branch |", "|---|---|---|"]
        out.append(f"| **Total** | **{fmt(line)}** | **{fmt(branch)}** |")
        if label == "Unit + integration" and gate["minLine"] is not None:
            out.append(f"| Gate (minimum) | {gate['minLine']:.0f}% | {gate['minBranch']:.0f}% |")
        for pkg, v in sorted(per_pkg.items()):
            out.append(f"| `{pkg}` | {fmt(pct(v[0], v[1]))} | {fmt(pct(v[2], v[3]))} |")
        out.append("")
        shown = True
        if label == "Unit + integration":
            break  # the combined report already includes the unit tests
    if not shown:
        out += ["No JaCoCo report found.", ""]

    print("\n".join(out))


if __name__ == "__main__":
    main()
