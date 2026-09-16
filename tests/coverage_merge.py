#!/usr/bin/env python3
"""
Merge the coverage of a partial run of the test suite into a full baseline.

    python3 coverage_merge.py --baseline <coverage dir> --runs <coverage dir>... --out <dir>

The runs are coverage directories made by `run_test_suite.sh -s -t ...` on the
source checked out in the repository now (the merge reads the current source).
The tests they contain, T, are the tests coverage_select.py chose for the
change between the baseline's commit and the current source. Per source file:

  unchanged   the baseline's lines; a line is covered when a baseline test
              outside T reached it, or a test of T reached it in the runs
  cosmetic    same, after moving the counts to the lines the statements now
              sit on (only comments, blank lines, formatting or declarations
              differ; checked, a mismatch is refused)
  changed     the runs for the tests of T; a baseline test outside T that
              reached the file keeps its coverage of the lines that still
              exist (matched by text), and is taken not to reach the added
              lines. That makes the result an estimate, noted in the
              metadata (tests_kept), which the monthly full run corrects.
  new         the runs only
  deleted     dropped

The output has the layout of a full run without gcov_per_test/, so it can be
the baseline of the next merge.
"""
import argparse
import os
import shutil
import subprocess
import sys
from collections import defaultdict
from datetime import datetime, timezone
from glob import glob

from coverage_common import (BIN_DIR, Baseline, REPO_DIR, list_tests,
                             label_to_test, statement_line_map,
                             test_to_label, text_line_map)
from multi_gcov_aggregator import (NOT_COVERABLE, GCovParser, build_records,
                                   distinct, is_declaration)


def read_source(path):
    if not os.path.exists(path):
        return None
    with open(path, errors="replace") as f:
        lines = f.read().split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    return lines


def not_coverable(content):
    s = content.strip()
    return bool(NOT_COVERABLE.match(s)) or is_declaration(s)


class Merge:
    def __init__(self, baseline, runs, tests, source_root, removed, allow_missing):
        self.baseline = baseline
        self.tests = tests
        self.source_root = source_root
        self.allow_missing = allow_missing
        self.errors = []
        self.status = defaultdict(list)   # unchanged/cosmetic/changed/new/deleted -> sources
        self.kept = {}                    # changed source -> baseline tests not re-run

        self.new = GCovParser(source_root)
        run_dirs = []
        self.new_records = []
        for run in runs:
            dirs = sorted(glob(os.path.join(run, "gcov_per_test", "*", "")))
            if not dirs:
                sys.exit(f"{run}: no gcov_per_test/ directory")
            run_dirs += dirs
            self.new_records += build_records(os.path.join(run, "build_records"))
        self.new.parse_directories(run_dirs)
        self.rerun = set()
        for builds in self.new.built_by.values():
            for label, _run in builds:
                t = label_to_test(label, tests)
                if t is None:
                    sys.exit(f"run label {label} is not a test of tests/")
                self.rerun.add(t)
        self.T = self.rerun | set(removed)

    def label(self, test):
        return test_to_label(test)

    def merged_line(self, source, old_line, old_count, content, new_line):
        """
        Count and tests of a baseline line after the merge: the baseline
        tests outside T that reached it, plus what the runs saw on new_line.
        """
        old_tests = self.baseline.covered_by.get(source, {}).get(old_line, [])
        rest = [t for t in old_tests if t not in self.T]
        dirs = [self.label(t) for t in rest]
        count = old_count if (rest and isinstance(old_count, int)) else (0 if isinstance(old_count, int) else "-")
        new_entry = self.new.coverage_data[source].get(new_line) if source in self.new.coverage_data else None
        if new_entry is not None:
            new_count, _content, new_dirs = new_entry
            if isinstance(new_count, int):
                # a test of T re-run: its old counts are inside old_count
                # already, so the counts are not summed. What matters is
                # zero or not; the tests are listed by name
                count = max(count if isinstance(count, int) else 0, new_count)
            dirs += [d for d in new_dirs if d not in dirs]
        return count, content, dirs

    def same_source(self, source, src):
        """Whether the runs' gcov files of `source` show the checked-out text."""
        for n, (_count, content, _dirs) in self.new.coverage_data[source].items():
            if n > len(src) or content.rstrip() != src[n-1].rstrip():
                return False
        return True

    def merge_file(self, source, base_lines, src):
        """Fill merged.coverage_data[source] for a file the baseline knows."""
        out = self.merged.coverage_data[source]
        old_text = [base_lines[n][1].rstrip() for n in sorted(base_lines)]
        if old_text == [l.rstrip() for l in src]:
            self.status["unchanged"].append(source)
            for n in sorted(base_lines):
                out[n] = self.merged_line(source, n, base_lines[n][0], base_lines[n][1], n)
            return True

        line_map = statement_line_map(old_text, src)
        if line_map is not None:
            unmapped = [n for n, (count, content) in base_lines.items()
                        if isinstance(count, int) and n not in line_map and not not_coverable(content)]
            if unmapped:
                self.errors.append(f"{source}: cosmetic change, but counted lines "
                                   f"{unmapped[:5]} have no statement to move to")
                return False
            self.status["cosmetic"].append(source)
            for n, content in enumerate(src, 1):
                out[n] = ("-", content, [])
            for old, new in line_map.items():
                if old in base_lines:
                    out[new] = self.merged_line(source, old, base_lines[old][0], src[new-1], new)
            return True

        # a real change: the runs give the file's lines; a baseline test
        # that reached the file but was not re-run keeps what it covered
        # on the lines that still exist, matched by their text
        if source not in self.new.coverage_data:
            self.errors.append(f"{source} changed, but no run compiled it")
            return False
        self.status["changed"].append(source)
        for n, entry in self.new.coverage_data[source].items():
            out[n] = entry
        missing = self.baseline.tests_reaching(source) - self.T
        if missing:
            self.kept[source] = sorted(missing)
            line_map = text_line_map(old_text, src)
            for old, (count, _content) in base_lines.items():
                # an executable line of the baseline (a count, 0 included)
                # that still exists: the builds of the tests not re-run
                # still compile it, and those tests still reach it or not
                if not isinstance(count, int) or old not in line_map:
                    continue
                keep = [t for t in self.baseline.covered_by.get(source, {}).get(old, []) if t in missing]
                new_line = line_map[old]
                new_count, content, dirs = out[new_line]
                if not isinstance(new_count, int):
                    if new_line not in self.new.coverage_data[source]:
                        continue      # not a line of the new gcov files
                    new_count = 0     # compiled only by a build not re-run
                dirs = list(dirs) + [self.label(t) for t in keep if self.label(t) not in dirs]
                out[new_line] = (max(new_count, 1 if keep else 0), content, dirs)
        return True

    def run(self):
        self.merged = GCovParser(self.source_root)
        base_gcov = self.baseline.gcov_files()
        sources = sorted(set(base_gcov) | set(self.new.coverage_data))
        for source in sources:
            src = read_source(os.path.normpath(os.path.join(self.source_root, source)))
            if src is None:
                self.status["deleted"].append(source)
                continue
            if source in self.new.coverage_data and not self.same_source(source, src):
                self.errors.append(f"{source}: the runs were made from another version of the "
                                   "source than the one checked out")
                continue
            if source in base_gcov:
                ok = self.merge_file(source, base_gcov[source], src)
            else:
                self.status["new"].append(source)
                for n, entry in self.new.coverage_data[source].items():
                    self.merged.coverage_data[source][n] = entry
                ok = True
            if not ok:
                continue
            # the builds that compile the file: the baseline's outside T,
            # plus those of the runs
            builders = self.baseline.tests_compiling(source)
            if builders is None and source in base_gcov:
                builders = self.baseline.all_tests()
            for t in (builders or set()):
                if t not in self.T:
                    self.merged.built_by[source].add((self.label(t), ""))
            self.merged.built_by[source] |= self.new.built_by.get(source, set())
        stale = [e for e in self.errors if "another version" in e]
        if stale or (self.errors and not self.allow_missing):
            sys.exit("Merge refused:\n  " + "\n  ".join(self.errors))
        for e in self.errors:
            print("Warning:", e, file=sys.stderr)
        records = self.baseline.records() + self.new_records
        if records:
            self.merged.mark_unbuilt(records)
        return self.merged, records


def write_records(out_dir, baseline, runs):
    """build_records/ of the merge: the baseline's, then the runs'."""
    dst = os.path.join(out_dir, "build_records")
    os.makedirs(dst, exist_ok=True)
    src = os.path.join(baseline.dir, "build_records")
    if os.path.isdir(src):
        for f in glob(os.path.join(src, "*.txt")):
            shutil.copy(f, dst)
    elif os.path.exists(os.path.join(baseline.dir, "coverage_metadata.txt")):
        shutil.copy(os.path.join(baseline.dir, "coverage_metadata.txt"),
                    os.path.join(dst, "baseline_metadata.txt"))
    for run in runs:
        for f in glob(os.path.join(run, "build_records", "*.txt")):
            with open(os.path.join(dst, os.path.basename(f)), "a") as o:
                o.write(open(f).read())


def write_metadata(out_dir, baseline, merge, commit, runs):
    with open(os.path.join(out_dir, "coverage_metadata.txt"), "w") as f:
        print("# Coverage merged by coverage_merge.py: a partial run added to a baseline.\n", file=f)
        print(f"date          : {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}", file=f)
        print(f"kind          : incremental", file=f)
        print(f"commit        : {commit}", file=f)
        print(f"commit_short  : {commit[:8]}", file=f)
        print(f"derived_from  : {baseline.commit}", file=f)
        print(f"baseline_kind : {baseline.metadata.get('kind', 'full')}", file=f)
        print(f"baseline_dir  : {baseline.dir}", file=f)
        print(f"runs          : {' '.join(runs)}", file=f)
        print(f"tests_rerun   : {' '.join(sorted(merge.rerun))}", file=f)
        print(f"tests_removed : {' '.join(sorted(merge.T - merge.rerun))}", file=f)
        for key in ("changed", "cosmetic", "new", "deleted"):
            print(f"files_{key:8s}: {' '.join(merge.status.get(key, []))}", file=f)
        # the estimate: tests that reached a changed file but were not re-run
        print("tests_kept    : " + " ".join(f"{s}={','.join(t)}" for s, t in sorted(merge.kept.items())), file=f)
        print(f"ntests        : {len(baseline.all_tests() - merge.T | merge.rerun)}", file=f)


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--baseline", required=True)
    p.add_argument("--runs", nargs="*", default=[], help="coverage directories of the partial runs (none when no test needed re-running)")
    p.add_argument("--out", required=True)
    p.add_argument("--source-root", default=BIN_DIR, help="where the gcov Source: paths are relative to")
    p.add_argument("--commit", help="commit the merged coverage describes (default: git HEAD)")
    p.add_argument("--removed-tests", default="", help="comma-separated tests deleted since the baseline")
    p.add_argument("--allow-missing", action="store_true",
                   help="merge even when a changed file was compiled by no run")
    a = p.parse_args()

    tests = list_tests()
    baseline = Baseline(a.baseline, tests)
    removed = [t for t in a.removed_tests.split(",") if t]
    merge = Merge(baseline, a.runs, tests, a.source_root, removed, a.allow_missing)
    merged, records = merge.run()

    if os.path.exists(a.out):
        shutil.rmtree(a.out)
    os.makedirs(a.out)
    merged.save_aggregated_coverage(a.out)
    write_records(a.out, baseline, a.runs)
    commit = a.commit or subprocess.run(["git", "-C", REPO_DIR, "rev-parse", "HEAD"],
                                        capture_output=True, text=True).stdout.strip()
    write_metadata(a.out, baseline, merge, commit, a.runs)
    for key in ("unchanged", "cosmetic", "changed", "new", "deleted"):
        n = len(merge.status.get(key, []))
        if n and key != "unchanged":
            print(f"{key:9s} {n:4d}  {' '.join(merge.status[key])}")
        elif n:
            print(f"{key:9s} {n:4d}")
    print(f"re-run tests: {' '.join(sorted(merge.rerun))}")
    for source, tests in sorted(merge.kept.items()):
        print(f"estimate: {source} kept the baseline coverage of {' '.join(tests)} (not re-run)")
    print(f"Merged coverage saved in directory: {a.out}")
