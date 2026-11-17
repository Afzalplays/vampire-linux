#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
for value in invalid "../server" Desktop; do
  if VAMPIRE_EDITION="$value" bash "$ROOT/scripts/test-live-iso.sh" >"$TMP/edition.out" 2>&1; then
    echo "live ISO harness accepted invalid edition: $value" >&2
    exit 1
  fi
  grep -q 'unsupported edition' "$TMP/edition.out"
done
for value in 0 00 abc -1 86401; do
  if VAMPIRE_QEMU_TIMEOUT="$value" bash "$ROOT/scripts/test-live-iso.sh" >"$TMP/timeout.out" 2>&1; then
    echo "live ISO harness accepted invalid timeout: $value" >&2
    exit 1
  fi
  grep -q 'positive integer' "$TMP/timeout.out"
done
echo "live ISO harness argument tests: PASS"
