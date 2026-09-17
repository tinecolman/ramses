#!/usr/bin/env python3
"""
Compare two coverage directories: what a change did to the test suite's
coverage.

    python3 coverage_diff.py <old coverage dir> <new coverage dir> [--base REV --head REV]

With C, E the covered and the executable lines of the old coverage, and
ΔC, ΔE their changes (ΔE negative when lines were removed):

    coverage gain = (C+ΔC)/(E+ΔE) - C/E

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
    result, texts = {}, {}
    for source, numbers in added_lines(base, head, repo).items():
        if not numbers:
            continue
        lines = gcov.get(source)
        if lines is None:
            result[source] = None      # not compiled by any build
            continue
        texts[source] = {n: lines[n][1] for n in numbers if n in lines}
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
    return result, texts


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


def render(cmp, added, old_dir, new_dir, notes, markdown, texts=None):
    new_meta = read_metadata(os.path.join(new_dir, "coverage_metadata.txt"))
    C, E = cmp["C"], cmp["D"]
    dC, dE = cmp["A"], cmp["B"]
    gain = cmp["new_pct"] - cmp["old_pct"]
    sign = "+" if gain >= 0 else ""
    arrow = "→" if markdown else "->"
    out = []
    title = f"Test-suite coverage: {cmp['old_pct']:.2f}% {arrow} {cmp['new_pct']:.2f}% ({sign}{gain:.2f} points)"
    out.append(f"## {title}" if markdown else title)
    for n in notes:
        out.append(f"{n}  " if markdown else n)
    kept_section = []
    if new_meta.get("kind") == "incremental":
        rerun = new_meta.get("tests_rerun", "").split()
        text = f"This is an estimate based on {len(rerun)} selected test(s)."
        out.append(f"**{text}**  " if markdown else text)
        # the tests that reached a changed file but were not re-run: their
        # baseline coverage of the lines that still exist was kept
        kept = [k for k in new_meta.get("tests_kept", "").split() if "=" in k]
        for item in kept:
            source, tests = item.split("=", 1)
            kept_section.append((source[3:], tests.replace(",", ", ")))
    out.append("")

    rows = [("covered lines C", f"{C}", f"{C + dC}", f"{dC:+d}"),
            ("executable lines E", f"{E}", f"{E + dE}", f"{dE:+d}"),
            ("coverage C/E", f"{cmp['old_pct']:.2f}%", f"{cmp['new_pct']:.2f}%", f"{sign}{gain:.2f} points"),
            ("never-compiled lines", f"{cmp['old_notbuilt']}", f"{cmp['new_notbuilt']}",
             f"{cmp['new_notbuilt'] - cmp['old_notbuilt']:+d}")]
    if markdown:
        out.append("| | before | after | Δ |")
        out.append("|---|---:|---:|---:|")
        out += [f"| {k} | {b} | {a} | {d} |" for k, b, a, d in rows]
    else:
        out.append(f"  {'':22s} {'before':>10} {'after':>10} {'delta':>14}")
        out += [f"  {k:22s} {b:>10} {a:>10} {d:>14}" for k, b, a, d in rows]
    out.append("")

    files = cmp["rows"]
    if files:
        title = f"{len(files)} files changed their numbers"
        hdr = ["file", "C/E before", "C/E after", "ΔC", "ΔE", "% before", "% after"]
        body = []
        for source, o, n in files:
            d_c = (n[0] if n else 0) - (o[0] if o else 0)
            d_e = (n[1] if n else 0) - (o[1] if o else 0)
            body.append([source[3:], fmt_ratio(o), fmt_ratio(n), f"{d_c:+d}", f"{d_e:+d}", fmt_pct(o), fmt_pct(n)])
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
        out.append("No file changed its numbers.")
        out.append("")

    if kept_section:
        title = "Tests not re-run, whose baseline coverage of the changed files was kept"
        if markdown:
            out.append(f"<details><summary>{title}</summary>\n")
            out += [f"- `{source}`: {tests}" for source, tests in kept_section]
            out.append("\n</details>\n")
        else:
            out.append(title + ":")
            out += [f"  {source}: {tests}" for source, tests in kept_section]
            out.append("")

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
            items = []
            for source, numbers in sorted(gaps.items()):
                for first, last in blocks(numbers):
                    text = (texts or {}).get(source, {}).get(first, "").strip()
                    where = f"{source[3:]}:{first}" if first == last else f"{source[3:]}:{first}-{last}"
                    if markdown:
                        items.append(f"- `{where}` `{text}`" + (f" (+{last - first} more lines)" if last > first else ""))
                    else:
                        items.append(f"  {where}  {text}" + (f" (+{last - first} more lines)" if last > first else ""))
            if markdown:
                out.append(f"\n<details><summary>Added uncovered lines ({len(items)})</summary>\n")
                out += items
                out.append("\n</details>")
            else:
                out.append("Added uncovered lines:")
                out += items
        if uncompiled:
            out.append(("\n" if markdown else "") + "Added files no build of the runs compiled: "
                       + ", ".join(s[3:] for s in uncompiled))
        out.append("")
    return "\n".join(out)


def blocks(numbers):
    """[1,2,3,7] -> [(1,3), (7,7)]."""
    out, start, prev = [], None, None
    for n in sorted(numbers) + [None]:
        if start is None:
            start = prev = n
        elif n is not None and n == prev + 1:
            prev = n
        else:
            out.append((start, prev))
            start = prev = n
    return out

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
    added, texts = None, None
    if a.base:
        added, texts = added_lines_coverage(a.new_dir, resolve_rev(a.base, a.repo), resolve_rev(a.head, a.repo), a.repo)
    text = render(cmp, added, a.old_dir, a.new_dir, a.note, a.markdown, texts)
    if a.output:
        open(a.output, "w").write(text + "\n")
    else:
        print(text)
