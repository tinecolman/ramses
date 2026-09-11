#!/usr/bin/env python3
"""Record in each test's README.md which feature areas that test exercises.

Joins the per-test attribution of a coverage run (coverage_tests.json) to the
feature/area structure in inventory.yaml, and writes a generated block into
tests/<...>/README.md.  Everything outside the markers is left alone, so the
block can be regenerated after every coverage run.

For each area a test reaches it reports:
  lines   the area's lines this test executes
  share   those lines as a fraction of the area's executable lines
  only    lines this test is the only one to execute -- what would stop being
          tested if this test were removed

Usage:
    python3 doc/features_overview/annotate_test_readmes.py --report
    python3 doc/features_overview/annotate_test_readmes.py --write
"""
import os, re, sys, json, glob, argparse, collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
INV  = os.path.join(HERE, "inventory.yaml")
TESTS = os.path.join(ROOT, "tests")

BEGIN = "<!-- BEGIN feature-coverage -->"
END   = "<!-- END feature-coverage -->"

try:
    import yaml
except ImportError:
    sys.exit("needs PyYAML:  pip install pyyaml")

sys.path.insert(0, HERE)
from derive_omp import spans
from derive_coverage import newest_run, owners

# Every test drives the AMR core, so listing everything it touches says
# nothing. An area is listed when the test exercises a real part of it, or
# when the test is the only one in the suite reaching some of its lines.
MIN_LINES = 10
MIN_SHARE = 25.0         # percent of the area's executable lines
MAX_ROWS  = 20


def test_dirs():
    """leaf test name -> path relative to tests/"""
    out = {}
    for cfg in glob.glob(os.path.join(TESTS, "**", "config.txt"), recursive=True):
        d = os.path.dirname(cfg)
        out[os.path.basename(d)] = os.path.relpath(d, TESTS)
    return out


def area_of_routine(inv):
    """(file, routine name) -> (feature id, feature title, area id, area title)"""
    out = {}
    for f in inv["features"]:
        for a in f["areas"]:
            for r in a["routines"]:
                out[(r["file"], r["name"].lower())] = (f["id"], f["title"],
                                                       a["id"], a["title"])
    return out


def area_totals(inv):
    """area key -> executable lines in it, from the derived coverage blocks"""
    out = collections.Counter()
    for f in inv["features"]:
        for a in f["areas"]:
            for r in a["routines"]:
                c = r.get("coverage") or {}
                out[(f["id"], a["id"])] += c.get("total", 0)
    return out


def collect(run, inv):
    """test -> {area key: [lines touched, lines only this test touches]}"""
    hits = json.load(open(os.path.join(run, "coverage_tests.json")))
    amap, per_test = area_of_routine(inv), collections.defaultdict(
        lambda: collections.defaultdict(lambda: [0, 0]))
    titles = {}
    for src, lines in hits.items():
        path = re.sub(r'^(\.\./)+', '', src)
        full = os.path.join(ROOT, path)
        if not os.path.exists(full):
            continue
        text = open(full, errors="replace").read().split("\n")
        owner = owners(spans(text), len(text))
        for lineno, tests in lines.items():
            n = int(lineno)
            if n >= len(owner) or not owner[n]:
                continue
            key = amap.get((path, owner[n]))
            if not key:
                continue
            fid, ftitle, aid, atitle = key
            titles[(fid, aid)] = (ftitle, atitle)
            for t in tests:
                cell = per_test[t][(fid, aid)]
                cell[0] += 1
                if len(tests) == 1:
                    cell[1] += 1
    return per_test, titles


def block_for(test, areas, totals, titles, run):
    rows = []
    for key, (n, only) in areas.items():
        tot = totals.get(key, 0)
        rows.append((100.0 * n / tot if tot else 0.0, n, only, key))
    rows.sort(key=lambda r: (-r[0], -r[1]))
    listed = [r for r in rows
              if (r[1] >= MIN_LINES and r[0] >= MIN_SHARE) or r[2]][:MAX_ROWS]
    rest = len(rows) - len(listed)

    by_feature = collections.Counter()
    for _share, n, _only, key in rows:
        by_feature[key[0]] += n
    chief = [f for f, _ in by_feature.most_common(3)]
    unique = sum(o for _s, _n, o, _k in rows)

    out = [BEGIN, "## Feature areas covered by this test", ""]
    # every test drives the AMR core, so say where the lines fall rather
    # than implying what the test is about
    out.append(f"Reaches {len(rows)} areas; most of its lines fall in "
               f"**{'**, **'.join(chief)}**"
               + (f". {unique} lines are reached by no other test in the suite."
                  if unique else ", and no line is reached by this test alone."))
    out.append("")
    out.append(f"| feature | area | lines | share of area | only this test |")
    out.append("|---|---|---:|---:|---:|")
    if not listed:
        out.append("| | *nothing above the reporting threshold* | | | |")
    for share, n, only, key in listed:
        out.append(f"| {key[0]} | {key[1]} | {n} | {share:.0f}% | "
                   f"{only if only else ''} |")
    if rest > 0:
        out.append("")
        out.append(f"{rest} further area{'s' if rest != 1 else ''} "
                   f"exercised more lightly (under {MIN_LINES} lines or "
                   f"{MIN_SHARE:.0f}% of the area, and shared with other tests).")
    out.append("")
    out.append(f"<sub>Generated from `{os.path.basename(run)}` by "
               f"`doc/features_overview/annotate_test_readmes.py`. "
               f"*share* is of the area's executable lines; *only* counts lines "
               f"no other test reaches.</sub>")
    out += ["", END]
    return "\n".join(out)


def write_readme(path, block, test):
    if os.path.exists(path):
        text = open(path, errors="replace").read()
    else:
        text = f"# {test}\n"
    if BEGIN in text and END in text:
        text = re.sub(re.escape(BEGIN) + r".*?" + re.escape(END), block,
                      text, flags=re.S)
    else:
        text = text.rstrip("\n") + "\n\n" + block + "\n"
    open(path, "w").write(text)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--run", default=None, help="coverage directory (default: newest)")
    ap.add_argument("--report", action="store_true", help="show, change nothing")
    ap.add_argument("--write", action="store_true", help="update the READMEs")
    args = ap.parse_args()

    run = args.run or newest_run()
    if not run:
        sys.exit("no coverage run found")
    if not os.path.exists(os.path.join(run, "coverage_tests.json")):
        sys.exit(f"{run} has no coverage_tests.json")
    print(f"coverage run: {os.path.relpath(run, ROOT)}")

    inv = yaml.safe_load(open(INV))
    totals = area_totals(inv)
    per_test, titles = collect(run, inv)
    dirs = test_dirs()

    written, missing = 0, []
    for test in sorted(per_test):
        if test not in dirs:
            missing.append(test)
            continue
        areas = per_test[test]
        block = block_for(test, areas, totals, titles, run)
        listed = sum(1 for k, (n, o) in areas.items()
                     if n >= MIN_LINES and 100.0*n/max(totals.get(k, 1), 1) >= MIN_SHARE)
        if args.report:
            uniq = sum(o for _n, o in areas.values())
            print(f"  {dirs[test]:34s} {len(areas):3d} areas "
                  f"({listed} listed), {uniq} lines only this test")
        if args.write:
            write_readme(os.path.join(TESTS, dirs[test], "README.md"), block, test)
            written += 1
    if missing:
        print(f"no test directory for: {', '.join(missing)}")
    if args.write:
        print(f"{written} README.md files updated")


if __name__ == "__main__":
    main()
