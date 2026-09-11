#!/usr/bin/env python3
"""Attach per-routine test coverage to inventory.yaml.

Reads the aggregated .gcov files of a coverage run produced by
tests/run_test_suite.sh and counts, for every routine in the inventory, the
lines of its own body.

A routine that `contains` other routines is charged only for the lines outside
them: every line is attributed to the innermost routine whose span contains it,
so a parent and its contained routines partition the file between them and no
line is counted twice.

The four line states come from the aggregated files and mean what the coverage
report says they mean:

  <count>  executed          counted, covered
  #####    compiled, not run counted, uncovered
  -----    no build compiled it, because of a preprocessor directive
                             counted, uncovered -- reaching it needs another
                             build variant, not another namelist
  -        not executable    not counted

Usage:
    python3 doc/features_overview/derive_coverage.py --report
    python3 doc/features_overview/derive_coverage.py --write
    python3 doc/features_overview/derive_coverage.py --json out.json
"""
import os, re, sys, json, glob, argparse, collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
INV  = os.path.join(HERE, "inventory.yaml")
RUNS = os.path.join(ROOT, "tests", "coverage_*")

try:
    import yaml
except ImportError:
    sys.exit("needs PyYAML:  pip install pyyaml")

sys.path.insert(0, HERE)
from derive_omp import spans          # the routine-span parser, shared


def newest_run():
    """Most recent coverage directory that has aggregated files in it."""
    cands = [d for d in sorted(glob.glob(RUNS))
             if os.path.isdir(os.path.join(d, "gcov_files"))]
    return cands[-1] if cands else None


def load_markers(run):
    """{source path relative to the repo: {line number: marker}}"""
    out = {}
    for path in glob.glob(os.path.join(run, "gcov_files", "*.gcov")):
        src, rows = None, {}
        for line in open(path, errors="replace"):
            if line.startswith("Source:"):
                src = line.split(":", 1)[1].strip()
                continue
            i = line.find(':')
            if i == -1 or i > 30:
                continue
            j = i + 1 + line[i+1:].find(':')
            try:
                rows[int(line[i+1:j].strip())] = line[:i].strip()
            except ValueError:
                continue
        if src:
            out[re.sub(r'^(\.\./)+', '', src)] = rows
    return out


def owners(routine_spans, nlines):
    """line number -> innermost routine containing it."""
    owner = [None] * (nlines + 2)
    # widest span first, so a contained routine overwrites its parent
    for name, (a, b) in sorted(routine_spans.items(),
                               key=lambda kv: kv[1][0] - kv[1][1]):
        for n in range(a, min(b, nlines) + 1):
            owner[n] = name
    return owner


def tally(markers, lines):
    """covered / uncovered / notbuilt over a set of line numbers."""
    covered = uncovered = notbuilt = 0
    for n in lines:
        m = markers.get(n)
        if m is None or m == '-':
            continue
        if m == '-----':
            notbuilt += 1
        elif m == '#####':
            uncovered += 1
        else:
            try:
                if int(m.rstrip('*')) > 0:
                    covered += 1
                else:
                    uncovered += 1
            except ValueError:
                pass
    return covered, uncovered, notbuilt


def derive(run):
    markers = load_markers(run)
    inv = yaml.safe_load(open(INV))
    routines = [r for f in inv["features"] for a in f["areas"] for r in a["routines"]]

    by_file = collections.defaultdict(list)
    for r in routines:
        by_file[r["file"]].append(r)

    result, missing_file, missing_routine = {}, [], []
    for path, rs in sorted(by_file.items()):
        full = os.path.join(ROOT, path)
        if not os.path.exists(full):
            missing_file.append(path)
            continue
        src = open(full, errors="replace").read().split("\n")
        sp = spans(src)
        owner = owners(sp, len(src))
        own = collections.defaultdict(list)
        for n in range(1, len(src) + 1):
            if owner[n]:
                own[owner[n]].append(n)
        marks = markers.get(path)
        for r in rs:
            key = f"{path}::{r['name'].lower()}"
            name = r["name"].lower()
            if name not in sp:
                missing_routine.append(key)
                continue
            if marks is None:            # file absent from this run entirely
                result[key] = {"status": "not_measured"}
                continue
            cov, unc, nb = tally(marks, own[name])
            total = cov + unc + nb
            result[key] = {"covered": cov, "total": total, "notbuilt": nb,
                           "pct": round(100.0 * cov / total, 1) if total else None}
    return result, missing_file, missing_routine


# ------------------------------------------------------------- write-back ---
HUMAN = {"note", "na"}          # keys under `coverage:` a human owns
KEEP = {}


def write_back(result, run):
    src = open(INV).read().split("\n")
    # first pass: drop the derived block, remembering the human-owned keys
    out, i, n, cur = [], 0, len(src), None
    while i < n:
        line = src[i]
        m = re.match(r'^(\s+)- file: (\S+)\s*$', line)
        if m:
            cur = m.group(2)
        m2 = re.match(r'^\s+name: (\S+)\s*$', line)
        if m2 and cur and "::" not in cur:
            cur = f"{cur}::{m2.group(1).lower()}"
        if re.match(r'^\s+coverage:\s*$', line):
            ind = len(line) - len(line.lstrip())
            j = i + 1
            while j < n and (not src[j].strip() or
                             len(src[j]) - len(src[j].lstrip()) > ind):
                k, _, v = src[j].strip().partition(":")
                if k in HUMAN and v.strip():
                    KEEP.setdefault(cur, {})[k] = v.strip().strip('"')
                j += 1
            i = j
            continue
        out.append(line); i += 1

    # second pass: insert the derived block at the end of each routine entry
    final, i, n, cur = [], 0, len(out), None
    while i < n:
        line = out[i]
        m = re.match(r'^(\s+)- file: (\S+)\s*$', line)
        if m:
            cur, ind = m.group(2), len(m.group(1)) + 2
        m2 = re.match(r'^\s+name: (\S+)\s*$', line)
        if m2 and cur and "::" not in cur:
            cur = f"{cur}::{m2.group(1).lower()}"
        final.append(line)
        nxt = out[i+1] if i + 1 < n else ""
        ends = cur and (re.match(r'^\s+- file: ', nxt) or
                        not nxt.startswith(" " * ind) or not nxt.strip())
        if ends:
            d = result.get(cur)
            if d:
                p = " " * ind
                final.append(f"{p}coverage:")
                if d.get("status"):
                    final.append(f"{p}  status: {d['status']}")
                else:
                    final.append(f"{p}  pct: {d['pct']}")
                    final.append(f"{p}  covered: {d['covered']}")
                    final.append(f"{p}  total: {d['total']}")
                    if d["notbuilt"]:
                        final.append(f"{p}  notbuilt: {d['notbuilt']}")
                keep = KEEP.get(cur, {})
                for k in ("na", "note"):
                    if keep.get(k):
                        final.append(f"{p}  {k}: {keep[k]}")
            cur = None
        i += 1

    text = "\n".join(final)
    # provenance, as a top-level key
    stamp = f"coverage_from: {os.path.basename(run)}"
    if re.search(r'^coverage_from:.*$', text, re.M):
        text = re.sub(r'^coverage_from:.*$', stamp, text, count=1, flags=re.M)
    else:
        text = stamp + "\n" + text
    open(INV, "w").write(text)
    print(f"inventory.yaml rewritten: {len(result)} coverage blocks")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--run", default=None, help="coverage directory (default: newest)")
    ap.add_argument("--report", action="store_true", help="show, change nothing")
    ap.add_argument("--write", action="store_true", help="update inventory.yaml")
    ap.add_argument("--json", default=None, help="machine-readable dump")
    args = ap.parse_args()

    run = args.run or newest_run()
    if not run:
        sys.exit("no coverage run found: expected tests/coverage_*/gcov_files/")
    print(f"coverage run: {os.path.relpath(run, ROOT)}")

    result, missing_file, missing_routine = derive(run)
    measured = {k: v for k, v in result.items() if "pct" in v and v["pct"] is not None}
    print(f"routines with coverage : {len(measured)}")
    print(f"routines not measured  : {len(result) - len(measured)}")
    if missing_routine:
        print(f"routines not found in source: {len(missing_routine)}")
        for k in missing_routine[:10]:
            print(f"    {k}")
    if missing_file:
        print(f"files missing from the tree : {len(missing_file)}")

    if args.report and measured:
        cov = sum(v["covered"] for v in measured.values())
        tot = sum(v["total"] for v in measured.values())
        print(f"\nsummed over routines: {100*cov/tot:.2f}% ({cov}/{tot})")
        worst = sorted(measured.items(), key=lambda kv: (kv[1]["pct"], -kv[1]["total"]))
        print("\nlowest coverage, largest first:")
        for k, v in worst[:15]:
            print(f"  {v['pct']:6.1f}%  {v['covered']:5d}/{v['total']:<5d}  {k}")
    if args.json:
        json.dump(result, open(args.json, "w"), indent=1, sort_keys=True)
        print(f"wrote {args.json}")
    if args.write:
        write_back(result, run)


if __name__ == "__main__":
    main()
