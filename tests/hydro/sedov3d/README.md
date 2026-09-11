* Test name: `sedov3d`
* Dimension: `3`
* Solver: `hydro`
* Comparison: md5sum of the amr2map denisty map of output_00046
* Purpose: Testing the 3D hydro implementation and the geometry refine
* Keywords: Hydro, geometrical refinement

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 29 areas; most of its lines fall in **amr_core**, **refinement**, **utilities**. 15 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| amr_core | units | 10 | 100% |  |
| amr_core | shutdown | 51 | 75% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| refinement | grid_linked_list | 447 | 65% |  |
| amr_core | output | 230 | 63% |  |
| amr_core | main_loop | 466 | 59% |  |
| hydrodynamics | output | 69 | 56% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| amr_core | grid_setup | 130 | 52% |  |
| utilities | neighbour_search | 92 | 48% |  |
| hydrodynamics | hydro_core | 41 | 46% |  |
| refinement | flagging | 313 | 43% |  |
| hydrodynamics | setup | 229 | 31% |  |
| hydro_solver | godunov_solver | 282 | 27% | 1 |
| amr_core | dump_helpers | 10 | 25% |  |
| hydro_solver | slope_types | 18 | 14% | 6 |
| hydro_solver | riemann_solvers | 48 | 11% | 8 |

10 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
