#!/usr/bin/env python3
"""
Validate doc/modules_overview/inventory.yaml against the RAMSES source tree.

Hard errors (exit 1):
  * an inventory entry points at a file that does not exist
  * an inventory entry names a routine that is not defined in that file
  * the same file::routine is claimed by two different features

Coverage report (informational):
  * routines that exist in in-scope source files but appear in no entry
  * in-scope source files that are never mentioned

Usage:  python3 doc/modules_overview/validate_inventory.py [-v] [--all-dirs]
"""
import os, re, sys, glob, argparse, collections
try:
    import yaml
except ImportError:
    sys.exit("needs PyYAML:  pip install pyyaml")

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

# Directories the inventory is expected to cover ("core + tested features").
IN_SCOPE  = ["amr", "hydro", "mhd", "poisson", "pm", "rt", "turb", "io"]
# Present in the tree but deliberately outside the inventory's scope.
OUT_SCOPE = ["aton", "pario", "rhd"]

DEF_RE = re.compile(r"""^\s*
    (?:(?:recursive|pure|elemental|impure|module)\s+)*
    (?:(?:logical|integer|real|complex|character|doubleprecision|double\s+precision
        |type|class)\s*(?:\([^)]*\))?(?:\s*\*\s*\d+)?\s+)?
    (?:(?:recursive|pure|elemental|impure|module)\s+)*
    (?:subroutine|function)\s+([a-zA-Z_]\w*)""", re.I | re.X)


def index_tree(dirs):
    """path -> set of routine names DEFINED in it.

    Names declared inside an `interface` block are not definitions (they are
    external or dummy procedures), so those blocks are skipped.
    """
    code = {}
    for d in dirs:
        pats = (f"{ROOT}/{d}/*.f90", f"{ROOT}/{d}/*.F90", f"{ROOT}/{d}/*.f")
        for p in sorted(sum((glob.glob(x) for x in pats), [])):
            names = set()
            iface = 0
            for line in open(p, errors="replace"):
                line = line.split('!')[0]          # strip trailing comment
                if re.match(r'^\s*interface\b', line, re.I):
                    iface += 1
                    continue
                if re.match(r'^\s*end\s*interface\b', line, re.I):
                    iface = max(0, iface - 1)
                    continue
                if re.match(r'^\s*end\b', line, re.I) or '::' in line:
                    continue
                m = DEF_RE.match(line)
                if m and not iface:
                    names.add(m.group(1).lower())
            code[f"{d}/{os.path.basename(p)}"] = names
    return code


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-v", "--verbose", action="store_true",
                    help="list every uncovered routine, not just per-file counts")
    ap.add_argument("--all-dirs", action="store_true",
                    help="also report coverage for aton/, pario/, rhd/")
    args = ap.parse_args()

    dirs = IN_SCOPE + (OUT_SCOPE if args.all_dirs else [])
    code = index_tree(dirs)
    inv = yaml.safe_load(open(os.path.join(HERE, "inventory.yaml")))

    # files deliberately left out (obsolete, dead, vendored, ...)
    excluded = {e["path"]: e.get("reason", "") for e in inv.get("excluded_files") or []}
    for path in excluded:
        if path not in code:
            print(f"note: excluded_files lists {path}, which is not in the tree")
        code.pop(path, None)

    errors = []
    claimed = collections.defaultdict(list)   # (file, routine) -> [feature/area]
    files_seen = set()

    # declaration-only modules claimed via the feature-level `modules:` list
    mod_owner = {}
    for feat in inv["features"]:
        for m in feat.get("modules") or []:
            files_seen.add(m)
            if m not in code:
                if m.split("/")[0] in OUT_SCOPE and not args.all_dirs:
                    continue
                errors.append(f"{feat['id']}: modules: no such file: {m}")
            elif code[m]:
                errors.append(f"{feat['id']}: modules: {m} defines "
                              f"{len(code[m])} routine(s); list them under areas instead")
            elif m in mod_owner:
                errors.append(f"{m} claimed by two features: {mod_owner[m]}, {feat['id']}")
            else:
                mod_owner[m] = feat['id']

    for feat in inv["features"]:
        for area in feat.get("areas") or []:
            where = f"{feat['id']}/{area['id']}"
            for r in area.get("routines") or []:
                path, name = r["file"], str(r["name"])
                files_seen.add(path)
                if path not in code:
                    if path.split("/")[0] in OUT_SCOPE and not args.all_dirs:
                        continue
                    errors.append(f"{where}: no such file: {path}")
                    continue
                if name != "*":
                    if name.lower() not in code[path]:
                        errors.append(
                            f"{where}: {path} has no routine '{name}'")
                    else:
                        claimed[(path, name.lower())].append(where)

    # ---- derived-field consistency (phase / role / scope / driver) ----
    PHASES = {"params", "init", "step", "output", "finalise", "any"}
    ROLES = {"driver", "recursive", "shared", "private", "unused"}
    SCOPES = {"area", "feature", "global"}
    # a caller name resolves to a definition in the same file when there is one
    # (Fortran contained/module scoping), else to every definition of that name
    by_name = {}
    by_file_name = {}
    for feat in inv["features"]:
        for area in feat.get("areas") or []:
            for r in (area.get("routines") or []):
                nm = str(r["name"]).lower()
                by_name.setdefault(nm, set()).add((feat["id"], area["id"]))
                by_file_name[(r["file"], nm)] = (feat["id"], area["id"])
    by_name.setdefault("program", {("amr_core", "main_loop")})

    def resolve(caller, same_file):
        if "::" in caller:                      # file-qualified caller
            cf, cn = caller.rsplit("::", 1)
            hit = by_file_name.get((cf, cn.lower()))
            return {hit} if hit else set()
        c = caller.lower()
        if (same_file, c) in by_file_name:
            return {by_file_name[(same_file, c)]}
        return by_name.get(c, set())

    for feat in inv["features"]:
        for area in feat.get("areas") or []:
            here = (feat["id"], area["id"])
            tag = f"{feat['id']}/{area['id']}"
            for r in (area.get("routines") or []):
                n = r["name"]
                cs = r.get("callers") or []
                if r.get("phase") not in PHASES:
                    errors.append(f"{tag}: {n} has phase {r.get('phase')!r}")
                if r.get("role") not in ROLES:
                    errors.append(f"{tag}: {n} has role {r.get('role')!r}")
                if r.get("scope") and r["scope"] not in SCOPES:
                    errors.append(f"{tag}: {n} has scope {r['scope']!r}")
                if r.get("omp_from") and not r.get("omp"):
                    errors.append(f"{tag}: {n} has omp_from but no omp")
                role = r.get("role")
                if role == "unused" and cs:
                    errors.append(f"{tag}: {n} is role unused but has callers")
                if role == "private" and len(cs) != 1:
                    errors.append(f"{tag}: {n} is role private but has {len(cs)} callers")
                if role == "shared" and len(cs) < 2:
                    errors.append(f"{tag}: {n} is role shared but has {len(cs)} callers")
                if role == "recursive" and str(n).lower() not in [c.lower() for c in cs]:
                    errors.append(f"{tag}: {n} is role recursive but does not "
                                  f"call itself (callers: {cs})")
                if (role == "driver") != bool(r.get("driver")):
                    errors.append(f"{tag}: {n} role/driver disagree "
                                  f"(role={role}, driver={r.get('driver')})")
                locs = set()
                for c in cs:
                    locs |= resolve(c, r["file"])
                if locs:
                    exp = ("area" if locs == {here}
                           else "feature" if {x for x, _ in locs} == {here[0]}
                           else "global")
                    if r.get("scope") != exp:
                        errors.append(f"{tag}: {n} scope is {r.get('scope')!r}, "
                                      f"callers say {exp!r}")
                elif r.get("scope"):
                    errors.append(f"{tag}: {n} has scope but no locatable callers")

    for (path, name), wheres in sorted(claimed.items()):
        if len(wheres) > 1:
            errors.append(f"{path}::{name} listed {len(wheres)} times: "
                          + ", ".join(sorted(wheres)))

    # ---- coverage ----
    covered = {(p, n) for (p, n) in claimed}
    whole = {r["file"] for f in inv["features"] for a in (f.get("areas") or [])
             for r in (a.get("routines") or []) if str(r["name"]) == "*"}

    uncovered = collections.defaultdict(list)
    for path, names in code.items():
        if path in whole:
            continue
        for n in sorted(names):
            if (path, n) not in covered:
                uncovered[path].append(n)

    decl_only = [p for p, n in code.items() if not n]
    orphan_mods = [p for p in sorted(decl_only) if p not in mod_owner]
    unmentioned = [p for p in sorted(code)
                   if p not in files_seen and p not in decl_only]

    n_tot = sum(len(v) for v in code.values())
    # a routine counts once, whether claimed by name or by a whole-file '*' entry
    all_cov = set(covered)
    for p in whole:
        all_cov |= {(p, n) for n in code.get(p, ())}
    n_cov = len(all_cov)

    print(f"inventory: {sum(len(a.get('routines') or []) for f in inv['features'] for a in (f.get('areas') or []))} entries, "
          f"{len(inv['features'])} features")
    print(f"source:    {len(code)} files, {n_tot} routines "
          f"({len(decl_only)} declaration-only files"
          + (f", {len(excluded)} excluded" if excluded else "") + ")")
    n_src = len(code) - len(decl_only)
    n_src_cov = len((files_seen & set(code)) - set(decl_only))
    print(f"coverage:  {n_cov}/{n_tot} routines ({100*n_cov/max(n_tot,1):.0f}%), "
          f"{n_src_cov}/{n_src} source files, "
          f"{len(mod_owner)}/{len(decl_only)} declaration-only modules")
    if orphan_mods:
        print(f"\ndeclaration-only modules not assigned to a feature ({len(orphan_mods)}):")
        print("  " + ", ".join(orphan_mods))

    if unmentioned:
        print(f"\nfiles never mentioned ({len(unmentioned)}):")
        by_dir = collections.defaultdict(list)
        for p in unmentioned:
            by_dir[p.split("/")[0]].append(p.split("/")[1])
        for d in sorted(by_dir):
            n = sum(len(code[f"{d}/{f}"]) for f in by_dir[d])
            print(f"  {d}/  ({len(by_dir[d])} files, {n} routines)")
            print("      " + ", ".join(sorted(by_dir[d])))

    partial = {p: v for p, v in uncovered.items() if p in files_seen}
    if partial:
        tot = sum(len(v) for v in partial.values())
        print(f"\npartially covered files ({len(partial)} files, {tot} routines missing):")
        for p in sorted(partial):
            if args.verbose:
                print(f"  {p}: {', '.join(partial[p])}")
            else:
                print(f"  {p}: {len(partial[p])} missing "
                      f"({', '.join(partial[p][:4])}{', ...' if len(partial[p]) > 4 else ''})")

    if errors:
        print(f"\nERRORS ({len(errors)}):")
        for e in errors:
            print(f"  {e}")
        return 1
    print("\nno errors: every entry resolves to a real routine.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
