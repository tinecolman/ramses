# advect1d

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 29 areas; most of its lines fall in **amr_core**, **refinement**, **utilities**. 14 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| amr_core | units | 10 | 100% |  |
| amr_core | shutdown | 51 | 75% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| refinement | grid_linked_list | 431 | 63% |  |
| amr_core | output | 224 | 62% |  |
| amr_core | main_loop | 445 | 57% |  |
| hydrodynamics | output | 67 | 54% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| amr_core | grid_setup | 123 | 49% |  |
| hydrodynamics | hydro_core | 41 | 46% |  |
| utilities | neighbour_search | 84 | 44% |  |
| refinement | flagging | 277 | 38% |  |
| hydrodynamics | setup | 206 | 28% |  |
| amr_core | dump_helpers | 10 | 25% |  |
| hydro_solver | godunov_solver | 215 | 20% | 3 |
| hydro_solver | slope_types | 11 | 8% | 11 |

11 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
