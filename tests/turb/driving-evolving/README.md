# driving-evolving

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 43 areas; most of its lines fall in **mesh**, **hydrodynamics**, **amr_core**, and no line is reached by this test alone.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| turb | driving | 50 | 100% |  |
| turb | turb_io | 24 | 100% |  |
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| turb | time_step_control | 12 | 92% |  |
| mesh | output | 97 | 87% |  |
| hydrodynamics | hydro_courant | 92 | 77% |  |
| turb | force_field | 157 | 77% |  |
| hydrodynamics | hydro_core | 68 | 76% |  |
| utilities | memory | 27 | 69% |  |
| utilities | timer | 63 | 68% |  |
| hydrodynamics | hydro_source_terms | 85 | 67% |  |
| amr_core | output | 140 | 66% |  |
| mesh | setup | 281 | 63% |  |
| hydrodynamics | output | 69 | 56% |  |
| mesh | refinement | 372 | 54% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| turb | setup | 108 | 50% |  |
| mesh | memory_management | 194 | 50% |  |

23 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
