# mixing-scalar

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 39 areas; most of its lines fall in **mesh**, **hydrodynamics**, **amr_core**. 10 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 95 | 85% |  |
| hydrodynamics | hydro_core | 68 | 76% |  |
| hydrodynamics | hydro_courant | 88 | 73% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| domains | load_balancing | 321 | 68% | 10 |
| mesh | refinement | 451 | 65% |  |
| mesh | setup | 282 | 64% |  |
| amr_core | output | 134 | 63% |  |
| hydrodynamics | output | 74 | 60% |  |
| hydrodynamics | hydro_interpolation | 135 | 55% |  |
| amr_core | main_loop | 229 | 54% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| mesh | memory_management | 194 | 50% |  |
| mesh | flagging | 179 | 49% |  |
| mesh | neighbour_search | 88 | 46% |  |
| hydrodynamics | hydro_source_terms | 54 | 43% |  |

19 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
