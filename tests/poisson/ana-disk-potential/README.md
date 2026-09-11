# ana-disk-potential

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 36 areas; most of its lines fall in **amr_core**, **cooling**, **refinement**. 61 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| amr_core | units | 10 | 100% |  |
| hydrodynamics | hydro_source_terms | 107 | 85% |  |
| gravity | output | 38 | 78% |  |
| amr_core | shutdown | 51 | 75% |  |
| hydrodynamics | hydro_core | 66 | 74% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| gravity | setup | 78 | 66% | 7 |
| amr_core | output | 234 | 64% |  |
| hydrodynamics | output | 68 | 55% |  |
| cooling | regular_cooling | 647 | 54% |  |
| utilities | communication | 309 | 54% |  |
| utilities | file | 16 | 53% |  |
| amr_core | main_loop | 418 | 53% |  |
| refinement | grid_linked_list | 361 | 52% |  |
| gravity | force_calculation | 66 | 50% | 18 |
| amr_core | grid_setup | 123 | 49% |  |
| utilities | neighbour_search | 62 | 32% |  |
| hydrodynamics | setup | 204 | 28% |  |
| domains | load_balancing | 310 | 26% |  |

16 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
