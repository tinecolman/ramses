# cosmo

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 45 areas; most of its lines fall in **particles**, **clumps**, **mesh**. 943 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| particles | time_step | 19 | 100% |  |
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 97 | 87% |  |
| clumps | clump_properties | 364 | 81% | 172 |
| gravity | force_calculation | 104 | 78% |  |
| gravity | output | 38 | 78% |  |
| clumps | clump_support | 48 | 77% | 48 |
| gravity | multigrid | 777 | 70% |  |
| utilities | memory | 27 | 69% |  |
| particles | output | 85 | 69% |  |
| utilities | timer | 63 | 68% |  |
| clumps | peak_finding | 791 | 67% | 643 |
| amr_core | output | 143 | 67% |  |
| mesh | memory_management | 260 | 67% |  |
| gravity | setup | 80 | 62% |  |
| amr_core | expansion | 159 | 58% |  |
| mesh | setup | 258 | 58% |  |
| particles | particle_tree | 373 | 57% |  |
| mesh | neighbour_search | 105 | 55% |  |

25 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
