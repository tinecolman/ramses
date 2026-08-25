* Test name: `sn-blast`
* Dimension: `3`
* Solver: `hydro`
* Comparison: sums over the hydro fields and the sink variables of `output_00002`
* Purpose: Testing supernova feedback from a sink, isolated from the Poisson solver
* Keywords: sink feedback (SN), stellar objects, PIC

A single sink sits at (158.5, 107.75, 133.75) pc in a 250 pc box of uniform
10 H/cc gas at 10 K, that is off-centre and off every symmetry plane. Its
`dmfsink` in `ic_sink` is above `stellar_msink_th`, so one stellar object of
100 M_sun (fixed through `mstellarini`, so the IMF draw plays no role) is
created on the first step and, because `sn_direct=.true.`, explodes right away.
The blast then expands into the uniform medium for 0.002 code units (~0.19 Myr).

Why this test exists next to `center-SN` and `stellar-HII`: those two are
symmetric and self-gravitating, so a roundoff-level difference in the multigrid
solution breaks the symmetry and grows, which makes their reference solutions
depend on the domain decomposition and on the number of OpenMP threads
(`stellar-HII` needs tolerances of 3e-6 for that reason). Here gravity is off
(`poisson=.false.`) and the refinement is purely geometric, so the mesh is
static and nothing amplifies a small error. The reference was generated on one
process with one thread and is reproduced to the default 3e-13 tolerance at
1, 2 and 4 MPI processes and at 1, 2 and 4 OpenMP threads.

Accretion is switched off (`accretion_scheme='none'`) so that the supernova is
the only thing acting on the sink and on the gas. Note that the injected energy
is ~2.9e50 erg rather than the full 1e51 erg, because the thermal dump is capped
by `Tsat`; the injected momentum matches `sn_p_ref` exactly.
