# sedov-classical-tracers

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 42 areas; most of its lines fall in **mesh**, **particles**, **hydrodynamics**. 74 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 95 | 85% |  |
| hydrodynamics | hydro_courant | 88 | 73% |  |
| utilities | memory | 27 | 69% |  |
| particles | output | 85 | 69% |  |
| utilities | timer | 63 | 68% |  |
| amr_core | output | 143 | 67% |  |
| mesh | setup | 289 | 65% |  |
| mesh | refinement | 445 | 65% |  |
| utilities | rng | 82 | 64% |  |
| mesh | memory_management | 242 | 62% |  |
| mesh | neighbour_search | 113 | 59% |  |
| particles | particle_tree | 378 | 58% |  |
| hydrodynamics | output | 68 | 55% |  |
| mesh | flagging | 200 | 55% |  |
| amr_core | main_loop | 228 | 54% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| utilities | dump_helpers | 20 | 50% |  |

22 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
