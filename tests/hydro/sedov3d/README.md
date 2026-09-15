* Test name: `sedov3d`
* Dimension: `3`
* Solver: `hydro`
* Comparison: md5sum of the amr2map denisty map of output_00046
* Purpose: Testing the 3D hydro implementation and the geometry refine
* Keywords: Hydro, geometrical refinement

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 37 areas; most of its lines fall in **mesh**, **amr_core**, **utilities**. 15 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 97 | 87% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| mesh | setup | 289 | 65% |  |
| mesh | refinement | 447 | 65% |  |
| amr_core | output | 135 | 64% |  |
| mesh | flagging | 224 | 61% |  |
| hydrodynamics | output | 69 | 56% |  |
| amr_core | main_loop | 231 | 54% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| mesh | memory_management | 194 | 50% |  |
| mesh | neighbour_search | 92 | 48% |  |
| domains | hilbert_decomposition | 30 | 44% |  |
| hydrodynamics | setup | 134 | 34% |  |
| amr_core | setup | 128 | 31% |  |
| hydro_amr | flagging | 89 | 31% |  |
| hydrodynamics | courant | 88 | 28% |  |

17 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
