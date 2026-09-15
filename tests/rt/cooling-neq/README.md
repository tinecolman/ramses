# cooling-neq

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 37 areas; most of its lines fall in **mesh**, **cooling**, **amr_core**, and no line is reached by this test alone.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 95 | 85% |  |
| cooling | rt_cooling | 572 | 73% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| utilities | file | 20 | 67% |  |
| amr_core | output | 141 | 67% |  |
| mesh | setup | 288 | 65% |  |
| hydrodynamics | output | 74 | 60% |  |
| mesh | memory_management | 182 | 47% |  |
| rt | output | 53 | 40% |  |
| domains | hilbert_decomposition | 26 | 38% |  |
| amr_core | main_loop | 161 | 38% |  |
| hydrodynamics | setup | 147 | 38% |  |
| amr_core | setup | 125 | 31% |  |
| utilities | communication | 169 | 29% |  |
| hydrodynamics | courant | 88 | 28% |  |
| utilities | dump_helpers | 10 | 25% |  |

18 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
