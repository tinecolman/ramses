# sedov

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 44 areas; most of its lines fall in **mesh**, **particles**, **amr_core**. 439 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| utilities | units | 10 | 100% |  |
| tracers | pm | 109 | 99% | 109 |
| tracers | update | 175 | 99% | 175 |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 95 | 85% |  |
| particles | output | 92 | 75% | 8 |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| utilities | rng | 87 | 68% |  |
| amr_core | output | 143 | 67% |  |
| mesh | setup | 289 | 65% |  |
| mesh | refinement | 449 | 65% | 4 |
| mesh | memory_management | 242 | 62% |  |
| particles | particle_tree | 398 | 61% | 20 |
| mesh | neighbour_search | 114 | 59% | 1 |
| hydrodynamics | output | 68 | 55% |  |
| amr_core | main_loop | 235 | 55% | 7 |
| mesh | flagging | 200 | 55% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |

24 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
