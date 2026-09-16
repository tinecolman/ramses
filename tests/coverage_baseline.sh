#!/bin/bash
#
# Store and retrieve test-suite coverage baselines as assets of a rolling
# GitHub release (tag coverage-baseline by default). One light asset per
# commit, coverage-baseline-<sha>.tar.zst (the reports, coverage_tests.json,
# coverage_built.json, gcov_files/ and build_records/: everything
# coverage_merge.py needs), and for full runs also coverage-full-<sha>.tar.zst
# with the per-test gcov files, logs and PDFs.
#
# Usage:
#   coverage_baseline.sh publish <coverage dir> <sha> [full]
#   coverage_baseline.sh find <rev> [max commits]   -> "<sha> <lag>" of the newest
#                                                     first-parent ancestor with a baseline
#   coverage_baseline.sh fetch <sha> <dir>          -> unpack that baseline into <dir>
#   coverage_baseline.sh list
#   coverage_baseline.sh prune [keep light] [keep full]   (defaults 30 and 3)
#
# Environment: COVERAGE_REPO (owner/name, default: the repository gh resolves
# from the current directory), COVERAGE_RELEASE (tag, default coverage-baseline),
# GH_TOKEN for publishing from CI.

set -euo pipefail

TAG="${COVERAGE_RELEASE:-coverage-baseline}"
if [ -n "${COVERAGE_REPO:-}" ]; then
   REPO_OPT=(-R "${COVERAGE_REPO}")
else
   REPO_OPT=()
fi

usage() { sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

# names of the assets of the release, empty when the release does not exist
assets() {
   gh release view "${TAG}" "${REPO_OPT[@]}" --json assets -q '.assets[].name' 2>/dev/null || true
}

ensure_release() {
   if ! gh release view "${TAG}" "${REPO_OPT[@]}" > /dev/null 2>&1; then
      echo "Creating release ${TAG}";
      gh release create "${TAG}" "${REPO_OPT[@]}" --prerelease --latest=false \
         --title "Test-suite coverage baselines" \
         --notes "Rolling store of coverage baselines, one per commit of dev, written by the coverage workflows. Not a release of the code." \
         --target "${2:-HEAD}";
   fi
}

cmd_publish() {
   [ $# -ge 2 ] || usage;
   local dir="$1" sha="$2" kind="${3:-light}" tmp;
   [ -f "${dir}/coverage_report.txt" ] || { echo "${dir}: not a coverage directory" >&2; exit 1; }
   tmp=$(mktemp -d);
   local light="${tmp}/coverage-baseline-${sha}.tar.zst";
   tar -C "$(dirname "${dir}")" --exclude='gcov_per_test' --exclude='test_results*.pdf' \
       --exclude='test_suite*.log' --transform "s|^$(basename "${dir}")|coverage-baseline-${sha}|" \
       -cf - "$(basename "${dir}")" | zstd -q -o "${light}";
   ensure_release "${sha}";
   gh release upload "${TAG}" "${REPO_OPT[@]}" --clobber "${light}";
   echo "uploaded $(basename "${light}") ($(du -h "${light}" | cut -f1))";
   if [ "${kind}" = "full" ]; then
      local full="${tmp}/coverage-full-${sha}.tar.zst";
      tar -C "$(dirname "${dir}")" --transform "s|^$(basename "${dir}")|coverage-full-${sha}|" \
          -cf - "$(basename "${dir}")" | zstd -q -o "${full}";
      gh release upload "${TAG}" "${REPO_OPT[@]}" --clobber "${full}";
      echo "uploaded $(basename "${full}") ($(du -h "${full}" | cut -f1))";
   fi
   rm -rf "${tmp}";
}

cmd_find() {
   [ $# -ge 1 ] || usage;
   local rev="$1" max="${2:-500}" have lag=0 sha;
   have=$(assets);
   for sha in $(git rev-list --first-parent -n "${max}" "${rev}"); do
      if grep -qx "coverage-baseline-${sha}.tar.zst" <<< "${have}"; then
         echo "${sha} ${lag}";
         return 0;
      fi
      lag=$((lag + 1));
   done
   echo "no baseline among the last ${max} first-parent ancestors of ${rev}" >&2;
   return 1;
}

cmd_fetch() {
   [ $# -ge 2 ] || usage;
   local sha="$1" dir="$2" tmp;
   tmp=$(mktemp -d);
   gh release download "${TAG}" "${REPO_OPT[@]}" -p "coverage-baseline-${sha}.tar.zst" -D "${tmp}";
   mkdir -p "$(dirname "${dir}")";
   rm -rf "${dir}";
   mkdir -p "${tmp}/x";
   zstd -dq -c "${tmp}/coverage-baseline-${sha}.tar.zst" | tar -C "${tmp}/x" -xf -;
   mv "${tmp}/x/coverage-baseline-${sha}" "${dir}";
   rm -rf "${tmp}";
   echo "baseline ${sha:0:10} unpacked in ${dir}";
}

cmd_list() {
   gh release view "${TAG}" "${REPO_OPT[@]}" --json assets \
      -q '.assets[] | "\(.createdAt)  \(.size)  \(.name)"' 2>/dev/null | sort || echo "no release ${TAG}";
}

cmd_prune() {
   local keep_light="${1:-30}" keep_full="${2:-3}" kind keep name;
   for kind in baseline full; do
      keep=$([ "${kind}" = baseline ] && echo "${keep_light}" || echo "${keep_full}");
      gh release view "${TAG}" "${REPO_OPT[@]}" --json assets \
         -q ".assets[] | select(.name | startswith(\"coverage-${kind}-\")) | \"\(.createdAt) \(.name)\"" \
         | sort -r | tail -n +"$((keep + 1))" | cut -d' ' -f2 | while read -r name; do
            echo "deleting ${name}";
            gh release delete-asset "${TAG}" "${name}" "${REPO_OPT[@]}" -y;
         done
   done
}

[ $# -ge 1 ] || usage;
cmd="$1"; shift;
case "${cmd}" in
   publish) cmd_publish "$@";;
   find)    cmd_find "$@";;
   fetch)   cmd_fetch "$@";;
   list)    cmd_list "$@";;
   prune)   cmd_prune "$@";;
   *) usage;;
esac
