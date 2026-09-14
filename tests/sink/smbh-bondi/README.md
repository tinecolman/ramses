* Test name: `smbh_bondi`
* Dimension: `3`
* Solver: `hydro`
* Comparison: md5sum of the sink output (`output_00002/sink_00002.csv`) at the end of the run
* Purpose: Testing the implementation of sink-SMBH Bondi-accretion
* Keywords: sink dynamics, sink accretion (Bondi), PIC

WARNING: This test uses the `experimental_sink` patch. To be adjusted after it is made default.

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 64 areas; most of its lines fall in **mesh**, **particles**, **gravity**. 90 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| mesh | boundaries | 119 | 100% |  |
| particles | time_step | 19 | 100% |  |
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| gravity | interpolation | 50 | 94% |  |
| mesh | output | 102 | 91% |  |
| gravity | boundaries | 88 | 90% |  |
| hydrodynamics | hydro_source_terms | 111 | 88% |  |
| gravity | output | 40 | 82% |  |
| gravity | force_calculation | 108 | 81% |  |
| gravity | multigrid | 894 | 80% |  |
| mesh | memory_management | 308 | 79% |  |
| hydrodynamics | hydro_core | 68 | 76% |  |
| hydrodynamics | hydro_courant | 91 | 76% |  |
| particles | output | 93 | 76% |  |
| sinks | update | 249 | 74% | 54 |
| sinks | accretion | 389 | 72% | 15 |
| amr_core | output | 153 | 72% |  |
| domains | load_balancing | 329 | 70% |  |
| utilities | memory | 27 | 69% |  |

44 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
