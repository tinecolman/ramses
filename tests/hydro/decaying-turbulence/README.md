# decaying-turbulence

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 38 areas; most of its lines fall in **mesh**, **hydrodynamics**, **amr_core**. 36 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 97 | 87% |  |
| hydrodynamics | hydro_core | 68 | 76% |  |
| hydrodynamics | hydro_courant | 88 | 73% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| amr_core | output | 135 | 64% |  |
| mesh | setup | 250 | 56% |  |
| hydrodynamics | output | 69 | 56% |  |
| mesh | refinement | 372 | 54% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| mesh | memory_management | 194 | 50% |  |
| domains | hilbert_decomposition | 30 | 44% |  |
| amr_core | main_loop | 183 | 43% |  |
| hydrodynamics | hydro_source_terms | 51 | 40% |  |
| hydrodynamics | setup | 282 | 39% | 5 |
| mesh | neighbour_search | 66 | 34% |  |
| amr_core | setup | 129 | 32% | 1 |

18 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
