#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/logread" <<'MOCK'
#!/bin/sh
printf '%s\n' "$*" >> "$VLOGS_CALLS"
echo 'mock log output'
MOCK
chmod +x "$TMP/bin/logread"
export VLOGS_CALLS="$TMP/calls"
output=$(PATH="$TMP/bin:/usr/bin:/bin" sh "$ROOT/rootfs-overlay/usr/bin/vlogs" --lines 35)
grep -q 'mock log output' <<< "$output"
grep -qx -- '-l 35' "$VLOGS_CALLS"
: > "$VLOGS_CALLS"
PATH="$TMP/bin:/usr/bin:/bin" sh "$ROOT/rootfs-overlay/usr/bin/vlogs" --follow >/dev/null
grep -qx -- '-f' "$VLOGS_CALLS"
if sh "$ROOT/rootfs-overlay/usr/bin/vlogs" --lines 0 >/dev/null 2>&1; then
  echo 'vlogs accepted zero lines' >&2; exit 1
fi
if sh "$ROOT/rootfs-overlay/usr/bin/vlogs" --lines nope >/dev/null 2>&1; then
  echo 'vlogs accepted non-numeric line count' >&2; exit 1
fi
if sh "$ROOT/rootfs-overlay/usr/bin/vlogs" --unknown >/dev/null 2>&1; then
  echo 'vlogs accepted unknown option' >&2; exit 1
fi
echo 'Vampire log viewer tests passed.'
