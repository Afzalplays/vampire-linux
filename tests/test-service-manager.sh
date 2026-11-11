#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/services" "$TMP/etc"
cat > "$TMP/services/mock" <<'SERVICE'
#!/bin/sh
printf 'mock:%s\n' "$1" >> "$VAMPIRE_TEST_LOG"
SERVICE
cat > "$TMP/services/second" <<'SERVICE'
#!/bin/sh
printf 'second:%s\n' "$1" >> "$VAMPIRE_TEST_LOG"
SERVICE
chmod +x "$TMP/services/mock" "$TMP/services/second"
export VAMPIRE_SERVICE_DIR="$TMP/services"
export VAMPIRE_ENABLED_FILE="$TMP/etc/services.enabled"
export VAMPIRE_TEST_LOG="$TMP/actions"
VCTL="$ROOT/rootfs-overlay/usr/bin/vctl"
sh -n "$VCTL"
"$VCTL" enable mock
"$VCTL" enable second
grep -Fxq mock "$VAMPIRE_ENABLED_FILE"
grep -Fxq second "$VAMPIRE_ENABLED_FILE"
"$VCTL" list | grep -Fq 'mock (enabled)'
"$VCTL" start-all
grep -Fxq 'mock:start' "$VAMPIRE_TEST_LOG"
grep -Fxq 'second:start' "$VAMPIRE_TEST_LOG"
[ "$(head -n 2 "$VAMPIRE_TEST_LOG" | tr '\n' ' ')" = "mock:start second:start " ]
"$VCTL" status mock
grep -Fxq 'mock:status' "$VAMPIRE_TEST_LOG"
"$VCTL" stop-all
[ "$(tail -n 2 "$VAMPIRE_TEST_LOG" | tr '\n' ' ')" = "second:stop mock:stop " ]
"$VCTL" disable mock
! grep -Fxq mock "$VAMPIRE_ENABLED_FILE"
"$VCTL" list | grep -Fq 'mock (disabled)'
if "$VCTL" enable '../escape' 2>/dev/null; then echo "unsafe service name accepted" >&2; exit 1; fi
echo "Vampire service manager tests passed."
