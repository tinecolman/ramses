# barotrop

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 45 areas; most of its lines fall in **mesh**, **gravity**, **amr_core**, and no line is reached by this test alone.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| gravity | interpolation | 48 | 91% |  |
| mesh | output | 93 | 83% |  |
| gravity | multigrid | 901 | 81% |  |
| gravity | force_calculation | 107 | 80% |  |
| gravity | output | 38 | 78% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| amr_core | output | 138 | 65% |  |
| mesh | refinement | 446 | 65% |  |
| amr_core | main_loop | 253 | 59% |  |
| mesh | memory_management | 231 | 59% |  |
| mesh | neighbour_search | 113 | 59% |  |
| hydrodynamics | output | 67 | 54% |  |
| utilities | communication | 309 | 54% |  |
| utilities | file | 16 | 53% |  |
| mesh | flagging | 171 | 47% |  |
| mesh | setup | 165 | 37% |  |
| hydro_amr | flagging | 99 | 35% |  |

25 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
