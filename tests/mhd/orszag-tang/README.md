# orszag-tang

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 30 areas; most of its lines fall in **refinement**, **amr_core**, **mhd_solver**. 241 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| amr_core | units | 10 | 100% |  |
| amr_core | shutdown | 51 | 75% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| hydrodynamics | output | 81 | 66% |  |
| refinement | grid_linked_list | 445 | 65% |  |
| amr_core | output | 227 | 63% |  |
| amr_core | main_loop | 456 | 58% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| amr_core | grid_setup | 123 | 49% |  |
| utilities | neighbour_search | 88 | 46% |  |
| hydrodynamics | mhd_core | 41 | 45% |  |
| mhd_solver | godunov_solver | 708 | 42% | 178 |
| refinement | interpolation | 406 | 40% | 33 |
| refinement | flagging | 295 | 40% |  |
| timestepping | timestep_mhd | 39 | 35% |  |
| hydrodynamics | setup | 215 | 29% |  |
| amr_core | dump_helpers | 10 | 25% |  |
| hydrodynamics | initial_conditions | 47 | 17% | 30 |

10 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
