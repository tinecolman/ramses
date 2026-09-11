* Test name: `shadow2d`
* Dimension: `2`
* Solver: `hydro`
* Comparison: temperature and ionization maps of output_00002
* Purpose: Testing the RT implementation
* Keywords: RT, shadow

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 40 areas; most of its lines fall in **amr_core**, **rt**, **cooling**, and no line is reached by this test alone.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| domains | boundary_setup | 119 | 100% |  |
| amr_core | units | 10 | 100% |  |
| hydrodynamics | hydro_core | 68 | 76% |  |
| rt | boundaries | 47 | 76% |  |
| rt | transport | 243 | 76% |  |
| amr_core | shutdown | 51 | 75% |  |
| rt | output | 98 | 74% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| cooling | rt_cooling | 526 | 67% |  |
| amr_core | output | 239 | 66% |  |
| hydrodynamics | output | 76 | 62% |  |
| refinement | grid_linked_list | 419 | 61% |  |
| amr_core | main_loop | 458 | 58% |  |
| utilities | communication | 313 | 54% |  |
| utilities | file | 16 | 53% |  |
| amr_core | grid_setup | 129 | 52% |  |
| rt | rt | 377 | 49% |  |
| hydrodynamics | setup | 291 | 40% |  |
| hydrodynamics | hydro_source_terms | 50 | 40% |  |

20 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
