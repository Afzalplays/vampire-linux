#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/settings" <<'MOCK'
#!/bin/sh
case "$1" in
  list) printf 'theme dark\naccent crimson\n' ;;
  *) exit 2 ;;
esac
MOCK
chmod +x "$TMP/settings"
printf '0\n' | VAMPIRE_SETTINGS_CMD="$TMP/settings" "$ROOT/rootfs-overlay/usr/bin/vdesktop" --settings > "$TMP/output"
grep -q 'Vampire Settings — Appearance and Desktop' "$TMP/output"
grep -q '1) Theme' "$TMP/output"
echo "Vampire Settings direct-launch test passed."

# Unsupported graphical preferences must be stored honestly without claiming
# that Weston applied a control it does not implement yet.
cat > "$TMP/settings" <<'MOCK"
#!/bin/sh
case "$1" in
  list) echo "theme dark" ;;
  set) printf 'set %s=%s\n' "$2" "$3" >> "$SETTINGS_CALLS" ;;
  apply) echo apply >> "$SETTINGS_CALLS" ;;
  *) exit 2 ;;
esac
MOCK
chmod +x "$TMP/settings"
: > "$TMP/calls"
printf '4\nextreme\n0\n' | SETTINGS_CALLS="$TMP/calls" VAMPIRE_SETTINGS_CMD="$TMP/settings" "$ROOT/rootfs-overlay/usr/bin/vdesktop" --settings > "$TMP/unsupported-output"
grep -q 'preference is stored; its graphical control is not implemented' "$TMP/unsupported-output"
grep -q '^set blur=extreme$' "$TMP/calls"
! grep -q '^apply$' "$TMP/calls"
echo "Vampire Settings unsupported-control disclosure test passed."
