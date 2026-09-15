# stellar-spawn

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 59 areas; most of its lines fall in **mesh**, **particles**, **gravity**. 1 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| particles | time_step | 19 | 100% |  |
| sinks | sink_output | 18 | 100% |  |
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| gravity | interpolation | 48 | 91% |  |
| mesh | output | 97 | 87% |  |
| gravity | force_calculation | 108 | 81% |  |
| gravity | output | 38 | 78% |  |
| particles | output | 91 | 74% |  |
| sinks | accretion | 395 | 74% |  |
| amr_core | output | 155 | 73% |  |
| gravity | multigrid | 796 | 72% |  |
| mesh | memory_management | 279 | 72% |  |
| domains | load_balancing | 328 | 69% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| amr_core | main_loop | 290 | 68% |  |
| utilities | rng | 87 | 68% |  |
| amr_core | time_step | 55 | 64% |  |
| sinks | stellars | 105 | 62% | 1 |

39 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
