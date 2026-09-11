# cooling-neq

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 30 areas; most of its lines fall in **amr_core**, **cooling**, **hydrodynamics**, and no line is reached by this test alone.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| amr_core | units | 10 | 100% |  |
| amr_core | shutdown | 51 | 75% |  |
| cooling | rt_cooling | 572 | 73% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| utilities | file | 20 | 67% |  |
| amr_core | output | 234 | 64% |  |
| hydrodynamics | output | 74 | 60% |  |
| amr_core | main_loop | 397 | 50% |  |
| amr_core | grid_setup | 118 | 47% |  |
| rt | output | 53 | 40% |  |
| hydrodynamics | setup | 231 | 32% |  |
| utilities | communication | 169 | 29% |  |
| amr_core | dump_helpers | 10 | 25% |  |

16 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
