* Test name: `rt-dirac`
* Dimension: `3`
* Solver: `mhd`
* Comparison: pressure, density, and ionization fractions. 2D maps and radial profiles of output_00002
* Purpose: Testing the RT implementation in 3D with MHD
* Keywords: RT, dirac

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 37 areas; most of its lines fall in **refinement**, **mhd_solver**, **amr_core**. 92 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| amr_core | units | 10 | 100% |  |
| cooling | rt_cooling | 593 | 76% |  |
| amr_core | shutdown | 51 | 75% |  |
| rt | transport | 235 | 73% | 17 |
| rt | output | 96 | 73% |  |
| hydrodynamics | output | 87 | 71% |  |
| utilities | memory | 27 | 69% |  |
| amr_core | main_loop | 544 | 69% |  |
| refinement | grid_linked_list | 472 | 69% | 12 |
| utilities | timer | 63 | 68% |  |
| amr_core | output | 237 | 65% |  |
| mhd_solver | godunov_solver | 1067 | 64% | 23 |
| utilities | communication | 340 | 59% |  |
| utilities | file | 16 | 53% |  |
| amr_core | grid_setup | 132 | 53% |  |
| rt | rt | 370 | 48% | 5 |
| refinement | interpolation | 483 | 48% | 21 |
| utilities | neighbour_search | 92 | 48% |  |
| hydrodynamics | mhd_core | 44 | 48% | 3 |
| refinement | flagging | 313 | 43% | 5 |

17 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
