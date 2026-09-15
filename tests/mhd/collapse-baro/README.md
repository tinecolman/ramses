* Test name: `collapse-baro'
* Dimension: `3`
* Solver: `mhd`
* Purpose: Testing the MHD + gravity implementation
* Keywords: mhd, collapse, barotrop

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 47 areas; most of its lines fall in **mesh**, **gravity**, **mhd_solver**. 338 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| utilities | units | 10 | 100% |  |
| gravity | conjugent_gradient | 158 | 99% | 158 |
| mesh | shutdown | 33 | 97% |  |
| gravity | interpolation | 48 | 91% |  |
| mesh | output | 97 | 87% |  |
| gravity | force_calculation | 111 | 83% |  |
| gravity | multigrid | 903 | 81% |  |
| gravity | output | 38 | 78% |  |
| mesh | refinement | 478 | 69% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| mesh | neighbour_search | 131 | 68% |  |
| amr_core | main_loop | 282 | 66% | 1 |
| amr_core | output | 140 | 66% |  |
| hydrodynamics | output | 81 | 66% |  |
| mesh | setup | 291 | 66% |  |
| domains | load_balancing | 306 | 65% |  |
| gravity | setup | 80 | 62% |  |
| mhd_solver | godunov_solver | 1026 | 61% | 35 |
| mesh | memory_management | 231 | 59% |  |

27 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
