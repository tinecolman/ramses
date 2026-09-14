* Test name: `ponomarenko-dynamo`
* Dimension: `3`
* Solver: `mhd`
* Comparison: B^2/2 isosurface of output_00002
* Purpose: Testing the MHD induction solver and MHD diffusion (cf. https://arxiv.org/pdf/astro-ph/0601715)
* Keywords: MHD, Ponomarenko dynamo

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 40 areas; most of its lines fall in **hydrodynamics**, **mesh**, **mhd_solver**. 394 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| utilities | units | 10 | 100% |  |
| mesh | shutdown | 33 | 97% |  |
| hydrodynamics | diffusion | 392 | 96% | 226 |
| mesh | output | 97 | 87% |  |
| hydrodynamics | mhd_interpolation | 538 | 83% | 63 |
| hydrodynamics | mhd_courant | 151 | 76% | 2 |
| utilities | timer | 63 | 68% |  |
| utilities | memory | 26 | 67% |  |
| hydrodynamics | output | 81 | 66% |  |
| mesh | setup | 287 | 65% |  |
| domains | load_balancing | 303 | 64% |  |
| hydrodynamics | velocity_profiles | 23 | 64% | 23 |
| amr_core | output | 135 | 64% |  |
| mhd_solver | godunov_solver | 978 | 58% |  |
| mesh | refinement | 401 | 58% |  |
| amr_core | main_loop | 241 | 57% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| mesh | memory_management | 194 | 50% |  |
| mesh | flagging | 180 | 49% |  |

20 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
