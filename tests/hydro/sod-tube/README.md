# sod-tube

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 30 areas; most of its lines fall in **refinement**, **amr_core**, **hydro_solver**. 213 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| domains | boundary_setup | 119 | 100% |  |
| amr_core | units | 10 | 100% |  |
| amr_core | shutdown | 51 | 75% |  |
| utilities | timer | 66 | 72% |  |
| hydro_solver | riemann_solvers | 306 | 71% | 171 |
| refinement | grid_linked_list | 477 | 69% |  |
| amr_core | output | 229 | 63% |  |
| utilities | communication | 350 | 61% |  |
| hydrodynamics | output | 69 | 56% |  |
| utilities | file | 16 | 53% |  |
| amr_core | grid_setup | 119 | 48% |  |
| utilities | neighbour_search | 90 | 47% |  |
| hydrodynamics | hydro_core | 41 | 46% |  |
| amr_core | main_loop | 317 | 40% |  |
| refinement | flagging | 289 | 39% |  |
| hydro_solver | slope_types | 50 | 38% | 26 |
| amr_core | dump_helpers | 10 | 25% |  |
| hydro_solver | godunov_solver | 227 | 21% | 8 |
| refinement | interpolation | 202 | 20% | 8 |

11 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
