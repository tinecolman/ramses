# sod-tube-nener

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 41 areas; most of its lines fall in **mesh**, **hydrodynamics**, **utilities**. 143 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| mesh | boundaries | 119 | 100% |  |
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 98 | 88% |  |
| hydrodynamics | hydro_courant | 100 | 83% |  |
| mesh | refinement | 477 | 69% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| mesh | setup | 282 | 64% |  |
| hydrodynamics | output | 78 | 63% |  |
| amr_core | output | 133 | 63% |  |
| utilities | communication | 350 | 61% |  |
| mesh | memory_management | 213 | 55% |  |
| hydrodynamics | hydro_interpolation | 133 | 54% |  |
| mesh | flagging | 198 | 54% |  |
| utilities | file | 16 | 53% |  |
| amr_core | main_loop | 220 | 52% |  |
| mesh | neighbour_search | 90 | 47% |  |
| hydrodynamics | hydro_core | 41 | 46% |  |
| hydrodynamics | screen_diagnostics | 123 | 40% | 115 |

21 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
