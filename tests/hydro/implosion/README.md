# implosion

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 39 areas; most of its lines fall in **mesh**, **hydrodynamics**, **amr_core**, and no line is reached by this test alone.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| mesh | boundaries | 119 | 100% |  |
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 100 | 89% |  |
| mesh | refinement | 515 | 75% |  |
| hydrodynamics | hydro_courant | 88 | 73% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| mesh | setup | 286 | 65% |  |
| amr_core | output | 134 | 63% |  |
| hydrodynamics | output | 70 | 57% |  |
| hydrodynamics | hydro_interpolation | 135 | 55% |  |
| mesh | flagging | 200 | 55% |  |
| mesh | memory_management | 213 | 55% |  |
| utilities | communication | 313 | 54% |  |
| utilities | file | 16 | 53% |  |
| amr_core | main_loop | 219 | 51% |  |
| mesh | neighbour_search | 94 | 49% |  |
| hydrodynamics | hydro_core | 41 | 46% |  |
| domains | hilbert_decomposition | 26 | 38% |  |

19 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
