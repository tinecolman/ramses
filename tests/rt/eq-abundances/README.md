# eq-abundances

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 36 areas; most of its lines fall in **cooling**, **mesh**, **amr_core**. 21 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 95 | 85% |  |
| utilities | timer | 63 | 68% |  |
| cooling | rt_cooling | 530 | 68% |  |
| amr_core | output | 141 | 67% |  |
| hydrodynamics | output | 74 | 60% |  |
| utilities | file | 16 | 53% |  |
| mesh | memory_management | 182 | 47% |  |
| rt | output | 53 | 40% |  |
| mesh | setup | 172 | 39% |  |
| domains | hilbert_decomposition | 26 | 38% |  |
| amr_core | main_loop | 145 | 34% |  |
| amr_core | setup | 120 | 29% |  |
| utilities | communication | 169 | 29% |  |
| hydrodynamics | courant | 88 | 28% |  |
| utilities | dump_helpers | 10 | 25% |  |
| rt | rt | 170 | 22% | 21 |

18 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
