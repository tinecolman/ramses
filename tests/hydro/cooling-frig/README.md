# cooling-frig

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 36 areas; most of its lines fall in **amr_core**, **utilities**, **refinement**. 80 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| turb | driving | 50 | 100% |  |
| turb | turb_io | 24 | 100% |  |
| amr_core | units | 10 | 100% |  |
| turb | time_step_control | 12 | 92% |  |
| turb | force_field | 157 | 77% |  |
| hydrodynamics | hydro_core | 68 | 76% |  |
| amr_core | shutdown | 51 | 75% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| hydrodynamics | hydro_source_terms | 85 | 67% |  |
| amr_core | output | 235 | 65% |  |
| hydrodynamics | output | 69 | 56% |  |
| refinement | grid_linked_list | 372 | 54% |  |
| utilities | file | 16 | 53% |  |
| amr_core | main_loop | 419 | 53% |  |
| utilities | communication | 303 | 53% |  |
| amr_core | grid_setup | 129 | 52% |  |
| turb | setup | 108 | 50% |  |
| utilities | neighbour_search | 66 | 34% |  |
| hydrodynamics | setup | 221 | 30% |  |

16 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
