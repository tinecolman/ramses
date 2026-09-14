* Test name: `stromgren2d`
* Dimension: `2`
* Solver: `hydro`
* Comparison: density, pressure, ionization profiles and maps of output_00002
* Purpose: Testing the RT implementation
* Keywords: RT, Stromgren

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 48 areas; most of its lines fall in **mesh**, **hydrodynamics**, **rt**. 14 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| mesh | boundaries | 119 | 100% |  |
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 100 | 89% |  |
| hydrodynamics | hydro_core | 68 | 76% |  |
| rt | boundaries | 47 | 76% |  |
| rt | output | 98 | 74% |  |
| hydrodynamics | hydro_courant | 88 | 73% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| cooling | rt_cooling | 531 | 68% | 3 |
| mesh | setup | 297 | 67% |  |
| amr_core | output | 141 | 67% |  |
| rt | interpolation | 38 | 64% |  |
| hydrodynamics | output | 76 | 62% |  |
| mesh | refinement | 419 | 61% |  |
| mesh | memory_management | 235 | 60% |  |
| utilities | communication | 313 | 54% |  |
| utilities | file | 16 | 53% |  |
| amr_core | main_loop | 215 | 50% |  |

28 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
