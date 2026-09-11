* Test name: `collapse-baro'
* Dimension: `3`
* Solver: `mhd`
* Purpose: Testing the MHD + gravity implementation
* Keywords: mhd, collapse, barotrop

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 40 areas; most of its lines fall in **gravity**, **refinement**, **mhd_solver**. 338 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| amr_core | units | 10 | 100% |  |
| gravity | conjugent_gradient | 158 | 99% | 158 |
| hydrodynamics | mhd_source_terms | 84 | 94% | 36 |
| gravity | force_calculation | 111 | 83% |  |
| gravity | multigrid | 903 | 81% |  |
| hydrodynamics | mhd_core | 72 | 78% | 31 |
| gravity | output | 38 | 78% |  |
| amr_core | shutdown | 51 | 75% |  |
| refinement | grid_linked_list | 478 | 69% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| utilities | neighbour_search | 131 | 68% |  |
| hydrodynamics | output | 81 | 66% |  |
| amr_core | main_loop | 517 | 66% | 1 |
| amr_core | output | 235 | 65% |  |
| mhd_solver | godunov_solver | 1026 | 61% | 35 |
| gravity | setup | 71 | 60% |  |
| utilities | communication | 309 | 54% |  |
| utilities | file | 16 | 53% |  |
| amr_core | grid_setup | 130 | 52% |  |

20 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
