* Test name: `rt-dirac`
* Dimension: `3`
* Solver: `mhd`
* Comparison: pressure, density, and ionization fractions. 2D maps and radial profiles of output_00002
* Purpose: Testing the RT implementation in 3D with MHD
* Keywords: RT, dirac

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 46 areas; most of its lines fall in **mesh**, **mhd_solver**, **hydrodynamics**. 92 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| rt | interpolation | 59 | 100% | 21 |
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 97 | 87% |  |
| cooling | rt_cooling | 593 | 76% |  |
| rt | transport | 235 | 73% | 17 |
| rt | output | 96 | 73% |  |
| hydrodynamics | output | 87 | 71% |  |
| utilities | memory | 27 | 69% |  |
| amr_core | main_loop | 294 | 69% |  |
| mesh | refinement | 472 | 69% | 12 |
| utilities | timer | 63 | 68% |  |
| mesh | setup | 303 | 68% |  |
| amr_core | output | 142 | 67% |  |
| hydrodynamics | mhd_interpolation | 424 | 65% |  |
| mhd_solver | godunov_solver | 1067 | 64% | 23 |
| utilities | communication | 340 | 59% |  |
| mesh | flagging | 202 | 55% |  |
| mesh | memory_management | 214 | 55% |  |
| utilities | file | 16 | 53% |  |

26 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
