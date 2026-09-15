# ana-disk-potential

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 44 areas; most of its lines fall in **mesh**, **cooling**, **amr_core**. 61 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 95 | 85% |  |
| gravity | output | 38 | 78% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| gravity | setup | 87 | 68% | 7 |
| amr_core | output | 141 | 67% |  |
| mesh | setup | 278 | 63% |  |
| mesh | memory_management | 231 | 59% |  |
| hydrodynamics | output | 68 | 55% |  |
| cooling | regular_cooling | 647 | 54% |  |
| utilities | communication | 309 | 54% |  |
| utilities | file | 16 | 53% |  |
| mesh | refinement | 361 | 52% |  |
| hydrodynamics | source_terms | 107 | 50% |  |
| gravity | force_calculation | 66 | 50% | 18 |
| amr_core | main_loop | 193 | 45% |  |
| domains | hilbert_decomposition | 26 | 38% |  |
| hydrodynamics | update_driver | 66 | 36% |  |

24 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
