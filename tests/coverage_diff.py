#!/usr/bin/env python3
"""
Compare two coverage directories: what a change did to the test suite's
coverage.

    python3 coverage_diff.py <old coverage dir> <new coverage dir> [--base REV --head REV]

With C, D the lines covered and the executable lines of the old coverage,
A the lines newly covered and B the executable lines added (removed when
negative):

    coverage gain = (C+A)/(D+B) - C/D

so it shows whether a change in the percentage comes from more lines being
covered or from lines being added or removed. Files whose numbers changed are
listed. With --base and --head, the lines the change added are looked up in
the new coverage and the executable ones no test executed are listed: those
are the gaps the change introduced. --markdown formats for a pull-request
comment; --note lines are printed under the title.
"""
import argparse
import re
import subprocess
import sys

from coverage_common import (REPO_DIR, SOURCE_DIRS, parse_aggregated_gcov,
                             parse_report, read_metadata, resolve_rev)
from glob import glob
import os


def added_lines(base, head, repo=REPO_DIR):
    """{"../amr/x.f90": [new line numbers added]} from git diff -U0."""
    args = ["git", "-C", repo, "diff", "-U0", base] + ([] if head == "WORKTREE" else [head]) \
        + ["--"] + list(SOURCE_DIRS)
    out = subprocess.run(args, capture_output=True, text=True, errors="replace").stdout
    added, current = {}, None
    for line in out.splitlines():
        if line.startswith("+++ "):
            path = line[4:]
            current = "../" + path[2:] if path.startswith("b/") else None
            if current:
                added.setdefault(current, [])
        elif line.startswith("@@") and current:
            m = re.match(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@", line)
            start, n = int(m.group(1)), int(m.group(2)) if m.group(2) is not None else 1
            added[current] += list(range(start, start + n))
    return added


def ranges(numbers):
    """[1,2,3,7] -> "1-3, 7"."""
    out, start, prev = [], None, None
    for n in sorted(numbers) + [None]:
        if start is None:
            start = prev = n
        elif n is not None and n == prev + 1:
            prev = n
        else:
            out.append(f"{start}" if start == prev else f"{start}-{prev}")
            start = prev = n
    return ", ".join(out)


def added_lines_coverage(new_dir, base, head, repo):
    """
    Per file with added lines: (executable, executed, never compiled,
    [uncovered line numbers]) according to the new coverage.
    """
    gcov = {}
    for path in glob(os.path.join(new_dir, "gcov_files", "*_aggregated.gcov")):
        source, lines = parse_aggregated_gcov(path)
        gcov[source] = lines
    result = {}
    for source, numbers in added_lines(base, head, repo).items():
        if not numbers:
            continue
        lines = gcov.get(source)
        if lines is None:
            result[source] = None      # not compiled by any build
            continue
        executable = executed = notbuilt = 0
        uncovered = []
        for n in numbers:
            count = lines.get(n, ("-", ""))[0]
            if count == "-":
                continue
            executable += 1
            if count == "-----":
                notbuilt += 1
            elif count == 0:
                uncovered.append(n)
            else:
                executed += 1
        result[source] = (executable, executed, notbuilt, uncovered)
    return result


def pct(cov, tot):
    return 100.0 * cov / tot if tot else 0.0


def compare(old_dir, new_dir):
    old, old_total = parse_report(os.path.join(old_dir, "coverage_report.txt"))
    new, new_total = parse_report(os.path.join(new_dir, "coverage_report.txt"))
    C, D = old_total[0], old_total[1]
    A, B = new_total[0] - C, new_total[1] - D
    rows = []
    for source in sorted(set(old) | set(new)):
        o, n = old.get(source), new.get(source)
        if o == n:
            continue
        rows.append((source, o, n))
    return {"A": A, "B": B, "C": C, "D": D, "old_pct": pct(C, D), "new_pct": pct(C + A, D + B),
            "old_notbuilt": old_total[2], "new_notbuilt": new_total[2], "rows": rows}


def fmt_ratio(r):
    return "—" if r is None else f"{r[0]}/{r[1]}"


def fmt_pct(r):
    return "" if r is None else f"{pct(r[0], r[1]):.1f}%"


def render(cmp, added, old_dir, new_dir, notes, markdown):
    old_meta, new_meta = read_metadata(os.path.join(old_dir, "coverage_metadata.txt")), \
        read_metadata(os.path.join(new_dir, "coverage_metadata.txt"))
    gain = cmp["new_pct"] - cmp["old_pct"]
    sign = "+" if gain >= 0 else ""
    out = []
    if markdown:
        out.append(f"## Test-suite coverage: {cmp['old_pct']:.2f}% → {cmp['new_pct']:.2f}% ({sign}{gain:.2f} points)")
    else:
        out.append(f"Test-suite coverage: {cmp['old_pct']:.2f}% -> {cmp['new_pct']:.2f}% ({sign}{gain:.2f} points)")
    for n in notes:
        out.append(f"{n}  " if markdown else n)
    out.append("")
    table = [("lines newly covered (A)", f"{cmp['A']:+d}"),
             ("executable lines added (B)", f"{cmp['B']:+d}"),
             ("lines covered before (C)", f"{cmp['C']}"),
             ("executable lines before (D)", f"{cmp['D']}"),
             ("coverage gain (C+A)/(D+B) − C/D", f"{sign}{gain:.3f} points"),
             ("never-compiled lines", f"{cmp['old_notbuilt']} → {cmp['new_notbuilt']}")]
    if markdown:
        out.append("| | |")
        out.append("|---|---:|")
        out += [f"| {k} | {v} |" for k, v in table]
    else:
        out += [f"  {k:36s} {v}" for k, v in table]
    out.append("")

    rows = cmp["rows"]
    if rows:
        title = f"{len(rows)} files changed their numbers"
        hdr = ["file", "before", "after", "ΔA", "ΔB", "before %", "after %"]
        body = []
        for source, o, n in rows:
            dA = (n[0] if n else 0) - (o[0] if o else 0)
            dB = (n[1] if n else 0) - (o[1] if o else 0)
            body.append([source[3:], fmt_ratio(o), fmt_ratio(n), f"{dA:+d}", f"{dB:+d}", fmt_pct(o), fmt_pct(n)])
        if markdown:
            out.append(f"<details><summary>{title}</summary>\n")
            out.append("| " + " | ".join(hdr) + " |")
            out.append("|---|---:|---:|---:|---:|---:|---:|")
            out += ["| " + " | ".join(r) + " |" for r in body]
            out.append("\n</details>")
        else:
            out.append(title)
            out += ["  " + "  ".join(f"{c:>{w}}" for c, w in zip(r, (36, 10, 10, 5, 5, 8, 8))) for r in body]
        out.append("")
    else:
        out.append("No file changed its numbers." if not markdown else "No file changed its numbers.\n")

    if added is not None:
        exe = sum(v[0] for v in added.values() if v)
        run = sum(v[1] for v in added.values() if v)
        nb = sum(v[2] for v in added.values() if v)
        gaps = {s: v[3] for s, v in added.items() if v and v[3]}
        uncompiled = [s for s, v in added.items() if v is None]
        head = f"Lines added by the change: {exe} executable, {run} executed by the suite"
        if nb:
            head += f", {nb} compiled by no build"
        out.append(("**" + head + "**") if markdown else head)
        if gaps:
            if markdown:
                out.append("\n<details><summary>Added lines no test executes</summary>\n")
                out += [f"- `{s[3:]}`: {ranges(v)}" for s, v in sorted(gaps.items())]
                out.append("\n</details>")
            else:
                out += [f"  {s[3:]}: {ranges(v)}" for s, v in sorted(gaps.items())]
        if uncompiled:
            out.append(("\n" if markdown else "") + "Added files no build of the runs compiled: "
                       + ", ".join(s[3:] for s in uncompiled))
        out.append("")
    return "\n".join(out)


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("old_dir")
    p.add_argument("new_dir")
    p.add_argument("--base", help="commit of the old coverage, to list the lines the change added")
    p.add_argument("--head", default="HEAD", help="commit of the new coverage, or WORKTREE")
    p.add_argument("--repo", default=REPO_DIR)
    p.add_argument("--markdown", action="store_true")
    p.add_argument("--note", action="append", default=[], help="a line to print under the title (repeatable)")
    p.add_argument("--output", help="write here instead of stdout")
    a = p.parse_args()

    cmp = compare(a.old_dir, a.new_dir)
    added = None
    if a.base:
        added = added_lines_coverage(a.new_dir, resolve_rev(a.base, a.repo), resolve_rev(a.head, a.repo), a.repo)
    text = render(cmp, added, a.old_dir, a.new_dir, a.note, a.markdown)
    if a.output:
        open(a.output, "w").write(text + "\n")
    else:
        print(text)
