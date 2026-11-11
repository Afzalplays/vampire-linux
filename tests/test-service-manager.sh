#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "\${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/services" "$TMP/etc"
cat > "$TMP/services/mock" <<'SERVICE'
#!/bin/sh
printf '%s\n' "$1" >> "$VAMPIRE_TEST_LOG"
SERVICE
chmod +x "$TMP/services/mock"
export VAMPIRE_SERVICE_DIR="$TMP/services"
export VAMPIRE_ENABLED_FILE="$TMP/etc/services.enabled"
export VAMPIRE_TEST_LOG="$TMP/actions"
VCTL="$ROOT/rootfs-overlay/usr/bin/vctl"
sh -n "$VCTL"
"$VCTL" enable mock
grep -Fxq mock "$VAMPIRE_ENABLED_FILE"
"$VCTL" list | grep -Fq 'mock (enabled)'
"$VCTL" start-all
grep -Fxq start "$VAMPIRE_TEST_LOG"
"$VCTL" status mock
grep -Fxq status "$VAMPIRE_TEST_LOG"
"$VCTL" disable mock
! grep -Fxq mock "$VAMPIRE_ENABLED_FILE"
"$VCTL" list | grep -Fq 'mock (disabled)'
if "$VCTL" enable '../escape' 2>/dev/null; then echo "unsafe service name accepted" >&2; exit 1; fi
echo "Vampire service manager tests passed."
