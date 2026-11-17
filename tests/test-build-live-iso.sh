#!/usr/bin/env bash
# Verify the live ISO builder rejects invalid edition values before touching output.
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
log="$WORK/build.log"
set +e
VAMPIRE_EDITION=invalid \
VAMPIRE_BUILD_DIR="$WORK/build" \
VAMPIRE_OUTPUT_DIR="$WORK/out" \
bash "$ROOT_DIR/build/build-live-iso.sh" >"$log" 2>&1
status=$?
set -e
[[ "$status" -eq 2 ]] || {
  cat "$log" >&2
  printf 'Expected invalid edition to exit 2, got %s\n' "$status" >&2
  exit 1
}
grep -Fq 'VAMPIRE_EDITION must be desktop or server' "$log"
[[ ! -e "$WORK/build" && ! -e "$WORK/out" ]] || {
  printf 'Invalid edition created build/output directories\n' >&2
  exit 1
}
printf 'PASS: invalid edition is rejected before creating build outputs\n'
