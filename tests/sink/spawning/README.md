# spawning

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 61 areas; most of its lines fall in **mesh**, **gravity**, **amr_core**. 233 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| turb | driving | 50 | 100% |  |
| turb | turb_io | 24 | 100% |  |
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| turb | time_step_control | 12 | 92% |  |
| gravity | interpolation | 47 | 89% |  |
| mesh | output | 97 | 87% |  |
| gravity | force_calculation | 112 | 84% |  |
| gravity | multigrid | 907 | 82% |  |
| gravity | output | 38 | 78% |  |
| turb | force_field | 157 | 77% |  |
| amr_core | output | 155 | 73% |  |
| mesh | memory_management | 279 | 72% |  |
| amr_core | main_loop | 297 | 70% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| particles | output | 84 | 68% |  |
| mesh | neighbour_search | 131 | 68% |  |
| mesh | refinement | 398 | 58% |  |
| hydrodynamics | output | 69 | 56% |  |

41 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
