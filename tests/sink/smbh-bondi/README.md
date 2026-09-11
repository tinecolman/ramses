* Test name: `smbh_bondi`
* Dimension: `3`
* Solver: `hydro`
* Comparison: md5sum of the sink output (`output_00002/sink_00002.csv`) at the end of the run
* Purpose: Testing the implementation of sink-SMBH Bondi-accretion
* Keywords: sink dynamics, sink accretion (Bondi), PIC

WARNING: This test uses the `experimental_sink` patch. To be adjusted after it is made default.

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 54 areas; most of its lines fall in **particles**, **gravity**, **sinks**. 90 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| domains | boundary_setup | 119 | 100% |  |
| amr_core | units | 10 | 100% |  |
| gravity | boundaries | 88 | 90% |  |
| amr_core | shutdown | 61 | 90% |  |
| hydrodynamics | hydro_source_terms | 111 | 88% |  |
| gravity | output | 40 | 82% |  |
| gravity | force_calculation | 108 | 81% |  |
| gravity | multigrid | 894 | 80% |  |
| hydrodynamics | hydro_core | 68 | 76% |  |
| particles | output | 93 | 76% |  |
| sinks | update | 249 | 74% | 54 |
| sinks | accretion | 389 | 72% | 15 |
| amr_core | output | 253 | 70% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| refinement | grid_linked_list | 442 | 64% |  |
| utilities | rng | 82 | 64% |  |
| sinks | setup | 176 | 63% | 11 |
| utilities | file | 18 | 60% |  |
| utilities | neighbour_search | 111 | 58% |  |

34 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
