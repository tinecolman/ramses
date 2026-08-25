* Test name: `hii-region`
* Dimension: `3`
* Solver: `hydro` with `RT=1 NGROUPS=3 NIONS=3`
* Comparison: sums over the hydro, RT and sink variables of `output_00002`
* Purpose: Testing ionising feedback from a sink, isolated from the Poisson solver
* Keywords: sink feedback (HII), radiative transfer, stellar objects, PIC

Radiative counterpart of `sn-blast`, with the same initial conditions: a single
sink at (158.5, 107.75, 133.75) pc in a 250 pc box of uniform 10 H/cc gas at
10 K, off-centre and off every symmetry plane. One stellar object of 50 M_sun
(fixed through `mstellarini`) is created on the first step and ionises the gas
around it through `sink_rt_feedback` for the whole run (`hii_t` is much longer
than the run). Unlike `stellar-HII` this test has `cooling=.true.`, which is
what lets the RT thermochemistry heat the ionised gas to ~1e4 K; the resulting
over-pressured region then expands and the density inside drops from 10 to
~5 H/cc by the end of the run. With `cooling=.false.` the gas stays at 10 K and
the ionised fraction saturates around 0.4 with no dynamical response, which
covers much less of the code.

As in `sn-blast`, gravity is off (`poisson=.false.`) and the refinement is
purely geometric, so the mesh is static and there is nothing for a roundoff
level error to be amplified by. This is the difference with `stellar-HII`,
which covers the same code path in a symmetric, self-gravitating box and needs
tolerances of 3e-6.

`rt_c_fraction` is 1e-4 rather than the 1e-6 of `stellar-HII`, so that the
ionisation front reaches a good fraction of the Stromgren radius (~15 pc for
these parameters) within a short run.
