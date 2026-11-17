#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
if VAMPIRE_EDITION=invalid bash "$ROOT/scripts/test-installed-disk.sh" >"$TMP/edition.out" 2>&1; then
  echo "installed-disk harness accepted an unsupported edition" >&2
  exit 1
fi
grep -q 'unsupported edition' "$TMP/edition.out"
if VAMPIRE_INSTALLED_BOOT_TIMEOUT=0 bash "$ROOT/scripts/test-installed-disk.sh" >"$TMP/timeout.out" 2>&1; then
  echo "installed-disk harness accepted a zero timeout" >&2
  exit 1
fi
grep -q 'positive integer' "$TMP/timeout.out"
if VAMPIRE_INSTALLED_BOOT_TIMEOUT=abc bash "$ROOT/scripts/test-installed-disk.sh" >"$TMP/timeout-text.out" 2>&1; then
  echo "installed-disk harness accepted a nonnumeric timeout" >&2
  exit 1
fi
grep -q 'positive integer' "$TMP/timeout-text.out"
if VAMPIRE_INSTALL_TEST_DIR="$ROOT" bash "$ROOT/scripts/test-installed-disk.sh" >"$TMP/workdir.out" 2>&1; then
  echo "installed-disk harness accepted repository root as work directory" >&2
  exit 1
fi
grep -q 'unsafe test directory' "$TMP/workdir.out"
ln -s "$TMP" "$TMP/workdir-link"
if VAMPIRE_INSTALL_TEST_DIR="$TMP/workdir-link" bash "$ROOT/scripts/test-installed-disk.sh" >"$TMP/symlink.out" 2>&1; then
  echo "installed-disk harness accepted a symlinked work directory" >&2
  exit 1
fi
grep -q 'symlinked test path component' "$TMP/symlink.out"
mkdir -p "$TMP/real-parent"
ln -s "$TMP/real-parent" "$TMP/parent-link"
if VAMPIRE_INSTALL_TEST_DIR="$TMP/parent-link/nested/work" bash "$ROOT/scripts/test-installed-disk.sh" >"$TMP/ancestor.out" 2>&1; then
  echo "installed-disk harness accepted a symlinked ancestor directory" >&2
  exit 1
fi
grep -q 'symlinked test path component' "$TMP/ancestor.out"
[[ ! -e "$TMP/real-parent/nested" ]] || { echo "created files through symlinked ancestor" >&2; exit 1; }
echo "installed-disk harness argument and path-safety tests: PASS"
