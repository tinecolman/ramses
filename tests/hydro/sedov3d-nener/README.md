* Test name: `sedov3d_nener`
* Dimension: `3`
* Solver: `hydro`
* Comparison: md5sum of the amr2map denisty map of output_00046
* Purpose: Testing the 3D hydro implementation of NENER
* Keywords: Hydro, Non-thermal energy

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 38 areas; most of its lines fall in **mesh**, **amr_core**, **utilities**. 84 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 97 | 87% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| mesh | refinement | 447 | 65% |  |
| amr_core | output | 135 | 64% |  |
| hydrodynamics | output | 78 | 63% |  |
| mesh | flagging | 224 | 61% |  |
| amr_core | main_loop | 231 | 54% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| mesh | memory_management | 194 | 50% |  |
| mesh | neighbour_search | 92 | 48% |  |
| domains | hilbert_decomposition | 30 | 44% |  |
| mesh | setup | 174 | 39% |  |
| hydro_amr | flagging | 99 | 35% |  |
| amr_core | setup | 128 | 31% |  |
| hydrodynamics | courant | 100 | 31% |  |
| hydro_solver | godunov_solver | 313 | 30% | 26 |

18 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
