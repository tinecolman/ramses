#!/usr/bin/env python3
"""
Which tests of the suite can change their coverage between two commits.

    python3 coverage_select.py --baseline <coverage dir> --base <rev> --head <rev|WORKTREE>

Every source file touched by the diff is looked up in the baseline's
coverage_tests.json (tests that executed it) and coverage_built.json (tests
that compiled it). A file whose executable statements are unchanged (comments,
blank lines, formatting, declarations without a value) selects nothing: no
test can cover it differently, coverage_merge.py only shifts its line numbers.
A new source file selects nothing by itself: it only runs if an existing file
starts to use it, and that file's tests are selected. Changes to a test's own
directory select that test; changes to how everything is built or run (the
compiler flags of bin/Makefile, the runner scripts) select every test.

Prints a JSON document; --summary adds a readable summary on stderr.
"""
import argparse
import json
import os
import sys
from collections import defaultdict

from coverage_common import (RUNNER_FILES, Baseline, REPO_DIR, family_of,
                             git_lines, is_cosmetic, list_tests,
                             makefile_is_object_lists_only, name_status,
                             resolve_rev, source_path, test_to_label)


def select(baseline, base, head, tests, repo=REPO_DIR, force_all=False):
    reasons = defaultdict(set)
    changed, cosmetic, new, deleted, removed_tests, notes = [], [], [], [], [], []
    everything = None

    def select_all(why):
        nonlocal everything
        everything = everything or why

    def tests_of(source, why):
        reaching = baseline.tests_reaching(source)
        if not reaching:
            compiling = baseline.tests_compiling(source)
            if compiling is None:
                notes.append(f"{source}: no test executed it and the baseline has no "
                             "coverage_built.json; selecting every test")
                select_all(f"{source} has no per-test build information")
                return
            reaching = compiling
            why += " (compiled, never executed)"
        for t in reaching:
            reasons[t].add(why)

    for status, old_path, new_path in name_status(base, head, repo):
        path = new_path if status != "D" else old_path
        src_new, src_old = source_path(new_path), source_path(old_path)

        if status == "D" and src_old:
            deleted.append(src_old)
            tests_of(src_old, f"{old_path} deleted")
        elif status == "R":
            deleted.append(src_old)
            new.append(src_new)
            tests_of(src_old, f"{old_path} renamed to {new_path}")
        elif status == "A" and src_new:
            new.append(src_new)
            notes.append(f"{new_path} is new: covered through the changed files that use it")
        elif src_new:
            old_lines = git_lines(base, old_path, repo)
            new_lines = git_lines(head, new_path, repo)
            if old_lines is not None and new_lines is not None and is_cosmetic(old_lines, new_lines):
                cosmetic.append(src_new)
            else:
                changed.append(src_new)
                tests_of(src_new, f"{new_path} changed")
        elif path.startswith("bin/Makefile"):
            old_lines = git_lines(base, old_path, repo) or []
            new_lines = git_lines(head, new_path, repo) or []
            if makefile_is_object_lists_only(old_lines, new_lines):
                notes.append(f"{path}: only the object lists changed")
            else:
                select_all(f"{path} changed")
        elif path in RUNNER_FILES:
            select_all(f"{path} changed")
        elif path.startswith("tests/"):
            parts = path.split("/")
            if len(parts) >= 4 and f"{parts[1]}/{parts[2]}" in tests:
                reasons[f"{parts[1]}/{parts[2]}"].add(f"{path} {'added' if status == 'A' else 'changed'}")
            elif len(parts) >= 4 and status == "D":
                removed_tests.append(f"{parts[1]}/{parts[2]}")

    if force_all:
        select_all("requested")
    if everything:
        for t in tests:
            reasons[t].add(everything)

    selected = sorted(t for t in reasons if t in tests)
    unknown = sorted(t for t in reasons if t not in tests)
    for t in unknown:
        notes.append(f"{t} has baseline data but no longer exists in tests/")
    removed_tests = sorted(set(removed_tests) - set(selected))

    by_family = defaultdict(list)
    for t in selected:
        by_family[family_of(t)].append(t)
    return {
        "base": base, "head": head,
        "baseline": baseline.dir, "baseline_commit": baseline.commit,
        "tests": selected,
        "labels": [test_to_label(t) for t in selected],
        "by_family": dict(by_family),
        "matrix": [{"family": f, "tests": ",".join(ts)} for f, ts in sorted(by_family.items())],
        "all": bool(everything),
        "all_reason": everything or "",
        "changed_sources": sorted(set(changed)),
        "cosmetic_sources": sorted(set(cosmetic)),
        "new_sources": sorted(set(new)),
        "deleted_sources": sorted(set(deleted)),
        "removed_tests": removed_tests,
        "reasons": {t: sorted(r) for t, r in sorted(reasons.items())},
        "notes": notes,
    }


def summary(result):
    lines = [f"Base {result['base'][:10]} -> head {result['head'][:10]}, "
             f"baseline {result['baseline_commit'][:10] or '?'}"]
    for key in ("changed_sources", "cosmetic_sources", "new_sources", "deleted_sources"):
        if result[key]:
            lines.append(f"  {key.replace('_', ' ')}: {', '.join(result[key])}")
    if result["all"]:
        lines.append("  every test is selected: " + result["all_reason"])
    lines.append(f"  {len(result['tests'])} tests to run" +
                 (": " + " ".join(result["tests"]) if result["tests"] else ""))
    if result["removed_tests"]:
        lines.append(f"  removed tests: {', '.join(result['removed_tests'])}")
    for n in result["notes"]:
        lines.append(f"  note: {n}")
    return "\n".join(lines)


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--baseline", required=True, help="coverage directory of the base commit")
    p.add_argument("--base", required=True, help="commit the baseline describes")
    p.add_argument("--head", default="HEAD", help="commit to select for, or WORKTREE (default HEAD)")
    p.add_argument("--repo", default=REPO_DIR)
    p.add_argument("--all", action="store_true", help="select every test whatever the diff")
    p.add_argument("--output", help="write the JSON here instead of stdout")
    p.add_argument("--summary", action="store_true", help="print a readable summary on stderr")
    a = p.parse_args()

    tests = list_tests(os.path.join(a.repo, "tests"))
    baseline = Baseline(a.baseline, tests)
    result = select(baseline, resolve_rev(a.base, a.repo), resolve_rev(a.head, a.repo),
                    tests, a.repo, a.all)
    if baseline.unknown_labels:
        result["notes"].append("baseline labels of tests that no longer exist: "
                               + ", ".join(sorted(baseline.unknown_labels)))
    text = json.dumps(result, indent=1)
    if a.output:
        with open(a.output, "w") as f:
            f.write(text + "\n")
    else:
        print(text)
    if a.summary:
        print(summary(result), file=sys.stderr)
