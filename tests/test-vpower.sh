#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VPOWER="$ROOT_DIR/rootfs-overlay/usr/bin/vpower"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
STATUS="$("$VPOWER" status)"
grep -Fq 'Vampire OS power status' <<<"$STATUS" || fail 'status header missing'
for action in reboot poweroff halt; do grep -Fq "$action:" <<<"$STATUS" || fail "status omitted $action"; done
for args in 'reboot' 'poweroff no' 'halt --force' 'status extra' 'unknown'; do
  if "$VPOWER" $args >/dev/null 2>&1; then fail "accepted unsafe or invalid arguments: $args"; fi
done
cat > "$TMP/bin/id" <<'MOCK'
#!/bin/sh
printf '%s\n' "${MOCK_UID:-1000}"
MOCK
cat > "$TMP/bin/sync" <<'MOCK'
#!/bin/sh
echo sync >> "$POWER_CALLS"
MOCK
for action in reboot poweroff halt; do
  cat > "$TMP/bin/$action" <<'MOCK'
#!/bin/sh
echo "${0##*/}" >> "$POWER_CALLS"
MOCK
done
chmod +x "$TMP/bin/"*
export POWER_CALLS="$TMP/power-calls"
if PATH="$TMP/bin:$PATH" MOCK_UID=1000 "$VPOWER" reboot --yes >/dev/null 2>&1; then fail 'non-root user was allowed to reboot'; fi
test ! -e "$POWER_CALLS" || fail 'non-root rejection executed a command'
for action in reboot poweroff halt; do
  PATH="$TMP/bin:$PATH" MOCK_UID=0 "$VPOWER" "$action" --yes >/dev/null
  tail -n 2 "$POWER_CALLS" | diff -u <(printf 'sync\n%s\n' "$action") - || fail "$action dispatch order was incorrect"
  : > "$POWER_CALLS"
done
printf 'PASS: power status, argument validation, root guard and mocked confirmed dispatch\n'
