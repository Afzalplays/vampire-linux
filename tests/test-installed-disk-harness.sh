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
echo "installed-disk harness argument tests: PASS"
