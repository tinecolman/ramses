# SNFB

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 54 areas; most of its lines fall in **particles**, **mesh**, **gravity**. 366 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| particles | time_step | 19 | 100% |  |
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| hydrodynamics | hydro_source_terms | 115 | 91% |  |
| gravity | interpolation | 47 | 89% |  |
| mesh | output | 97 | 87% |  |
| gravity | force_calculation | 111 | 83% |  |
| gravity | multigrid | 904 | 81% |  |
| hydrodynamics | hydro_core | 71 | 80% |  |
| subgrid | feedback | 396 | 78% | 268 |
| gravity | output | 38 | 78% |  |
| particles | output | 94 | 76% |  |
| hydrodynamics | hydro_courant | 91 | 76% |  |
| amr_core | output | 154 | 73% |  |
| mesh | memory_management | 279 | 72% |  |
| utilities | timer | 63 | 68% |  |
| mesh | neighbour_search | 131 | 68% |  |
| mesh | refinement | 466 | 68% |  |
| particles | particle_tree | 433 | 67% |  |
| utilities | memory | 26 | 67% |  |

34 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
