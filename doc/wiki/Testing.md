
# Testing

## 1. Running the automatic test suite

To run the automatic tests, navigate to the [tests](https://github.com/ramses-organisation/ramses/tree/stable/tests) directory, and run the `run_test_suite.sh` script:
```
>$ cd tests
>$ ./run_test_suite.sh
```
The tests will begin and the output should look like:
```
############################################
#   Running RAMSES automatic test suite    #
############################################
Will perform the following tests:
 [ 1] hydro/implosion
 [ 2] hydro/sod-tube
 [ 3] mhd/imhd-tube
 [ 4] mhd/orszag-tang
 [ 5] rt/stromgren2d
 [ 6] sink/smbh-bondi
--------------------------------------------
Test 1/6: hydro/implosion
Cleanup
Compiling source
```
and so on.
Once the tests have completed, a report is generated in a `.pdf` file named `test_results.pdf`, alongside a log file `test_suite.log`.

### Options

- Run the suite in parallel (on 4 cpus):
```
./run_test_suite.sh -p 4
```

- Do not delete results data:
```
./run_test_suite.sh -d
```

- Run in verbose mode:
```
./run_test_suite.sh -v
```

- Select individual tests (for tests 3 to 5, and 10):
```
./run_test_suite.sh -t 3-5,10
```

- Run all tests in `mhd` directory:
```
./run_test_suite.sh -t mhd
```
- Select tests by name (can be mixed with directories):
```
./run_test_suite.sh -t hydro/sedov3d,sink/smbh-bondi,rt
```
- Run test suite with coverage (see section 4):
```
./run_test_suite.sh -s
```

- Run tests with restart:
```
./run_test_suite.sh -r
```
This will add an intermediate output in the middle of the test, and restart from it.

## 2. Creating a new test

The following steps describe how to add a new test to the test suite. In this example, the test will be named `sedov-3d`.

The first step is to create a new directory `sedov-3d` in one of the `hydro`, `mhd`, `rt`, or `sinks` directories. No need to modify the `run_test_suite.sh` script, the new test will automatically be picked up and added to the list. We will choose to place it inside the `hydro` directory. Please use hyphens (`-`) in your test names instead of underscores (`_`) as `latex` does not like underscores.

```
>$ cd hydro
>$ mkdir sedov-3d
```

**Note**: use one directory per test. If you want to run a 2D and a 3D sedov test, create separate `sedov-2d` and `sedov-3d` directories.

In that directory, you will need:

- A `config.txt` file: usually just contains the Makefile flags, e.g. `FLAGS: NDIM=3 PATCH= SOLVER=hydro`

- A namelist: `sedov-3d.nml` (the name needs to be the same as the test directory)

:::{warning}
For the restart system to work, there is some limitations on the output parameters you can use. They have to be on the form
```
&OUTPUT_PARAMS
noutput=1 ! should be 1
tout=0.620
/
```
or
```
&OUTPUT_PARAMS
noutput=1 ! should be 1
aout=1.355E-01
/
/
```
for cosmo runs or
```
&OUTPUT_PARAMS
foutput=1 ! should be 1
tend=0.05
/
```

:::


- A file for plotting and checking the solution against a reference: `plot-sedov-3d.py`. It is advised to copy a file from the other directories to see how to write this. **Note that this file needs to contain at least one call to `visu_ramses.check_solution(data["data"], 'sedov-3d')`**.

- A reference solution: `sedov-3d-ref.txt`. To create it, run your test and once the final output (number 2 in this case) has been created, do the following:
```
import visu_ramses
data = visu_ramses.load_snapshot(2)
visu_ramses.check_solution(data["data"], 'sedov-3d', overwrite=True)
```

- A `Readme.md` containing a short description of the test

Optional files:

- `condinit.f90`: you can have your own initial setup if it's not entirely definable in a namelist. **REMEMBER** to set the correct `PATCH` in the `config.txt` file! (e.g. `PATCH=../tests/hydro/sedov-3d`). An other option is to add a custom condinit routine option in the existing condinit.f90 file.

- `before-test.sh`: if this file is present in the test directory, it will be run before the test begins (useful for e.g. creating symbolic links to libraries...)

- `after-test.sh`: if this file is present in the test directory, it will be run after the test begins (useful for e.g. cleaning up symbolic links to libraries...)



### Tuning tolerances for solution verification

By default, relative differences between the sums of all the variables inside all leaf cells in the domain and the reference solution cannot exceed `3.0e-13`.
Sometimes, some variables are more volatile than others when running simulations on different numbers of CPUs, and this limit is too low, leading to false failed tests.
The `check_solution` method in the `visu/visu_ramses.py` module can be tuned to work for your test using the following options:

- `tolerance`: a dictionary listing the allowed relative difference between the sum over all leaf cells and reference value. The default is `{"all":3.0e-13}`. To make the check on `density` less restrictive, use for instance `tolerance={"density":1.0e-10}`.

- `threshold`: relative value below which a vector component is set to zero. Default is `2.0e-14`.

- `norm_min`: minimum value for the norm of a vector, to protect against null vectors. Default is `1.0e-30`.

- `min_variance`: if the data differs by less than this value from the average value, it is set to the average. Default is `1.0e-14`.


## 3. Creating a new group of tests

If your test does not fall under the categories already present in the `tests` directory (`hydro`, `mhd`, `rt`, `sinks`), you can create a new directory and put your tests in there. You will then have to edit the `run_test_suite.sh` file to ensure your new tests will be picked up.

Say you want to create 3 new tests, `sedov-1d`, `sedov-2d`, and `sedov-3d` inside a new `sedov` directory, you have to find the line describing the list of directories to be scanned at the top of the `run_test_suite.sh` file:

```
# List of directories to scan
testlist="hydro,mhd,rt,sink";
```
and add your new directory separated from the previous one by a comma, i.e.
```
# List of directories to scan
testlist="hydro,mhd,rt,sink,sedov";
```

## 4. Coverage of the test suite

With `-s`, the code is built with gcov instrumentation (`GCOV=1`, which also
sets `-O0`) and the lines each test executes are collected. The result goes to
`tests/coverage_<branch>_<date>_<commit>/`:

- `coverage_report.txt`: per source file, the executable lines that ran over
  all tests, and the lines no build of the run compiled at all (they sit
  behind a preprocessor directive no test enables; `coverage_notbuilt.txt`
  breaks them down by directive).
- `gcov_files/`: one aggregated gcov file per source, with every line's count.
- `coverage_tests.json` and `coverage_built.json`: which tests executed each
  line, and which tests' builds compiled each file.
- `gcov_per_test/` and `build_records/`: the raw data of each test and how it
  was built, so the report can be regenerated or added to.

A full run takes a few hours, so the coverage is not recomputed from scratch
for every change. Instead, a full run is kept as a **baseline** and a change is
measured by re-running only the tests it can affect:

```
cd tests
python3 coverage_select.py --baseline <baseline dir> --base <baseline commit> --head HEAD --summary
./run_test_suite.sh -s -p 2 -t <the tests it lists>
python3 coverage_merge.py --baseline <baseline dir> --runs coverage_<...> --out merged
python3 coverage_diff.py <baseline dir> merged --base <baseline commit> --head HEAD
```

`coverage_select.py` finds the routines the diff touches and, from the
baseline, the tests that executed lines of those routines. It then keeps the
fewest of them that still execute every such line, preferring tests with a
short run time (recorded in the baseline's `build_records/`). A file whose
executable statements did not change (comments, blank lines, formatting,
declarations without a value) selects nothing. A new file selects nothing by
itself, since it can only run through an existing file that now uses it, and
that file's tests are selected. A change to a test's directory selects that
test; a change to the compiler flags of `bin/Makefile` or to the runner
scripts selects every test.

`coverage_merge.py` builds a complete coverage directory for the new source:
changed files come from the new runs, unchanged files keep the baseline's lines
(covered when a baseline test that was not re-run reached them, or a re-run
test reached them now). A test that reached a changed file but was not re-run
keeps its coverage of the lines that still exist, matched by their text, and
is taken not to reach the added lines. The result is therefore an estimate:
tests not re-run are assumed to execute the same lines as before, and to skip
new ones. The merge notes this in its metadata, the report says so, and the
monthly full run measures the error. The merge refuses to mix runs made from
another version of the source. `coverage_diff.py` then reports, with `C`/`D`
the lines covered/executable in the baseline and `A`/`B` the lines newly
covered/added:

    coverage gain = (C+A)/(D+B) - C/D

together with the files whose numbers changed and the executable lines the
change added that no test executes.

### On GitHub

Three workflows automate this (`.github/workflows/coverage_*.yaml`):

- **Coverage (full)** runs every test with coverage, monthly or by hand, and
  publishes the result as an asset of the rolling release `coverage-baseline`
  (`tests/coverage_baseline.sh` wraps `gh` for this). It also reports how far
  the rolling baseline had drifted from the full run, and posts the number on
  the issue "Test-suite coverage tracking": subscribe to it to get the monthly
  number by mail, or put GitHub handles to mention in the repository variable
  `COVERAGE_NOTIFY` (Settings, Secrets and variables, Actions, Variables).
- **Coverage (dev)**, on every push to `dev`, re-runs the selected tests,
  merges them into the baseline of the previous commit and publishes the
  result as the baseline of the new commit.
- **Coverage (PR)** does the same for a pull request against the baseline of
  its base branch, and the completed-workflow hook posts the comparison as a
  comment on the PR.

The first baseline has to be made by running **Coverage (full)** by hand
(Actions tab, "Run workflow").
