#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
assert_output() {
  local file="$1" expected="$2"
  if ! grep -Fq "$expected" "$file"; then
    echo "Expected output not found: $expected" >&2
    cat "$file" >&2
    exit 1
  fi
}
if VAMPIRE_EDITION=invalid bash "$ROOT/scripts/test-installed-disk.sh" >"$TMP/edition.out" 2>&1; then
  echo "installed-disk harness accepted an unsupported edition" >&2
  exit 1
fi
assert_output "$TMP/edition.out" 'unsupported edition'
if VAMPIRE_INSTALLED_BOOT_TIMEOUT=0 bash "$ROOT/scripts/test-installed-disk.sh" >"$TMP/timeout.out" 2>&1; then
  echo "installed-disk harness accepted a zero timeout" >&2
  exit 1
fi
assert_output "$TMP/timeout.out" 'positive integer'
if VAMPIRE_INSTALLED_BOOT_TIMEOUT=00 bash "$ROOT/scripts/test-installed-disk.sh" >"$TMP/timeout-zero-padded.out" 2>&1; then
  echo "installed-disk harness accepted a zero-padded zero timeout" >&2
  exit 1
fi
assert_output "$TMP/timeout-zero-padded.out" 'between 1 and 86400'
if VAMPIRE_INSTALLED_BOOT_TIMEOUT=abc bash "$ROOT/scripts/test-installed-disk.sh" >"$TMP/timeout-text.out" 2>&1; then
  echo "installed-disk harness accepted a nonnumeric timeout" >&2
  exit 1
fi
assert_output "$TMP/timeout-text.out" 'positive integer'
if VAMPIRE_INSTALL_TEST_DIR="$ROOT" bash "$ROOT/scripts/test-installed-disk.sh" >"$TMP/workdir.out" 2>&1; then
  echo "installed-disk harness accepted repository root as work directory" >&2
  exit 1
fi
assert_output "$TMP/workdir.out" 'unsafe test directory'
ln -s "$TMP" "$TMP/workdir-link"
if VAMPIRE_INSTALL_TEST_DIR="$TMP/workdir-link" bash "$ROOT/scripts/test-installed-disk.sh" >"$TMP/symlink.out" 2>&1; then
  echo "installed-disk harness accepted a symlinked work directory" >&2
  exit 1
fi
assert_output "$TMP/symlink.out" 'symlinked test path component'
mkdir -p "$TMP/real-parent"
ln -s "$TMP/real-parent" "$TMP/parent-link"
if VAMPIRE_INSTALL_TEST_DIR="$TMP/parent-link/nested/work" bash "$ROOT/scripts/test-installed-disk.sh" >"$TMP/ancestor.out" 2>&1; then
  echo "installed-disk harness accepted a symlinked ancestor directory" >&2
  exit 1
fi
assert_output "$TMP/ancestor.out" 'symlinked test path component'
[[ ! -e "$TMP/real-parent/nested" ]] || { echo "created files through symlinked ancestor" >&2; exit 1; }
echo "installed-disk harness argument and path-safety tests: PASS"
