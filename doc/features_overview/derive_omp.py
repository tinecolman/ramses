#!/usr/bin/env python3
"""Derive the OpenMP status of every inventory routine from the `openmp` branch.

The public RAMSES trunk carries no OpenMP directives at all; the work lives on
the `openmp` branch.  This script reads that branch straight out of git (no
checkout needed), attributes every directive to the routine that contains it,
and writes the result back into inventory.yaml.

Per routine it records one derived `state`. The vocabulary is deliberately
about OpenMP threading only -- RAMSES is MPI-parallel everywhere, so "parallel"
and "serial" would say nothing:

  opens_region  the routine opens an OpenMP parallel region -- it is where the
                threading starts
  adapted       no region of its own, but it has been adapted to run inside one
                (threadprivate declarations, critical/atomic sections)
  stateless     runs inside a parallel region and needs no adaptation: it keeps
                nothing between calls -- no `save` variables, no
                data-initialised locals, no DATA statements
  race          runs inside a parallel region but keeps state across calls that
                is not threadprivate
  unthreaded    never runs inside a parallel region

`stateless` names exactly what was checked and nothing more. It is inferred
from the declarations in the routine, so it does not cover writes to module
variables through `use` association; it is the necessary condition, not a
proof.

Usage:
    python3 doc/features_overview/derive_omp.py --report        # show, change nothing
    python3 doc/features_overview/derive_omp.py --write         # update inventory.yaml
    python3 doc/features_overview/derive_omp.py --json out.json # machine-readable dump
"""
import os, re, sys, json, argparse, subprocess, collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
INV  = os.path.join(HERE, "inventory.yaml")
REF  = "openmp"          # branch carrying the OpenMP work
TRUNK = "dev"            # branch the inventory describes

try:
    import yaml
except ImportError:
    sys.exit("needs PyYAML:  pip install pyyaml")

# ---------------------------------------------------------------- parsing ---
DEF_RE = re.compile(r"""^\s*
    (?:(?:recursive|pure|elemental|impure|module)\s+)*
    (?:(?:logical|integer|real|complex|character|doubleprecision|double\s+precision
        |type|class)\s*(?:\([^)]*\))?(?:\s*\*\s*\d+)?\s+)?
    (?:(?:recursive|pure|elemental|impure|module)\s+)*
    (?:subroutine|function)\s+([a-zA-Z_]\w*)""", re.I | re.X)
END_RE  = re.compile(r'^\s*end\s*(subroutine|function)?\s*([a-zA-Z_]\w*)?\s*$', re.I)
# `end if`, `enddo`, `end select`, ... also match the pattern above: they close a
# block, not a program unit. A bare `end`, `end subroutine`/`end function`, or
# `end <name of the routine we are inside>` is the real thing.
BLOCKS  = {"if", "do", "select", "where", "type", "forall", "associate",
           "block", "critical", "enum", "file", "team", "interface"}


def closes(m, current):
    kw, nm = m.group(1), m.group(2)
    if kw:
        return True                       # end subroutine / end function
    if nm is None:
        return True                       # bare `end`
    n = nm.lower()
    if n in BLOCKS:
        return False
    return n == current                   # `end <routine name>`
IFACE   = re.compile(r'^\s*interface\b', re.I)
ENDIF   = re.compile(r'^\s*end\s*interface\b', re.I)
OMP     = re.compile(r'^\s*!\$\s*omp\s+(.*)$', re.I)
OMPCONT = re.compile(r'^\s*!\$\s*omp\s*&', re.I)
PARDIR  = re.compile(r'^\s*!\$\s*omp\s+parallel\b(.*)$', re.I)
ENDPAR  = re.compile(r'^\s*!\$\s*omp\s+end\s+parallel\b', re.I)
DOSTMT  = re.compile(r'^\s*(?:\w+\s*:\s*)?do\b', re.I)
ENDDO   = re.compile(r'^\s*end\s*do\b', re.I)
CALL    = re.compile(r'\bcall\s+([a-zA-Z_]\w*)', re.I)
TPDECL  = re.compile(r'^\s*!\$\s*omp\s+threadprivate\s*\(([^)]*)', re.I)
SAVE    = re.compile(r'(^|[,;])\s*save\b', re.I)
DATA    = re.compile(r'^\s*data\s+\w', re.I)
NAME    = re.compile(r'^[a-zA-Z_]\w*$')
# `x = ...` or `x(i) = ...` at the start of a statement, but not `==`, `>=`, ...
ASSIGN  = re.compile(r'^\s*([a-zA-Z_]\w*)\s*(?:\([^=]*\))?\s*=(?![=>])')

REGION_KINDS = ("do", "sections", "workshare")
SYNC_KINDS   = {"critical", "atomic", "barrier", "single", "master",
                "flush", "ordered", "taskwait"}


def show(ref, path):
    p = subprocess.run(["git", "-C", ROOT, "show", f"{ref}:{path}"],
                       capture_output=True, text=True)
    return None if p.returncode else p.stdout


def spans(lines):
    """routine name -> (start, end) 1-based line numbers, innermost wins."""
    out, stack, iface = {}, [], 0
    for i, raw in enumerate(lines, 1):
        if OMP.match(raw):
            continue
        line = raw.split('!')[0]
        if IFACE.match(line):
            iface += 1; continue
        if ENDIF.match(line):
            iface = max(0, iface - 1); continue
        if iface:
            continue
        if stack:
            m = END_RE.match(line)
            if m and closes(m, stack[-1]):
                name = stack.pop()
                out[name] = (out[name][0], i)
                continue
        if '::' in line:
            continue
        m = DEF_RE.match(line)
        if m:
            name = m.group(1).lower()
            if name not in out:            # first definition wins
                out[name] = (i, len(lines))
                stack.append(name)
    return out


def directives(lines, span):
    """counts of the directives inside a routine's span."""
    reg = tp = sync = loops = 0
    tpnames = set()
    a, b = span
    for raw in lines[a-1:b]:
        m = OMP.match(raw)
        if not m or OMPCONT.match(raw):
            continue
        rest = m.group(1).strip().lower()
        head = rest.split('(')[0].split()[0] if rest else ""
        if head == "parallel":          # the OpenMP directive keyword
            reg += 1
            if rest.split()[1:2] and rest.split()[1] in REGION_KINDS:
                loops += 1
        elif head == "do":
            loops += 1
        elif head == "threadprivate":
            tp += 1
            t = TPDECL.match(raw)
            if t:
                tpnames |= {x.strip().lower() for x in t.group(1).split(',') if x.strip()}
        elif head in SYNC_KINDS:
            sync += 1
    return reg, loops, tp, sync, tpnames


def hazards(lines, span, threadprivate):
    """`save` / data-initialised locals that the routine also writes to.

    An initialised local is implicitly SAVEd in Fortran, so it survives between
    calls and is shared by every thread.  That is only a race if the routine
    assigns to it -- `integer::tag=101` used as a constant is harmless.
    """
    names, other = [], 0
    a, b = span
    for raw in lines[a-1:b]:
        code = raw.split('!')[0]
        if not code.strip():
            continue
        if DATA.match(code):
            other += 1
            continue
        if '::' not in code:
            continue
        left, right = code.split('::', 1)
        if 'parameter' in left.lower():
            continue
        saved = bool(SAVE.search(left))
        for decl in right.split(','):
            d = decl.strip()
            if not saved and '=' not in d:
                continue                      # plain local, fine
            n = d.split('=')[0].split('(')[0].strip()
            if NAME.match(n):
                names.append(n.lower())
    cand = {n for n in names if n not in threadprivate}
    if not cand:
        return [], other
    written = set()
    for raw in lines[a-1:b]:
        code = raw.split('!')[0]
        if '::' in code:
            continue
        for m in ASSIGN.finditer(code):
            written.add(m.group(1).lower())
        for m in re.finditer(r'\b(?:read|allocate|deallocate)\s*\([^)]*\)?\s*([a-zA-Z_]\w*)',
                             code, re.I):
            written.add(m.group(1).lower())
    return sorted(cand & written), other


def parallel_regions(lines):
    """line intervals covered by a parallel region."""
    out, i, n = [], 0, len(lines)
    while i < n:
        m = PARDIR.match(lines[i])
        if not m:
            i += 1; continue
        rest = m.group(1).strip().lower()
        if rest.split()[0:1] and rest.split()[0] in REGION_KINDS:
            j, depth, started = i + 1, 0, False
            while j < n:
                if re.match(r'^\s*!\$\s*omp\s+end\s+parallel', lines[j]):
                    break
                c = lines[j].split('!')[0]
                if DOSTMT.match(c):
                    depth += 1; started = True
                elif ENDDO.match(c):
                    depth -= 1
                    if started and depth <= 0:
                        break
                j += 1
        else:
            j = i + 1
            while j < n and not ENDPAR.match(lines[j]):
                j += 1
        out.append((i + 1, j + 1)); i = j + 1
    return out


# ------------------------------------------------------------------ main ----
def build(inv):
    routines = []                              # (feature, area, entry)
    for f in inv["features"]:
        for a in f.get("areas") or []:
            for r in a.get("routines") or []:
                routines.append((f["id"], a["id"], r))
    keys = {f"{r['file']}::{r['name'].lower()}" for _, _, r in routines}
    files = sorted({r["file"] for _, _, r in routines})

    # forward edges, resolved the way the inventory resolves callers
    by_name = collections.defaultdict(set)
    for _, _, r in routines:
        by_name[r["name"].lower()].add(f"{r['file']}::{r['name'].lower()}")
    fwd = collections.defaultdict(set)
    for _, _, r in routines:
        me = f"{r['file']}::{r['name'].lower()}"
        for c in r.get("callers") or []:
            if "::" in c:
                srcs = {c.lower()} if c.lower() in keys else set()
            else:
                local = f"{r['file']}::{c.lower()}"
                srcs = {local} if local in keys else by_name.get(c.lower(), set())
            for s in srcs:
                fwd[s].add(me)

    info, seeds, missing = {}, set(), []
    for path in files:
        text = show(REF, path)
        if text is None:
            missing.append(path); continue
        lines = text.split("\n")
        sp = spans(lines)
        regs = parallel_regions(lines)
        for name, span in sp.items():
            key = f"{path}::{name}"
            if key not in keys:
                continue
            reg, loops, tp, sync, tpn = directives(lines, span)
            offenders, other = hazards(lines, span, tpn)
            info[key] = dict(regions=reg, loops=loops, threadprivate=tp,
                             sync=sync, offenders=offenders, data=other)
            # A routine carrying threadprivate/critical but opening no region of
            # its own can only be running inside someone else's region, so all
            # of its callees run under threads too. A routine that DOES open a
            # region runs on one thread outside it, so its callees are threaded
            # only where the call site sits inside the region -- handled below.
            if (tp or sync) and not reg:
                seeds.add(key)
        # anything called from inside a region runs under threads
        for a, b in regs:
            for ln in lines[a-1:b]:
                for m in CALL.finditer(ln.split('!')[0]):
                    nm = m.group(1).lower()
                    local = f"{path}::{nm}"
                    for s in ({local} if local in keys else by_name.get(nm, set())):
                        seeds.add(s)

    under = set(seeds); frontier = list(seeds)
    while frontier:
        nxt = []
        for n in frontier:
            for c in fwd[n]:
                if c not in under:
                    under.add(c); nxt.append(c)
        frontier = nxt

    # routines executed every timestep (amr_step and everything below it)
    per_step = set(); frontier = ["amr/amr_step.f90::amr_step"]
    while frontier:
        nxt = []
        for n in frontier:
            for c in fwd[n]:
                if c not in per_step:
                    per_step.add(c); nxt.append(c)
        frontier = nxt

    state = {}
    for key, d in info.items():
        if d["regions"]:                          s = "opens_region"
        elif d["threadprivate"] or d["sync"]:     s = "adapted"
        elif key in under:  s = "race" if (d["offenders"] or d["data"]) else "stateless"
        else:                                     s = "unthreaded"
        state[key] = dict(d, state=s, under_threads=key in under,
                          per_step=key in per_step)
    return routines, state, missing, fwd


DONE = {"opens_region", "adapted", "stateless"}

def bucket(r, d, fwd, state):
    """done | todo | n/a -- what the area-level progress bar counts."""
    if not d:
        return "na"
    if (r.get("omp") or {}).get("na"):
        return "na"       # a human ruled this one out of scope for OpenMP
    if d["state"] in DONE:
        return "done"
    if d["state"] == "race":
        return "todo"
    if r["phase"] == "step" and d["per_step"]:
        key = f"{r['file']}::{r['name'].lower()}"
        if any(state.get(c, {}).get("state") == "opens_region" for c in fwd[key]):
            return "done"          # single-threaded wrapper around a region
        return "todo"
    return "na"


def report(inv, routines, state, fwd, only=None):
    MARK = {"opens_region": "R", "adapted": "A", "stateless": "s",
            "race": "!", "unthreaded": "."}
    for f in inv["features"]:
        if only and f["id"] not in only:
            continue
        ftot = collections.Counter()
        out = []
        for a in f.get("areas") or []:
            c = collections.Counter(); bar = ""
            for r in a.get("routines") or []:
                d = state.get(f"{r['file']}::{r['name'].lower()}")
                c[bucket(r, d, fwd, state)] += 1
                bar += MARK.get(d["state"] if d else "?", "?")
            ftot += c
            den = c["done"] + c["todo"]
            pct = f"{100*c['done']//den:3d}%" if den else "  -"
            out.append(f"  {a['id']:<34}{sum(c.values()):4d} "
                       f"{c['done']:5d} {c['todo']:5d} {c['na']:4d}  {pct}  {bar}")
        den = ftot["done"] + ftot["todo"]
        pct = f"{100*ftot['done']//den:3d}%" if den else "  -"
        print(f"\n{f['id']:<34}{sum(ftot.values()):6d} {ftot['done']:5d} "
              f"{ftot['todo']:5d} {ftot['na']:4d}  {pct}")
        print("\n".join(out))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--json")
    ap.add_argument("--feature", action="append")
    args = ap.parse_args()

    inv = yaml.safe_load(open(INV))
    routines, state, missing, fwd = build(inv)
    if missing:
        print(f"warning: {len(missing)} file(s) absent from {REF}: "
              + ", ".join(missing[:5]), file=sys.stderr)
    unmatched = [f"{r['file']}::{r['name']}" for _, _, r in routines
                 if f"{r['file']}::{r['name'].lower()}" not in state]
    if unmatched:
        print(f"warning: {len(unmatched)} inventory routine(s) not found on "
              f"{REF}: " + ", ".join(unmatched[:5]), file=sys.stderr)

    if args.json:
        json.dump(state, open(args.json, "w"), indent=1)
    if args.report or not (args.write or args.json):
        print(f"{'feature / area':<34}{'n':>6} {'done':>5} {'todo':>5} {'n/a':>4}")
        report(inv, routines, state, fwd, set(args.feature) if args.feature else None)
        c = collections.Counter(v["state"] for v in state.values())
        print("\nstates:", dict(c))
    if args.write:
        for feat, area, r in routines:
            key = f"{r['file']}::{r['name'].lower()}"
            if key in state:
                state[key]["progress"] = bucket(r, state[key], fwd, state)
        rewrite(state)


def rewrite(state):
    """Replace the omp:/omp_from:/notes: blocks in inventory.yaml in place."""
    src = open(INV).read().split("\n")
    out, i, n = [], 0, len(src)
    cur = None
    while i < n:
        line = src[i]
        m = re.match(r'^(\s+)- file: (\S+)\s*$', line)
        if m:
            cur = m.group(2)
        m2 = re.match(r'^(\s+)name: (\S+)\s*$', line)
        if m2 and cur:
            cur = f"{cur}::{m2.group(2).lower()}"
        if re.match(r'^\s+(omp|notes):\s*$', line) or \
           re.match(r'^\s+omp_from:\s', line):
            ind = len(line) - len(line.lstrip())
            block = []
            j = i + 1
            while j < n and (not src[j].strip() or
                             len(src[j]) - len(src[j].lstrip()) > ind):
                block.append(src[j]); j += 1
            if line.strip().startswith("notes:"):
                note = next((b.split(":", 1)[1].strip()
                             for b in block if b.strip().startswith("public:")), None)
                if note:
                    KEEP.setdefault(cur, {})["note"] = note
            elif line.strip().startswith("omp:"):
                for b in block:
                    k, _, v = b.strip().partition(":")
                    v = v.strip()
                    if k == "public" and v:            # pre-derivation spelling
                        KEEP.setdefault(cur, {})["recorded"] = v.strip('"')
                    elif k in HUMAN and v:
                        KEEP.setdefault(cur, {})[k] = v.strip('"')
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
            d = state.get(cur)
            if d:
                p = " " * ind
                final.append(f"{p}omp:")
                final.append(f"{p}  state: {d['state']}")
                final.append(f"{p}  progress: {d['progress']}")
                for k in ("regions", "threadprivate", "sync"):
                    if d[k]:
                        final.append(f"{p}  {k}: {d[k]}")
                if d["state"] == "race" and d["offenders"]:
                    final.append(f"{p}  unprotected: [{', '.join(d['offenders'])}]")
                keep = KEEP.get(cur, {})
                for k in ("na", "verified"):
                    if keep.get(k):
                        final.append(f"{p}  {k}: {keep[k]}")
                rec = keep.get("recorded")
                if rec:
                    final.append(f'{p}  recorded: "{rec}"')
                    if disagrees(rec, d["state"]):
                        final.append(f"{p}  disagrees: true")
                if keep.get("note"):
                    final.append(f"{p}  note: {keep['note']}")
            cur = None
        i += 1
    open(INV, "w").write("\n".join(final))
    print(f"inventory.yaml rewritten: {len(state)} omp blocks")


# keys under `omp:` that a human owns -- derive_omp.py carries them across
HUMAN = {"recorded", "note", "na", "verified"}
KEEP = {}

def disagrees(rec, derived):
    r = str(rec).strip().lower()
    if r in ("", "-"):
        return False
    if r in ("yes", "y"):
        return derived in ("unthreaded", "race")
    if r == "no":
        return derived in ("opens_region", "adapted")
    return True          # todo / todo? / maybe / wip -- still an open question


if __name__ == "__main__":
    main()
