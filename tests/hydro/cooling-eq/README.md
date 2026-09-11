# cooling-eq

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 26 areas; most of its lines fall in **amr_core**, **cooling**, **hydrodynamics**. 41 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| amr_core | units | 10 | 100% |  |
| amr_core | shutdown | 51 | 75% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| utilities | file | 20 | 67% |  |
| amr_core | output | 229 | 63% |  |
| hydrodynamics | output | 68 | 55% |  |
| cooling | regular_cooling | 660 | 55% | 41 |
| amr_core | main_loop | 372 | 47% |  |
| amr_core | grid_setup | 114 | 46% |  |
| utilities | communication | 169 | 29% |  |
| hydrodynamics | setup | 213 | 29% |  |
| amr_core | dump_helpers | 10 | 25% |  |

13 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
