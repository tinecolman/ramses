#!/usr/bin/env python3
"""Which tests execute which routines.

Joins the per-test line attribution of a coverage run (coverage_tests.json) to
the routine spans of every file in inventory.yaml, and writes
tests_by_routine.json for page/build.py to embed.

A routine counts as reached by a test when that test executes at least one of
the routine's *own* lines -- lines of a contained routine belong to that
routine, exactly as in derive_coverage.py.

Usage:
    python3 doc/features_overview/derive_test_map.py --report
    python3 doc/features_overview/derive_test_map.py --report --test implosion
    python3 doc/features_overview/derive_test_map.py --write
"""
import os, sys, json, glob, argparse, collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
INV  = os.path.join(HERE, "inventory.yaml")
OUT  = os.path.join(HERE, "tests_by_routine.json")

try:
    import yaml
except ImportError:
    sys.exit("needs PyYAML:  pip install pyyaml")

sys.path.insert(0, HERE)
from derive_omp import spans
from derive_coverage import newest_run, owners


def test_paths():
    """leaf test name -> path relative to tests/, e.g. implosion -> hydro/implosion"""
    out = {}
    for cfg in glob.glob(os.path.join(ROOT, "tests", "**", "config.txt"),
                         recursive=True):
        d = os.path.dirname(cfg)
        out[os.path.basename(d)] = os.path.relpath(d, os.path.join(ROOT, "tests"))
    return out


def build(run, inv):
    """(file, lowercased routine name) -> set of test names"""
    per = {k.replace("../", ""): v for k, v in
           json.load(open(os.path.join(run, "coverage_tests.json"))).items()}
    paths = {r["file"] for f in inv["features"] for a in f["areas"]
             for r in a["routines"]}
    hits = collections.defaultdict(set)
    for path in sorted(paths):
        full = os.path.join(ROOT, path)
        if not os.path.exists(full):
            continue
        src = open(full, errors="replace").read().split("\n")
        owner = owners(spans(src), len(src))
        for ln, tests in per.get(path, {}).items():
            n = int(ln)
            if n < len(owner) and owner[n]:
                hits[(path, owner[n])] |= set(tests)
    return hits


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true",
                    help=f"write {os.path.basename(OUT)}")
    ap.add_argument("--report", action="store_true")
    ap.add_argument("--test", help="report one test's reach, feature by feature")
    args = ap.parse_args()

    run = newest_run()
    if not run:
        sys.exit("no coverage run found under tests/")
    inv = yaml.safe_load(open(INV))
    hits = build(run, inv)
    paths = test_paths()

    names = sorted({t for s in hits.values() for t in s})
    idx = {t: i for i, t in enumerate(names)}
    routines = {}
    for f in inv["features"]:
        for a in f["areas"]:
            for r in a["routines"]:
                s = hits.get((r["file"], str(r["name"]).lower()))
                if s:
                    routines[r["file"] + "::" + r["name"]] = sorted(idx[t] for t in s)

    blob = {"run": os.path.basename(run),
            "names": names,
            "paths": [paths.get(t, t) for t in names],
            "routines": routines}

    if args.test:
        t = args.test
        if t not in idx:
            sys.exit(f"no such test in this run: {t}\n  have: {', '.join(names)}")
        print(f"{paths.get(t, t)} reaches:")
        total = reached = 0
        for f in inv["features"]:
            n = d = 0
            for a in f["areas"]:
                for r in a["routines"]:
                    d += 1
                    if t in hits.get((r["file"], str(r["name"]).lower()), ()):
                        n += 1
            total += d
            reached += n
            if n:
                print(f"  {f['id']:18s} {n:3d}/{d:3d}  {100*n/d:5.1f}%  "
                      + "#" * round(20 * n / d))
        print(f"\n  {reached} of {total} routines")
    elif args.report:
        print(f"run {os.path.basename(run)}: {len(names)} tests, "
              f"{len(routines)} of "
              f"{sum(len(a['routines']) for f in inv['features'] for a in f['areas'])}"
              f" routines reached by at least one test")
        per_test = collections.Counter()
        for s in hits.values():
            for t in s:
                per_test[t] += 1
        for t, n in per_test.most_common():
            print(f"  {paths.get(t, t):42s} {n:4d} routines")

    if args.write:
        json.dump(blob, open(OUT, "w"), separators=(",", ":"))
        print(f"wrote {OUT} "
              f"({os.path.getsize(OUT)/1024:.0f} KB, {len(names)} tests, "
              f"{len(routines)} routines)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
