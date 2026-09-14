#!/usr/bin/env python3
"""Recompute each routine's `scope` from its `callers`.

Moving a routine between areas invalidates its own scope, and invalidates it
for anything whose callers moved -- those cascades are easy to miss by hand.
This applies the same rule validate_inventory.py checks:

    area     every caller resolves to this routine's own (feature, area)
    feature  callers span areas but stay inside this routine's feature
    global   callers span more than one feature
    (absent) no caller resolves anywhere

Caller names resolve as they do in the validator: to a definition in the same
file when there is one (Fortran contained/module scoping), else to every
definition of that name.

Usage:
    python3 doc/features_overview/derive_scope.py --report
    python3 doc/features_overview/derive_scope.py --write
"""
import os, re, sys, argparse

HERE = os.path.dirname(os.path.abspath(__file__))
INV = os.path.join(HERE, "inventory.yaml")

try:
    import yaml
except ImportError:
    sys.exit("needs PyYAML:  pip install pyyaml")


def expected(inv):
    """(file, name) -> the scope its callers imply, or None for no callers"""
    by_name, by_file_name = {}, {}
    for feat in inv["features"]:
        for area in feat.get("areas") or []:
            for r in area.get("routines") or []:
                nm = str(r["name"]).lower()
                by_name.setdefault(nm, set()).add((feat["id"], area["id"]))
                by_file_name[(r["file"], nm)] = (feat["id"], area["id"])
    by_name.setdefault("program", {("amr_core", "main_loop")})

    def resolve(caller, same_file):
        if "::" in caller:
            cf, cn = caller.rsplit("::", 1)
            hit = by_file_name.get((cf, cn.lower()))
            return {hit} if hit else set()
        c = caller.lower()
        if (same_file, c) in by_file_name:
            return {by_file_name[(same_file, c)]}
        return by_name.get(c, set())

    out = {}
    for feat in inv["features"]:
        for area in feat.get("areas") or []:
            here = (feat["id"], area["id"])
            for r in area.get("routines") or []:
                locs = set()
                for c in (r.get("callers") or []):
                    locs |= resolve(c, r["file"])
                if not locs:
                    out[(r["file"], r["name"])] = None
                else:
                    out[(r["file"], r["name"])] = (
                        "area" if locs == {here}
                        else "feature" if {x for x, _ in locs} == {here[0]}
                        else "global")
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true", help="apply the changes")
    ap.add_argument("--report", action="store_true")
    args = ap.parse_args()

    inv = yaml.safe_load(open(INV))
    want = expected(inv)
    have = {(r["file"], r["name"]): r.get("scope")
            for f in inv["features"] for a in f["areas"] for r in a["routines"]}
    wrong = {k: (have[k], want[k]) for k in have if have[k] != want[k]}

    if not wrong:
        print("every scope already agrees with its callers")
        return 0
    print(f"{len(wrong)} scope value(s) disagree with their callers:")
    for (path, name), (was, exp) in sorted(wrong.items()):
        print(f"  {path}::{name}: {was!r} -> {exp!r}")
    if not args.write:
        print("\n(--write to apply)")
        return 0

    # rewrite in place: find each routine block and set/remove its scope line
    L = open(INV).read().split("\n")
    fid = aid = None
    blocks = []          # (start, end, file, name)
    start = None
    for i, l in enumerate(L):
        if l.startswith("          - file: "):
            if start is not None:
                blocks.append((start, i))
            start = i
        elif re.match(r"^      - id: |^  - id: |^[a-z_]+:", l) and start is not None:
            blocks.append((start, i)); start = None
    if start is not None:
        blocks.append((start, len(L)))

    n = 0
    for a, b in reversed(blocks):
        path = L[a].split("file:", 1)[1].strip()
        name = next(x.split("name:", 1)[1].strip()
                    for x in L[a:b] if x.strip().startswith("name:"))
        if (path, name) not in wrong:
            continue
        exp = wrong[(path, name)][1]
        si = [k for k in range(a, b) if L[k].strip().startswith("scope:")]
        if exp is None:
            for k in reversed(si):
                del L[k]
        elif si:
            L[si[0]] = f"            scope: {exp}"
        else:                       # insert after role, else after name
            anchor = [k for k in range(a, b) if L[k].strip().startswith("role:")] \
                  or [k for k in range(a, b) if L[k].strip().startswith("name:")]
            L.insert(anchor[-1] + 1, f"            scope: {exp}")
        n += 1
    open(INV, "w").write("\n".join(L))
    print(f"\nrewrote {n} scope value(s) in {INV}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
