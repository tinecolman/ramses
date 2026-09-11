# sedov

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 37 areas; most of its lines fall in **amr_core**, **refinement**, **particles**. 439 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| amr_core | units | 10 | 100% |  |
| tracers | pm | 109 | 99% | 109 |
| tracers | update | 175 | 99% | 175 |
| amr_core | shutdown | 61 | 90% |  |
| particles | output | 92 | 75% | 8 |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| utilities | rng | 87 | 68% |  |
| refinement | grid_linked_list | 449 | 65% | 4 |
| amr_core | output | 236 | 65% |  |
| particles | particle_tree | 398 | 61% | 20 |
| amr_core | main_loop | 471 | 60% | 7 |
| utilities | neighbour_search | 114 | 59% | 1 |
| hydrodynamics | output | 68 | 55% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| amr_core | dump_helpers | 20 | 50% |  |
| amr_core | grid_setup | 124 | 50% |  |
| hydrodynamics | hydro_core | 41 | 46% |  |
| particles | particle_types | 15 | 38% | 2 |

17 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
