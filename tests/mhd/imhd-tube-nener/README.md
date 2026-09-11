# imhd-tube-nener

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 34 areas; most of its lines fall in **refinement**, **amr_core**, **hydrodynamics**. 67 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| domains | boundary_setup | 119 | 100% |  |
| amr_core | units | 10 | 100% |  |
| amr_core | shutdown | 51 | 75% |  |
| hydrodynamics | output | 92 | 75% |  |
| refinement | grid_linked_list | 479 | 70% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| amr_core | output | 229 | 63% |  |
| amr_core | main_loop | 453 | 58% |  |
| hydrodynamics | mhd_source_terms | 51 | 57% | 3 |
| utilities | communication | 313 | 54% |  |
| utilities | file | 16 | 53% |  |
| hydrodynamics | screen_diagnostics | 155 | 51% | 10 |
| amr_core | grid_setup | 126 | 51% |  |
| utilities | neighbour_search | 90 | 47% |  |
| hydrodynamics | mhd_core | 41 | 45% |  |
| hydrodynamics | setup | 312 | 43% |  |
| refinement | flagging | 308 | 42% | 5 |
| timestepping | timestep_mhd | 45 | 41% | 6 |
| hydrodynamics | boundaries | 120 | 38% |  |

14 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
