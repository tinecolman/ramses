* Test name: `abc-flow`
* Dimension: `3`
* Solver: `mhd`
* Comparison: B^2/2 projection along y-axis of output_00002
* Purpose: Testing the MHD induction solver and MHD diffusion (cf. https://arxiv.org/pdf/astro-ph/0601715)
* Keywords: MHD, ABC-flow, dynamo

<!-- BEGIN feature-coverage -->
## Feature areas covered by this test

Reaches 33 areas; most of its lines fall in **amr_core**, **mhd_solver**, **hydrodynamics**. 13 lines are reached by no other test in the suite.

| feature | area | lines | share of area | only this test |
|---|---|---:|---:|---:|
| amr_core | units | 10 | 100% |  |
| timestepping | timestep_mhd | 83 | 75% |  |
| amr_core | shutdown | 51 | 75% |  |
| utilities | timer | 63 | 68% |  |
| utilities | memory | 26 | 67% |  |
| hydrodynamics | output | 81 | 66% |  |
| amr_core | output | 230 | 63% |  |
| refinement | grid_linked_list | 381 | 55% |  |
| utilities | file | 16 | 53% |  |
| utilities | communication | 303 | 53% |  |
| amr_core | main_loop | 414 | 53% |  |
| amr_core | grid_setup | 128 | 51% |  |
| hydrodynamics | mhd_core | 41 | 45% |  |
| domains | load_balancing | 527 | 44% |  |
| mhd_solver | godunov_solver | 717 | 43% |  |
| hydrodynamics | diffusion | 166 | 41% |  |
| hydrodynamics | velocity_profiles | 13 | 36% | 13 |
| utilities | neighbour_search | 66 | 34% |  |
| hydrodynamics | setup | 251 | 34% |  |
| utilities | sorting | 31 | 27% |  |

13 further areas exercised more lightly (under 10 lines or 25% of the area, and shared with other tests).

<sub>Generated from `coverage_features_overview_2026-09-10_7b6d29b8` by `doc/features_overview/annotate_test_readmes.py`. *share* is of the area's executable lines; *only* counts lines no other test reaches.</sub>

<!-- END feature-coverage -->
