# spawning

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 53 areas; most of its lines fall in **gravity**, **amr_core**, **refinement**. 233 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| turb | driving | 50 | 100% |  |
| turb | turb_io | 24 | 100% |  |
| amr_core | units | 10 | 100% |  |
| hydrodynamics | hydro_source_terms | 117 | 93% |  |
| turb | time_step_control | 12 | 92% |  |
| amr_core | shutdown | 61 | 90% |  |
| gravity | force_calculation | 112 | 84% |  |
| gravity | multigrid | 907 | 82% |  |
| gravity | output | 38 | 78% |  |
| turb | force_field | 157 | 77% |  |
| hydrodynamics | hydro_core | 68 | 76% |  |
| utilities | memory | 27 | 69% |  |
| amr_core | output | 250 | 69% |  |
| utilities | timer | 63 | 68% |  |
| particles | output | 84 | 68% |  |
| utilities | neighbour_search | 131 | 68% |  |
| refinement | grid_linked_list | 398 | 58% |  |
| hydrodynamics | output | 69 | 56% |  |
| utilities | communication | 309 | 54% |  |
| utilities | file | 16 | 53% |  |

33 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
