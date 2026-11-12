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
