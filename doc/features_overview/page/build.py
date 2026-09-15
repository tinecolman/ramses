#!/usr/bin/env python3
import yaml, json, os
D=os.path.dirname(os.path.abspath(__file__))
INV="/home/tcolman/Codes/ramses/doc/features_overview/inventory.yaml"
d=yaml.safe_load(open(INV))
d.pop("open_tasks", None)   # standing tasks live in the YAML, not on the page
rs=[r for f in d["features"] for a in f["areas"] for r in a["routines"]]
def prog(r): return (r.get("omp") or {}).get("progress")
_c=sum((r.get("coverage") or {}).get("covered",0) for r in rs)
_t=sum((r.get("coverage") or {}).get("total",0) for r in rs)
cov_pct=round(100*_c/_t,1) if _t else 0

# Features are listed in the order the YAML lists them, which is the order a
# run reaches them. They are deliberately not grouped under headings; see the
# note under "Per feature" in inventory.yaml for why that was tried and undone.

# ---- cross-feature coupling, derived from `callers` ------------------------
# This is what a top-level grouping could not express, and it is derived rather
# than decided. Caller names resolve exactly as validate_inventory.py does: to a
# definition in the same file when there is one, else to every definition of
# that name.
by_name, by_file_name = {}, {}
for f in d["features"]:
    for a in f["areas"]:
        for r in a["routines"]:
            nm=str(r["name"]).lower()
            by_name.setdefault(nm,set()).add(f["id"])
            by_file_name[(r["file"],nm)]=f["id"]
by_name.setdefault("program",{"amr_core"})
def resolve(caller, same_file):
    if "::" in caller:
        cf,cn=caller.rsplit("::",1)
        hit=by_file_name.get((cf,cn.lower()))
        return {hit} if hit else set()
    c=caller.lower()
    if (same_file,c) in by_file_name: return {by_file_name[(same_file,c)]}
    return by_name.get(c,set())

edges={}          # (caller feature, callee feature) -> number of call sites
unresolved=set()
for f in d["features"]:
    for a in f["areas"]:
        for r in a["routines"]:
            for c in (r.get("callers") or []):
                hits=resolve(c, r["file"])
                if not hits: unresolved.add(c); continue
                for cf in hits:
                    if cf!=f["id"]:
                        edges[(cf,f["id"])]=edges.get((cf,f["id"]),0)+1
def _rank(fid, idx):
    out=[[b if idx==0 else a, n] for (a,b),n in edges.items()
         if (a if idx==0 else b)==fid]
    return sorted(out, key=lambda x:(-x[1], x[0]))
for f in d["features"]:
    f["uses"]=_rank(f["id"],0)        # this feature calls into those
    f["used_by"]=_rank(f["id"],1)     # those call into this feature

d["stats"]={"routines":len(rs),
            "done":sum(1 for r in rs if prog(r)=="done"),
            "todo":sum(1 for r in rs if prog(r)=="todo"),
            "need":sum(1 for r in rs if prog(r) in ("done","todo")),
            "unsafe":sum(1 for r in rs if (r.get("omp") or {}).get("state")=="unsafe"),
            "drivers":sum(1 for r in rs if r.get("driver")),
            "utils":sum(1 for r in rs if r.get("scope")=="global"),
            "features":len(d["features"]),
            "areas":sum(len(f["areas"]) for f in d["features"]),
            "files":len({r["file"] for r in rs}),
            "cov_pct":cov_pct,
            "cov_zero":sum(1 for r in rs if (r.get("coverage") or {}).get("pct")==0),
            "cov_na":sum(1 for r in rs if (r.get("coverage") or {}).get("pct") is None),
            "edges":len(edges),
            "unresolved":len(unresolved)}

# which tests reach which routines, from derive_test_map.py --write
TM=os.path.join(os.path.dirname(INV), "tests_by_routine.json")
if os.path.exists(TM):
    tm=json.load(open(TM))
    d["tests_by_routine"]={"names":tm["names"],"paths":tm["paths"],
                           "routines":tm["routines"],"run":tm["run"]}
    d["stats"]["tests"]=len(tm["names"])
    d["stats"]["untested"]=len(rs)-len(tm["routines"])

QUESTIONS=json.load(open(D+"/questions.json"))
APPLIED=["hydrodynamics splits three ways: the update, hydro_amr and hydro_ic",
 "flagging, interpolation and boundaries become hydro_amr, 28 routines",
 "the hydro/mhd build alternatives now share one area: 17 areas become 13",
 "init_flow_fine is the IC dispatcher; it and init_flow left setup for the ICs",
 "input.rst attached to hydrodynamics",
 "init_time is the setup dispatcher; 10 routines were phase step, not init",
 "expansion moved into Program core under setup; cosmo dissolved",
 "timestepping dissolved: clock to Program core, Courant to hydro/mhd",
 "new cosmo feature holds the Friedmann machinery",
 "mesh moved up to second, its areas reordered, both summaries rewritten",
 "domains split into load balancing, Hilbert and bisection",
 "boundary_setup was never domain decomposition: now mesh/boundaries",
 "the hydro/mhd prolongation limiters have drifted: 6 todos added",
 "per-physics refinement criteria moved to hydro, rt and gravity",
 "mesh/interpolation dissolved: every routine in it was per-physics",
 "12 old OpenMP status notes cleared",
 "Program core areas in chronological order; parameters.rst and output.rst attached",
 "deallocate_amr into its own mesh/shutdown area",
 "refinement is now `mesh`, Mesh data structures: 7 areas, 68 routines",
 "neighbour_search moved out of utilities into the mesh",
 "amr.rst moved from Program core to the mesh",
 "amr_core is now Program core: 15 routines, not 34",
 "your 13 routine flags applied; 15 scope values recomputed",
 "savegadget split out as gadget_output, like movie",
 "the units area moved to shared utilities",
 "params and output stay with their feature; see q18-io for why",
 "dump_utils moved to utilities \u2014 it is shared mechanism, not a leaf",
 "additional_output split into light_cone and movie: they share no code",
 "\u201cExercised by\u201d narrows the page to one test\u2019s reach",
 "\u201cUnder review\u201d marks what this pass is working through",
 "which tests reach which routine, derived from the coverage run",
 "top-level grouping taken out again: one flat list, in run order",
 "every feature now carries a summary and a link to its lecture",
 "features and areas collapse; the page opens as the map, not the detail",
 "cross-feature coupling derived from callers and shown on every feature",
 "status dimensions are now a table: benchmarks and docs appear when filled",
 "test coverage joined to every routine, from the full 41-test run",
 "coverage shown per routine, per area and per feature, next to the OpenMP state",
 "each test README now lists the feature areas it exercises"]

head=open(D+"/head.part").read(); tail=open(D+"/tail.part").read()
out=(head + "const DATA = " + json.dumps(d,separators=(",",":")) + ";\n"
     + "const QUESTIONS = " + json.dumps(QUESTIONS) + ";\n"
     + "const APPLIED = " + json.dumps(APPLIED) + ";\n" + tail)
p=D+"/ramses-inventory.html"; open(p,"w").write(out)
print(f"wrote {p} ({len(out)/1024:.0f} KB, {len(rs)} routines, "
      f"{d['stats']['features']} features, {len(edges)} cross-feature edges, "
      f"{len(unresolved)} caller names unresolved)")
