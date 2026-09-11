# imhd-tube

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 33 areas; most of its lines fall in **refinement**, **mhd_solver**, **amr_core**. 305 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| domains | boundary_setup | 119 | 100% |  |
| amr_core | units | 10 | 100% |  |
| amr_core | shutdown | 51 | 75% |  |
| utilities | timer | 66 | 72% |  |
| mhd_solver | riemann_solvers | 447 | 71% | 297 |
| refinement | grid_linked_list | 479 | 70% |  |
| utilities | memory | 27 | 69% |  |
| hydrodynamics | output | 83 | 67% |  |
| amr_core | output | 229 | 63% |  |
| utilities | communication | 313 | 54% |  |
| utilities | file | 16 | 53% |  |
| amr_core | grid_setup | 119 | 48% |  |
| hydrodynamics | screen_diagnostics | 146 | 48% | 1 |
| utilities | neighbour_search | 90 | 47% |  |
| hydrodynamics | mhd_core | 41 | 45% |  |
| amr_core | main_loop | 334 | 42% |  |
| refinement | flagging | 303 | 41% |  |
| hydrodynamics | boundaries | 120 | 38% |  |
| timestepping | timestep_mhd | 39 | 35% |  |
| refinement | interpolation | 335 | 33% |  |

13 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
