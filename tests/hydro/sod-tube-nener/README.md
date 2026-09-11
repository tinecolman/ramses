# sod-tube-nener

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 33 areas; most of its lines fall in **refinement**, **amr_core**, **hydrodynamics**. 143 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| domains | boundary_setup | 119 | 100% |  |
| amr_core | units | 10 | 100% |  |
| amr_core | shutdown | 51 | 75% |  |
| refinement | grid_linked_list | 477 | 69% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| hydrodynamics | output | 78 | 63% |  |
| amr_core | output | 229 | 63% |  |
| utilities | communication | 350 | 61% |  |
| amr_core | main_loop | 450 | 57% |  |
| utilities | file | 16 | 53% |  |
| amr_core | grid_setup | 126 | 51% |  |
| utilities | neighbour_search | 90 | 47% |  |
| hydrodynamics | hydro_core | 41 | 46% |  |
| refinement | flagging | 299 | 41% |  |
| hydrodynamics | screen_diagnostics | 123 | 40% | 115 |
| hydrodynamics | hydro_source_terms | 50 | 40% |  |
| hydrodynamics | setup | 263 | 36% |  |
| utilities | sorting | 31 | 27% |  |
| amr_core | dump_helpers | 10 | 25% |  |

13 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
