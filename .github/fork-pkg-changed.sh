#!/usr/bin/env bash
# Fork-only, used by the fork-*.yml workflows; kres does not generate it and
# the upstream contribution must not carry it.
#
# Usage: fork-pkg-changed.sh VAR_REGEX PATH...
#
# Writes build=true to $GITHUB_OUTPUT when a push changed any PATH, or a
# Pkgfile line defining a variable whose name starts with VAR_REGEX, and
# build=false otherwise. Anything but a push, and a push whose previous
# commit is unknown, builds.

set -euo pipefail

vars=$1
shift

build() {
  echo "build=$1" >>"${GITHUB_OUTPUT}"
  [ "$1" = true ] || echo "::notice::$2"
}

if [ "${GITHUB_EVENT_NAME}" != push ]; then
  build true
  exit 0
fi

if ! git cat-file -e "${BEFORE:-0000000000000000000000000000000000000000}^{commit}" 2>/dev/null; then
  build true
  exit 0
fi

if [ -n "$(git diff --name-only "${BEFORE}" "${GITHUB_SHA}" -- "$@")" ]; then
  build true
  exit 0
fi

if git diff -U0 "${BEFORE}" "${GITHUB_SHA}" -- Pkgfile | grep -qE "^[-+][[:space:]]*(${vars})"; then
  build true
  exit 0
fi

build false "no change to $* or to Pkgfile variables matching ${vars}; nothing to build"
