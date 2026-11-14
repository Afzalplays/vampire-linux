#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/services" "$TMP/etc" "$TMP/empty-services"
cat > "$TMP/services/mock" <<'SERVICE'
#!/bin/sh
printf 'mock:%s\n' "$1" >> "$VAMPIRE_TEST_LOG"
SERVICE
cat > "$TMP/services/second" <<'SERVICE'
#!/bin/sh
printf 'second:%s\n' "$1" >> "$VAMPIRE_TEST_LOG"
SERVICE
cat > "$TMP/services/broken-stop" <<'SERVICE'
#!/bin/sh
printf 'broken-stop:%s\n' "$1" >> "$VAMPIRE_TEST_LOG"
[ "$1" != stop ]
SERVICE
chmod +x "$TMP/services/"*
export VAMPIRE_SERVICE_DIR="$TMP/services"
export VAMPIRE_ENABLED_FILE="$TMP/etc/services.enabled"
export VAMPIRE_TEST_LOG="$TMP/actions"
VCTL="$ROOT/rootfs-overlay/usr/bin/vctl"
sh -n "$VCTL"
"$VCTL" enable mock
"$VCTL" enable second
"$VCTL" enable second
grep -Fxq mock "$VAMPIRE_ENABLED_FILE"
grep -Fxq second "$VAMPIRE_ENABLED_FILE"
[ "$(grep -Fc second "$VAMPIRE_ENABLED_FILE")" -eq 1 ]
[ "$(stat -c '%a' "$VAMPIRE_ENABLED_FILE")" = 600 ]
"$VCTL" list > "$TMP/list"
grep -Fq 'mock (enabled)' "$TMP/list"
"$VCTL" start-all
grep -Fxq 'mock:start' "$VAMPIRE_TEST_LOG"
grep -Fxq 'second:start' "$VAMPIRE_TEST_LOG"
[ "$(head -n 2 "$VAMPIRE_TEST_LOG" | tr '\n' ' ')" = "mock:start second:start " ]
"$VCTL" status mock
grep -Fxq 'mock:status' "$VAMPIRE_TEST_LOG"
: > "$VAMPIRE_TEST_LOG"
"$VCTL" status-all
grep -Fxq 'second:status' "$VAMPIRE_TEST_LOG"
[ "$(grep -Fc ':status' "$VAMPIRE_TEST_LOG")" -eq 2 ]
"$VCTL" stop-all
[ "$(tail -n 2 "$VAMPIRE_TEST_LOG" | tr '\n' ' ')" = "second:stop mock:stop " ]
"$VCTL" disable mock
! grep -Fxq mock "$VAMPIRE_ENABLED_FILE"
"$VCTL" list > "$TMP/list"
grep -Fq 'mock (disabled)' "$TMP/list"
if "$VCTL" restart broken-stop 2>/dev/null; then echo "restart unexpectedly succeeded after stop failure" >&2; exit 1; fi
[ "$(grep -Fc 'broken-stop:start' "$VAMPIRE_TEST_LOG" || true)" -eq 0 ]
printf 'mock\nmock\n' > "$VAMPIRE_ENABLED_FILE"
: > "$VAMPIRE_TEST_LOG"
"$VCTL" status-all 2>"$TMP/status-duplicate.err"
[ "$(grep -Fc 'mock:status' "$VAMPIRE_TEST_LOG")" -eq 1 ]
grep -Fq 'ignoring duplicate service entry' "$TMP/status-duplicate.err"
"$VCTL" start-all 2>"$TMP/duplicate.err"
[ "$(grep -Fc 'mock:start' "$VAMPIRE_TEST_LOG")" -eq 2 ]
grep -Fq 'ignoring duplicate service entry' "$TMP/duplicate.err"
printf 'mock\n../escape\n' > "$VAMPIRE_ENABLED_FILE"
: > "$VAMPIRE_TEST_LOG"
if "$VCTL" status-all 2>"$TMP/status-invalid.err"; then
  echo "status-all accepted malformed enabled entry" >&2
  exit 1
fi
[ "$(grep -Fc 'mock:status' "$VAMPIRE_TEST_LOG")" -eq 1 ]
grep -Fq 'ignoring invalid service entry' "$TMP/status-invalid.err"
if "$VCTL" enable second 2>/dev/null; then echo "malformed enabled list accepted" >&2; exit 1; fi
for unsafe in '../escape' '-leading-dash' '..' '.hidden'; do
  if "$VCTL" enable "$unsafe" 2>/dev/null; then echo "unsafe service name accepted: $unsafe" >&2; exit 1; fi
done
if "$VCTL" status missing 2>/dev/null; then echo "missing service reported success" >&2; exit 1; fi
VAMPIRE_SERVICE_DIR="$TMP/empty-services" "$VCTL" list > "$TMP/empty-list"
grep -Fq 'no services installed' "$TMP/empty-list"
echo "Vampire service manager tests passed."
