# advect1d

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 37 areas; most of its lines fall in **mesh**, **hydrodynamics**, **amr_core**. 14 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 93 | 83% |  |
| hydrodynamics | hydro_courant | 88 | 73% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| mesh | setup | 278 | 63% |  |
| amr_core | output | 133 | 63% |  |
| mesh | refinement | 431 | 63% |  |
| hydrodynamics | output | 67 | 54% |  |
| mesh | flagging | 198 | 54% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| amr_core | main_loop | 219 | 51% |  |
| mesh | memory_management | 194 | 50% |  |
| hydrodynamics | hydro_core | 41 | 46% |  |
| mesh | neighbour_search | 84 | 44% |  |
| hydrodynamics | hydro_interpolation | 83 | 34% |  |
| amr_core | setup | 123 | 30% |  |
| hydrodynamics | setup | 206 | 28% |  |

17 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
