"""
Helpers shared by the incremental coverage tools: coverage_select.py,
coverage_merge.py and coverage_diff.py.

A coverage directory (made by run_test_suite.sh -s or by coverage_merge.py)
holds, besides the report, the two sidecars the tools rely on:
  coverage_tests.json   {source: {line: [tests that executed the line]}}
  coverage_built.json   {source: [tests whose build compiled the source]}
Source paths are the ones gcov prints, relative to bin/ ("../amr/x.f90").
Tests are labelled <family>_<test> (older directories: just <test>); the
tools normalise both spellings to the test's directory, "family/test".
"""
import json
import os
import re
import subprocess
import sys
from glob import glob

from multi_gcov_aggregator import (build_records, continuation_heads,
                                   is_declaration, strip_comment)

TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_DIR = os.path.normpath(os.path.join(TESTS_DIR, ".."))
BIN_DIR = os.path.join(REPO_DIR, "bin")
# The directories bin/Makefile takes sources from
SOURCE_DIRS = ("amr", "aton", "hydro", "io", "mhd", "pm", "poisson", "rhd",
               "rt", "turb")
SOURCE_EXT = (".f90", ".F90", ".F", ".f")
# Files of tests/ that change how every test is built or run
RUNNER_FILES = ("tests/run_test_suite.sh", "tests/run_with_restart.py",
                "tests/multi_gcov_aggregator.py", "tests/gcov_preprocessor.py")


# --------------------------------------------------------------------- tests
def list_tests(tests_dir=TESTS_DIR):
    """Every test of the suite as "family/test", from the config.txt files."""
    return sorted(os.path.relpath(os.path.dirname(c), tests_dir)
                  for c in glob(os.path.join(tests_dir, "*", "*", "config.txt")))


def test_to_label(test):
    return test.replace("/", "_")


def label_to_test(label, tests):
    """
    "hydro_sedov3d" -> "hydro/sedov3d"; the bare "sedov3d" of older coverage
    directories resolves when exactly one test has that name. A label that
    is already "family/test" is returned as is. None when unknown.
    """
    if label in tests:
        return label
    for t in tests:
        if test_to_label(t) == label:
            return t
    found = [t for t in tests if os.path.basename(t) == label]
    return found[0] if len(found) == 1 else None


def family_of(test):
    return test.split("/")[0]


def source_path(path):
    """
    Repository path "amr/x.f90" -> gcov path "../amr/x.f90", or None when the
    path is not a source file of the code.
    """
    parts = path.split("/")
    if len(parts) == 2 and parts[0] in SOURCE_DIRS and path.endswith(SOURCE_EXT):
        return "../" + path
    return None


def repo_path(source):
    """gcov path "../amr/x.f90" -> repository path "amr/x.f90"."""
    return os.path.normpath(os.path.join("bin", source))


# ----------------------------------------------------------------------- git
def git(args, repo=REPO_DIR, check=True):
    r = subprocess.run(["git", "-C", repo] + list(args), capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"git {' '.join(args)} failed:\n{r.stderr.strip()}")
    return r.stdout


def git_lines(rev, path, repo=REPO_DIR):
    """The lines of `path` at `rev`, from the working tree when rev is
    WORKTREE, None when the file does not exist there."""
    if rev == "WORKTREE":
        full = os.path.join(repo, path)
        if not os.path.exists(full):
            return None
        with open(full, errors="replace") as f:
            return f.read().split("\n")
    r = subprocess.run(["git", "-C", repo, "show", f"{rev}:{path}"],
                       capture_output=True, text=True, errors="replace")
    return r.stdout.split("\n") if r.returncode == 0 else None


def resolve_rev(rev, repo=REPO_DIR):
    return "WORKTREE" if rev == "WORKTREE" else git(["rev-parse", rev], repo).strip()


def name_status(base, head, repo=REPO_DIR):
    """[(status, old path, new path)] of `git diff -M --name-status`."""
    args = ["diff", "-M", "--name-status", base] + ([] if head == "WORKTREE" else [head])
    out = []
    for line in git(args, repo).splitlines():
        parts = line.split("\t")
        status = parts[0][0]
        if status == "R":
            out.append(("R", parts[1], parts[2]))
        else:
            out.append((status, parts[1], parts[1]))
    return out


# --------------------------------------------------------- cosmetic changes
def statement_sequence(lines):
    """
    The statements of a source file that can influence what executes, each
    as one whitespace-free lower-case string, in order, with the line number
    of the statement's first line. Comments, blank lines and declarations
    without an initial value are left out, so two versions of a file with the
    same sequence differ only cosmetically: no test can cover them
    differently. Preprocessor lines are kept, they gate compilation.
    """
    heads = continuation_heads(lines)
    text, order = {}, []
    for number, raw in enumerate(lines, 1):
        s = raw.strip()
        if not s or s[0] == "!":
            continue
        if s[0] == "#":
            order.append(number)
            text[number] = re.sub(r"\s+", "", s.lower())
            continue
        body = strip_comment(s).strip()
        if not body:
            continue
        head = heads.get(number, number)
        if head not in text:
            order.append(head)
            text[head] = ""
        text[head] += body.rstrip("&").strip() + " "
    seq = []
    for head in order:
        t = text[head].strip()
        if t.startswith("#"):
            seq.append((head, t))
            continue
        if is_declaration(t) and not t.lower().startswith("data"):
            # an initial value or a parameter can change what runs
            if "=" not in re.sub(r"\b(kind|len)\s*=", "", t, flags=re.I):
                continue
        seq.append((head, re.sub(r"\s+", "", t).lower()))
    return seq


def is_cosmetic(old_lines, new_lines):
    """Whether two versions of a file hold the same executable statements."""
    return ([s for _, s in statement_sequence(old_lines)] ==
            [s for _, s in statement_sequence(new_lines)])


def statement_line_map(old_lines, new_lines):
    """
    {old line: new line} for the first line of every statement, when the two
    versions are cosmetically equal (checked first, None otherwise).
    """
    old = statement_sequence(old_lines)
    new = statement_sequence(new_lines)
    if [s for _, s in old] != [s for _, s in new]:
        return None
    return {o: n for (o, _), (n, _) in zip(old, new)}


ROUTINE_START = re.compile(
    r"^\s*(?:(?:recursive|pure|elemental|impure|module)\s+)*"
    r"(?:(?:integer|real|double\s*precision|logical|character|complex|type)\s*(?:\([^)]*\))?\s*"
    r"(?:(?:recursive|pure|elemental|impure)\s+)*)?"
    r"(subroutine|function|program)\s+(\w+)", re.I)
ROUTINE_END = re.compile(r"^\s*end\s*(subroutine|function|program)?\b\s*(\w+)?\s*$", re.I)


def routines(lines):
    """
    [(first line, last line, name)] of the procedures of a source file,
    innermost first for internal procedures. `end` without a keyword closes
    the innermost open procedure only when it is not an end of block.
    """
    out, stack = [], []
    for number, raw in enumerate(lines, 1):
        text = strip_comment(raw).strip()
        if not text or text.startswith("#"):
            continue
        m = ROUTINE_START.match(text)
        if m and "::" not in text.split("(")[0]:
            stack.append((number, m.group(2)))
            continue
        m = ROUTINE_END.match(text)
        if m and stack and (m.group(1) or not m.group(2)):
            start, name = stack.pop()
            out.append((start, number, name))
    return out


def enclosing_routines(lines, numbers):
    """The routines of `lines` that contain any of the line numbers."""
    found, rest = [], set(numbers)
    for start, end, name in routines(lines):
        hit = {n for n in rest if start <= n <= end}
        if hit:
            found.append((start, end, name))
            rest -= hit
    return found, rest


def diff_hunks(base, head, path, repo=REPO_DIR):
    """[(old start, old count, new start, new count)] of git diff -U0."""
    args = ["diff", "-U0", base] + ([] if head == "WORKTREE" else [head]) + ["--", path]
    out = []
    for line in git(args, repo).splitlines():
        m = re.match(r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@", line)
        if m:
            out.append((int(m.group(1)), int(m.group(2)) if m.group(2) is not None else 1,
                        int(m.group(3)), int(m.group(4)) if m.group(4) is not None else 1))
    return out


def old_lines_touched(hunks):
    """
    The lines of the old file a diff touches: the deleted or replaced
    lines, and for a pure insertion the two lines it sits between.
    """
    touched = set()
    for old_start, old_count, _new_start, _new_count in hunks:
        if old_count:
            touched.update(range(old_start, old_start + old_count))
        else:
            touched.update({old_start, old_start + 1})
    return touched


def text_line_map(old_lines, new_lines):
    """{old line: new line} for the lines difflib matches between two versions."""
    import difflib
    a = [l.rstrip() for l in old_lines]
    b = [l.rstrip() for l in new_lines]
    out = {}
    for i, j, n in difflib.SequenceMatcher(None, a, b, autojunk=False).get_matching_blocks():
        for k in range(n):
            out[i + k + 1] = j + k + 1
    return out


def makefile_is_object_lists_only(old_lines, new_lines):
    """
    Whether two versions of bin/Makefile differ only in the object lists
    (`XOBJ = a.o b.o \\` and their continuation lines), i.e. in which files
    are compiled rather than how.
    """
    def rest(lines):
        kept, in_list = [], False
        for raw in lines:
            line = raw.rstrip()
            if not in_list and re.match(r"^\s*\w*OBJ\w*\s*\+?=", line):
                in_list = True
            if in_list:
                in_list = line.endswith("\\")
                continue
            kept.append(line)
        return kept
    return rest(old_lines) == rest(new_lines)


# ------------------------------------------------------------ coverage dirs
def read_metadata(path):
    """The `key : value` lines of a coverage_metadata.txt, as a dict."""
    out = {}
    if not os.path.exists(path):
        return out
    for line in open(path, errors="replace"):
        m = re.match(r"^(\w+)\s*:\s*(.*)$", line)
        if m and not line.startswith(" "):
            out[m.group(1)] = m.group(2).strip()
    return out


def parse_report(path):
    """
    {source: (covered, total, not built)} of a coverage_report.txt, and the
    TOTAL row as a tuple. Not-built is 0 when the column is blank.
    """
    files, total = {}, None
    for line in open(path, errors="replace"):
        m = re.match(r"^(\S+)\s+([\d.]+)%\s+(\d+)/(\d+)\s*(\d*)\s*$", line)
        if not m:
            continue
        row = (int(m.group(3)), int(m.group(4)), int(m.group(5) or 0))
        if m.group(1) == "TOTAL":
            total = row
        else:
            files[m.group(1)] = row
    return files, total


def parse_aggregated_gcov(path):
    """
    (source, {line: (count, content)}) of a gcov_files/*_aggregated.gcov.
    count is an int, 0 for "#####", "-----" for never compiled, "-" for not
    executable.
    """
    source, lines = None, {}
    with open(path, errors="replace") as f:
        for raw in f:
            if raw.startswith("Source:"):
                source = raw[len("Source:"):].strip()
                continue
            m = re.match(r"^\s*(\S+):\s*(\d+): (.*)$", raw.rstrip("\n"))
            if not m:
                continue
            count = m.group(1)
            if count == "#####":
                count = 0
            elif count not in ("-", "-----"):
                count = int(count)
            lines[int(m.group(2))] = (count, m.group(3))
    return source, lines


class Baseline:
    """A coverage directory, read for merging or selecting."""

    def __init__(self, directory, tests=None):
        self.dir = directory
        self.tests = tests if tests is not None else list_tests()
        self.metadata = read_metadata(os.path.join(directory, "coverage_metadata.txt"))
        self.commit = self.metadata.get("commit", "")
        self.report, self.total = parse_report(os.path.join(directory, "coverage_report.txt"))
        self.covered_by = self._load_json("coverage_tests.json", per_line=True)
        self.unknown_labels = set()
        self.built_by = self._load_json("coverage_built.json", per_line=False)
        if self.built_by is None:
            self.built_by = self._built_from_gcov_per_test()

    def _load_json(self, name, per_line):
        path = os.path.join(self.dir, name)
        if not os.path.exists(path):
            return None
        data = json.load(open(path))
        out = {}
        for source, value in data.items():
            if per_line:
                out[source] = {int(n): self._tests_of(labels) for n, labels in value.items()}
            else:
                out[source] = self._tests_of(value)
        return out

    def _tests_of(self, labels):
        names = []
        for label in labels:
            t = label_to_test(label, self.tests)
            if t is None:
                self.unknown_labels.add(label)
                t = label
            names.append(t)
        return sorted(set(names))

    def _built_from_gcov_per_test(self):
        """
        Directories made before coverage_built.json existed: which tests
        compiled a file is read off the .gcov files they left, when
        gcov_per_test/ is still there. None when it is not.
        """
        root = os.path.join(self.dir, "gcov_per_test")
        if not os.path.isdir(root):
            return None
        out = {}
        for path in glob(os.path.join(root, "*", "**", "*.gcov"), recursive=True):
            label = os.path.relpath(path, root).split(os.sep)[0]
            source = None
            with open(path, errors="replace") as f:
                for line in f:
                    if line.startswith("        -:    0:Source:"):
                        source = line.split("Source:")[1].strip()
                    break
            if source:
                out.setdefault(source, set()).add(label)
        return {s: self._tests_of(labels) for s, labels in out.items()}

    def tests_reaching(self, source):
        """Tests that executed at least one line of the source."""
        out = set()
        for names in (self.covered_by or {}).get(source, {}).values():
            out.update(names)
        return out

    def tests_compiling(self, source):
        """Tests whose build compiled the source (None when not recorded)."""
        if self.built_by is None:
            return None
        return set(self.built_by.get(source, []))

    def all_tests(self):
        """Every test that has coverage data in this directory."""
        out = set()
        for source in (self.covered_by or {}):
            out |= self.tests_reaching(source)
        for source in (self.built_by or {}):
            out |= self.tests_compiling(source)
        return out

    def gcov_files(self):
        """{source: {line: (count, content)}} of gcov_files/."""
        out = {}
        for path in sorted(glob(os.path.join(self.dir, "gcov_files", "*_aggregated.gcov"))):
            source, lines = parse_aggregated_gcov(path)
            if source:
                out[source] = lines
        return out

    def runtimes(self):
        """{test: seconds} from the build records, for the tests that have it."""
        out = {}
        path = os.path.join(self.dir, "build_records")
        if not os.path.isdir(path):
            return out
        for f in glob(os.path.join(path, "*.txt")):
            test = None
            for line in open(f, errors="replace"):
                m = re.match(r"^test\s*:\s*(\S+)", line)
                if m:
                    test = m.group(1)
                m = re.match(r"^\s+runtime_s\s*:\s*(\d+)", line)
                if m and test:
                    out[test] = max(out.get(test, 0), int(m.group(1)))
        return out

    def lines_of(self, source, test):
        """The lines of `source` the test executed in the baseline."""
        return {n for n, names in (self.covered_by or {}).get(source, {}).items() if test in names}

    def records(self):
        """The build records, from build_records/ or an old metadata file."""
        path = os.path.join(self.dir, "build_records")
        if not os.path.isdir(path):
            path = os.path.join(self.dir, "coverage_metadata.txt")
        return build_records(path)
