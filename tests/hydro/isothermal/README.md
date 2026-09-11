# isothermal

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 36 areas; most of its lines fall in **gravity**, **refinement**, **amr_core**. 2 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| amr_core | units | 10 | 100% |  |
| gravity | multigrid | 901 | 81% |  |
| gravity | force_calculation | 107 | 80% |  |
| gravity | output | 38 | 78% |  |
| amr_core | shutdown | 51 | 75% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| amr_core | output | 229 | 63% |  |
| refinement | grid_linked_list | 418 | 61% |  |
| utilities | neighbour_search | 113 | 59% |  |
| hydrodynamics | output | 67 | 54% |  |
| utilities | communication | 309 | 54% |  |
| utilities | file | 16 | 53% |  |
| amr_core | grid_setup | 119 | 48% |  |
| hydrodynamics | hydro_core | 41 | 46% |  |
| amr_core | main_loop | 362 | 46% |  |
| hydrodynamics | hydro_source_terms | 54 | 43% |  |
| refinement | flagging | 270 | 37% |  |
| amr_core | dump_helpers | 10 | 25% |  |
| hydrodynamics | setup | 140 | 19% | 2 |

16 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
