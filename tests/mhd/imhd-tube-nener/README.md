# imhd-tube-nener

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 41 areas; most of its lines fall in **mesh**, **hydrodynamics**, **amr_core**. 67 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| mesh | boundaries | 119 | 100% |  |
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 98 | 88% |  |
| hydrodynamics | output | 92 | 75% |  |
| mesh | refinement | 479 | 70% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| mesh | setup | 282 | 64% |  |
| amr_core | output | 133 | 63% |  |
| hydrodynamics | mhd_source_terms | 51 | 57% | 3 |
| hydrodynamics | mhd_courant | 110 | 56% | 9 |
| mesh | memory_management | 213 | 55% |  |
| utilities | communication | 313 | 54% |  |
| mesh | flagging | 198 | 54% |  |
| utilities | file | 16 | 53% |  |
| amr_core | main_loop | 224 | 53% |  |
| hydrodynamics | mhd_interpolation | 335 | 52% |  |
| hydrodynamics | screen_diagnostics | 155 | 51% | 10 |
| mesh | neighbour_search | 90 | 47% |  |

21 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
