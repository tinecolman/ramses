# stellar-spawn

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 50 areas; most of its lines fall in **particles**, **sinks**, **gravity**. 1 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| sinks | sink_output | 18 | 100% |  |
| amr_core | units | 10 | 100% |  |
| amr_core | shutdown | 61 | 90% |  |
| hydrodynamics | hydro_source_terms | 111 | 88% |  |
| gravity | force_calculation | 108 | 81% |  |
| gravity | output | 38 | 78% |  |
| hydrodynamics | hydro_core | 67 | 75% |  |
| particles | output | 91 | 74% |  |
| sinks | accretion | 395 | 74% |  |
| gravity | multigrid | 796 | 72% |  |
| utilities | memory | 27 | 69% |  |
| amr_core | output | 250 | 69% |  |
| utilities | timer | 63 | 68% |  |
| utilities | rng | 87 | 68% |  |
| sinks | stellars | 105 | 62% | 1 |
| sinks | setup | 170 | 61% |  |
| utilities | file | 18 | 60% |  |
| sinks | update | 198 | 59% |  |
| particles | position_and_velocity_update | 311 | 57% |  |
| hydrodynamics | output | 69 | 56% |  |

30 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
