# center-SN

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 51 areas; most of its lines fall in **sinks**, **particles**, **gravity**. 187 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| sinks | sink_output | 18 | 100% |  |
| amr_core | units | 10 | 100% |  |
| sinks | sn_feedback | 186 | 94% | 186 |
| amr_core | shutdown | 61 | 90% |  |
| hydrodynamics | hydro_source_terms | 111 | 88% |  |
| gravity | force_calculation | 108 | 81% |  |
| gravity | output | 38 | 78% |  |
| hydrodynamics | hydro_core | 68 | 76% |  |
| gravity | multigrid | 825 | 74% |  |
| particles | output | 91 | 74% |  |
| sinks | accretion | 396 | 74% |  |
| sinks | update | 243 | 72% |  |
| utilities | memory | 27 | 69% |  |
| amr_core | output | 250 | 69% |  |
| utilities | timer | 63 | 68% |  |
| utilities | rng | 87 | 68% |  |
| refinement | grid_linked_list | 452 | 66% |  |
| sinks | stellars | 106 | 63% |  |
| sinks | setup | 172 | 62% |  |
| particles | position_and_velocity_update | 311 | 57% |  |

31 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
