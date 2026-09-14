# center-SN

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 60 areas; most of its lines fall in **mesh**, **sinks**, **particles**. 187 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| particles | time_step | 19 | 100% |  |
| sinks | sink_output | 18 | 100% |  |
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| sinks | sn_feedback | 186 | 94% | 186 |
| gravity | interpolation | 48 | 91% |  |
| hydrodynamics | hydro_source_terms | 111 | 88% |  |
| mesh | output | 97 | 87% |  |
| gravity | force_calculation | 108 | 81% |  |
| gravity | output | 38 | 78% |  |
| hydrodynamics | hydro_core | 68 | 76% |  |
| hydrodynamics | hydro_courant | 91 | 76% |  |
| gravity | multigrid | 825 | 74% |  |
| particles | output | 91 | 74% |  |
| sinks | accretion | 396 | 74% |  |
| amr_core | output | 155 | 73% |  |
| sinks | update | 243 | 72% |  |
| mesh | memory_management | 279 | 72% |  |
| domains | load_balancing | 330 | 70% |  |
| utilities | memory | 27 | 69% |  |

40 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
