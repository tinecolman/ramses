* Test name: `stellar-HII`
* Dimension: `3`
* Solver: `hydro` + `RT` (`NGROUPS=3`, `NIONS=3`)
* Comparison: gas, RT and movie variables, plus all sink and stellar object columns of `output_00002`
* Purpose: Testing sink merging, stellar object spawning, and ionising radiation from sinks
* Keywords: sink dynamics, sink merging, stellar objects, RT, HII region, PIC

## Setup

250 pc box, uniform 10 H/cc at T = 10 K, `levelmin=6`, `levelmax=8`,
`nlevelmax_sink=7`. Six sinks are read from `ic_sink`; `create_sinks=.false.`,
so no sink ever forms from the gas and there is no formation threshold to make
the run non-reproducible.

| id | mass (Msun) | position | velocity |
|----|-------------|----------|----------|
| 6  | 4079        | (125,125,125) — box centre | at rest |
| 1  | 4079        | (200,200,125) | at rest |
| 4  | 40.79       | (50,200,125)  | at rest |
| 5  | 40.79       | (200,50,125)  | at rest |
| 2  | 20.395      | (55,50,125)   | `vx = -119` |
| 3  | 20.395      | (45,50,125)   | `vx = +119` |

Sinks 2 and 3 are aimed at each other and **merge** during the run, so
`output_00002` contains five sinks (ids 1, 2, 4, 5, 6). The merged sink keeps
the lower id, which is why the namelist notes `sink_id != isink`.

`stellar=.true.` with `stellar_msink_th=300`, so the two massive sinks spawn
**two stellar objects, on sinks 1 and 6**. `mstellarini=50,50,50,50,50,50`
fixes the first six stellar masses at 50 Msun (2039.2 in code units).

With `rt_sink=.true.`, those two stellar objects drive the HII regions.

## Symmetry

Every sink starts at `z = 125` with `vz = 0`, the gas is uniform, and the only
non-zero initial velocities are in-plane. The whole configuration is therefore
**exactly reflection-symmetric about the plane z = 125**.

Since `l = sum m (r x v)`, and under `z -> -z` both `r_z` and `v_z` flip sign
while the in-plane components do not, the `x` and `y` components of `r x v` are
odd and must cancel. So for every sink, at all times:

* `vz = 0`
* `lx = ly = 0`
* `lz` is the only component the physics permits

**Any non-zero `vz`, `lx` or `ly` is purely numerical.**
