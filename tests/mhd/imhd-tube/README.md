# imhd-tube

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 40 areas; most of its lines fall in **mesh**, **mhd_solver**, **hydro_amr**. 305 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| mesh | boundaries | 119 | 100% |  |
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 98 | 88% |  |
| utilities | timer | 66 | 72% |  |
| mhd_solver | riemann_solvers | 447 | 71% | 297 |
| mesh | refinement | 479 | 70% |  |
| utilities | memory | 27 | 69% |  |
| hydrodynamics | output | 83 | 67% |  |
| amr_core | output | 133 | 63% |  |
| mesh | memory_management | 213 | 55% |  |
| utilities | communication | 313 | 54% |  |
| mesh | flagging | 198 | 54% |  |
| utilities | file | 16 | 53% |  |
| amr_core | main_loop | 224 | 53% |  |
| hydrodynamics | screen_diagnostics | 146 | 48% | 1 |
| mesh | neighbour_search | 90 | 47% |  |
| hydro_amr | boundaries | 120 | 38% |  |
| hydro_amr | interpolation | 335 | 37% |  |
| hydro_amr | flagging | 105 | 37% |  |

20 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
