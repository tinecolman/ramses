# mixing-scalar

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 31 areas; most of its lines fall in **amr_core**, **refinement**, **domains**. 10 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| amr_core | units | 10 | 100% |  |
| hydrodynamics | hydro_core | 68 | 76% |  |
| amr_core | shutdown | 51 | 75% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| refinement | grid_linked_list | 451 | 65% |  |
| amr_core | output | 227 | 63% |  |
| hydrodynamics | output | 74 | 60% |  |
| amr_core | main_loop | 459 | 58% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| amr_core | grid_setup | 126 | 51% |  |
| utilities | neighbour_search | 88 | 46% |  |
| domains | load_balancing | 541 | 45% | 10 |
| hydrodynamics | hydro_source_terms | 54 | 43% |  |
| refinement | flagging | 277 | 38% |  |
| hydrodynamics | setup | 233 | 32% |  |
| hydro_solver | godunov_solver | 295 | 28% |  |
| utilities | sorting | 31 | 27% |  |
| amr_core | dump_helpers | 10 | 25% |  |

11 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
