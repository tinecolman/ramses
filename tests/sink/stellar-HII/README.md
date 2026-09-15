# stellar-HII

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 69 areas; most of its lines fall in **mesh**, **particles**, **sinks**. 570 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| particles | time_step | 19 | 100% |  |
| sinks | sink_output | 18 | 100% |  |
| utilities | units | 10 | 100% |  |
| sinks | hii_feedback | 114 | 97% | 114 |
| mesh | shutdown | 33 | 97% |  |
| gravity | interpolation | 48 | 91% |  |
| mesh | output | 97 | 87% |  |
| rt | output | 111 | 84% | 15 |
| amr_core | main_loop | 351 | 82% | 4 |
| gravity | force_calculation | 108 | 81% |  |
| gravity | output | 38 | 78% |  |
| mesh | memory_management | 299 | 77% |  |
| amr_core | output | 162 | 76% |  |
| sinks | accretion | 399 | 74% | 3 |
| gravity | multigrid | 822 | 74% |  |
| particles | output | 91 | 74% |  |
| sinks | update | 243 | 72% |  |
| domains | load_balancing | 334 | 71% | 4 |
| amr_core | time_step | 59 | 69% |  |
| utilities | timer | 63 | 68% |  |

49 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
