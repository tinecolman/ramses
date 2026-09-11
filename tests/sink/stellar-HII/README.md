# stellar-HII

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 57 areas; most of its lines fall in **sinks**, **particles**, **gravity**. 570 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| sinks | sink_output | 18 | 100% |  |
| amr_core | units | 10 | 100% |  |
| sinks | hii_feedback | 114 | 97% | 114 |
| amr_core | shutdown | 61 | 90% |  |
| hydrodynamics | hydro_source_terms | 111 | 88% |  |
| rt | output | 111 | 84% | 15 |
| gravity | force_calculation | 108 | 81% |  |
| hydrodynamics | hydro_core | 70 | 79% |  |
| gravity | output | 38 | 78% |  |
| sinks | accretion | 399 | 74% | 3 |
| gravity | multigrid | 822 | 74% |  |
| particles | output | 91 | 74% |  |
| sinks | update | 243 | 72% |  |
| amr_core | output | 257 | 71% |  |
| utilities | timer | 63 | 68% |  |
| utilities | rng | 87 | 68% |  |
| rt | transport | 218 | 68% |  |
| refinement | grid_linked_list | 461 | 67% |  |
| utilities | memory | 26 | 67% |  |
| cooling | rt_cooling | 508 | 65% | 22 |

37 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
