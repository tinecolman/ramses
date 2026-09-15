# driving-static

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 43 areas; most of its lines fall in **mesh**, **amr_core**, **hydrodynamics**, and no line is reached by this test alone.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| turb | driving | 50 | 100% |  |
| turb | turb_io | 24 | 100% |  |
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| mesh | output | 97 | 87% |  |
| turb | force_field | 158 | 77% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| amr_core | output | 140 | 66% |  |
| mesh | setup | 281 | 63% |  |
| hydrodynamics | output | 69 | 56% |  |
| mesh | refinement | 372 | 54% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| mesh | memory_management | 194 | 50% |  |
| amr_core | main_loop | 195 | 46% |  |
| domains | hilbert_decomposition | 30 | 44% |  |
| turb | setup | 94 | 44% |  |
| hydrodynamics | source_terms | 85 | 40% |  |
| hydrodynamics | update_driver | 68 | 38% |  |

23 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
