# cosmo

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 38 areas; most of its lines fall in **particles**, **clumps**, **gravity**. 943 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| amr_core | units | 10 | 100% |  |
| amr_core | shutdown | 61 | 90% |  |
| clumps | clump_properties | 364 | 81% | 172 |
| gravity | force_calculation | 104 | 78% |  |
| gravity | output | 38 | 78% |  |
| clumps | clump_support | 48 | 77% | 48 |
| gravity | multigrid | 777 | 70% |  |
| utilities | memory | 27 | 69% |  |
| particles | output | 85 | 69% |  |
| utilities | timer | 63 | 68% |  |
| clumps | peak_finding | 791 | 67% | 643 |
| amr_core | output | 238 | 66% |  |
| gravity | setup | 71 | 60% |  |
| particles | particle_tree | 373 | 57% |  |
| utilities | neighbour_search | 105 | 55% |  |
| refinement | grid_linked_list | 372 | 54% |  |
| utilities | communication | 309 | 54% |  |
| utilities | file | 16 | 53% |  |
| particles | position_and_velocity_update | 289 | 53% |  |
| amr_core | grid_setup | 127 | 51% |  |

18 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
