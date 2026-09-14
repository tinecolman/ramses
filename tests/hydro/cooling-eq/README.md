# cooling-eq

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 33 areas; most of its lines fall in **mesh**, **cooling**, **amr_core**. 41 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 95 | 85% |  |
| hydrodynamics | hydro_courant | 88 | 73% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| utilities | file | 20 | 67% |  |
| amr_core | output | 136 | 64% |  |
| mesh | setup | 277 | 63% |  |
| hydrodynamics | output | 68 | 55% |  |
| cooling | regular_cooling | 660 | 55% | 41 |
| mesh | memory_management | 181 | 46% |  |
| domains | hilbert_decomposition | 26 | 38% |  |
| amr_core | main_loop | 147 | 35% |  |
| utilities | communication | 169 | 29% |  |
| amr_core | setup | 119 | 29% |  |
| hydrodynamics | setup | 213 | 29% |  |
| utilities | dump_helpers | 10 | 25% |  |

15 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
