# orszag-tang

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 37 areas; most of its lines fall in **mesh**, **hydrodynamics**, **mhd_solver**. 241 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 95 | 85% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| hydrodynamics | output | 81 | 66% |  |
| mesh | refinement | 445 | 65% |  |
| mesh | setup | 282 | 64% |  |
| amr_core | output | 134 | 63% |  |
| hydrodynamics | mhd_interpolation | 406 | 62% | 33 |
| mesh | flagging | 200 | 55% |  |
| utilities | file | 16 | 53% |  |
| amr_core | main_loop | 227 | 53% |  |
| utilities | communication | 303 | 53% |  |
| hydrodynamics | mhd_courant | 101 | 51% |  |
| mesh | memory_management | 194 | 50% |  |
| mesh | neighbour_search | 88 | 46% |  |
| hydrodynamics | mhd_core | 41 | 45% |  |
| mhd_solver | godunov_solver | 708 | 42% | 178 |
| domains | hilbert_decomposition | 26 | 38% |  |

17 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
