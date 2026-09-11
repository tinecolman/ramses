# implosion

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 31 areas; most of its lines fall in **refinement**, **amr_core**, **utilities**, and no line is reached by this test alone.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| domains | boundary_setup | 119 | 100% |  |
| amr_core | units | 10 | 100% |  |
| amr_core | shutdown | 51 | 75% |  |
| refinement | grid_linked_list | 515 | 75% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| amr_core | output | 232 | 64% |  |
| amr_core | main_loop | 453 | 58% |  |
| hydrodynamics | output | 70 | 57% |  |
| utilities | communication | 313 | 54% |  |
| utilities | file | 16 | 53% |  |
| amr_core | grid_setup | 123 | 49% |  |
| utilities | neighbour_search | 94 | 49% |  |
| hydrodynamics | hydro_core | 41 | 46% |  |
| refinement | flagging | 293 | 40% |  |
| hydrodynamics | setup | 271 | 37% |  |
| amr_core | dump_helpers | 10 | 25% |  |

14 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
