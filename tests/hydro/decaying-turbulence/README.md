# decaying-turbulence

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 30 areas; most of its lines fall in **amr_core**, **hydrodynamics**, **utilities**. 36 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| amr_core | units | 10 | 100% |  |
| hydrodynamics | hydro_core | 68 | 76% |  |
| amr_core | shutdown | 51 | 75% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| amr_core | output | 230 | 63% |  |
| hydrodynamics | output | 69 | 56% |  |
| refinement | grid_linked_list | 372 | 54% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| amr_core | grid_setup | 128 | 51% |  |
| amr_core | main_loop | 381 | 48% |  |
| hydrodynamics | hydro_source_terms | 51 | 40% |  |
| hydrodynamics | setup | 282 | 39% | 5 |
| utilities | neighbour_search | 66 | 34% |  |
| amr_core | dump_helpers | 10 | 25% |  |
| timestepping | time_step | 185 | 22% | 31 |

13 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
