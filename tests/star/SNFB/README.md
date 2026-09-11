# SNFB

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 43 areas; most of its lines fall in **particles**, **gravity**, **amr_core**. 366 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| amr_core | units | 10 | 100% |  |
| hydrodynamics | hydro_source_terms | 115 | 91% |  |
| amr_core | shutdown | 61 | 90% |  |
| gravity | force_calculation | 111 | 83% |  |
| gravity | multigrid | 904 | 81% |  |
| hydrodynamics | hydro_core | 71 | 80% |  |
| subgrid | feedback | 396 | 78% | 268 |
| gravity | output | 38 | 78% |  |
| particles | output | 94 | 76% |  |
| amr_core | output | 249 | 69% |  |
| utilities | timer | 63 | 68% |  |
| utilities | neighbour_search | 131 | 68% |  |
| refinement | grid_linked_list | 466 | 68% |  |
| particles | particle_tree | 433 | 67% |  |
| utilities | memory | 26 | 67% |  |
| utilities | rng | 82 | 64% |  |
| amr_core | main_loop | 482 | 61% |  |
| hydrodynamics | output | 75 | 61% |  |
| particles | position_and_velocity_update | 324 | 60% |  |
| gravity | setup | 71 | 60% |  |

23 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
