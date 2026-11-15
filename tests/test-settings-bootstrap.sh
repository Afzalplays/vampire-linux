#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
CONFIG="$TMP/etc/vampire/settings.conf"
DEFAULTS="$TMP/settings.defaults"
BACKUPS="$TMP/backups"
cp "$ROOT/rootfs-overlay/etc/vampire/settings.defaults" "$DEFAULTS"
export VAMPIRE_SETTINGS_FILE="$CONFIG"
export VAMPIRE_SETTINGS_DEFAULTS="$DEFAULTS"
export VAMPIRE_SETTINGS_BACKUP_DIR="$BACKUPS"
export VAMPIRE_SETTINGS_VALIDATOR="$ROOT/rootfs-overlay/usr/bin/vsettings"
BOOTSTRAP="$ROOT/rootfs-overlay/usr/lib/vampire/settings-bootstrap"

sh -n "$BOOTSTRAP"
sh "$BOOTSTRAP"
cmp -s "$CONFIG" "$DEFAULTS"
test "$(stat -c %a "$CONFIG")" = 600

# Valid user preferences must survive a normal boot.
VAMPIRE_SETTINGS_FILE="$CONFIG" "$ROOT/rootfs-overlay/usr/bin/vsettings" set theme light
cp "$CONFIG" "$TMP/valid.expected"
sh "$BOOTSTRAP"
cmp -s "$CONFIG" "$TMP/valid.expected"

# Invalid preferences are backed up before validated defaults replace them.
printf 'theme=invalid\n' > "$CONFIG"
if sh "$BOOTSTRAP"; then :; else
  echo "bootstrap failed to recover from invalid user settings" >&2; exit 1
fi
test "$(VAMPIRE_SETTINGS_FILE="$CONFIG" "$ROOT/rootfs-overlay/usr/bin/vsettings" get theme)" = dark
find "$BACKUPS" -type f -name 'settings.conf.invalid.*' | grep -q .
grep -q '^theme=invalid$' "$BACKUPS"/settings.conf.invalid.*

# Invalid defaults must never overwrite the current settings.
cp "$CONFIG" "$TMP/before-invalid-defaults"
printf 'theme=invalid\n' > "$DEFAULTS"
printf 'unknown_key=bad\n' > "$CONFIG"
cp "$CONFIG" "$TMP/invalid-current"
if sh "$BOOTSTRAP" >/dev/null 2>&1; then
  echo "bootstrap accepted invalid defaults" >&2; exit 1
fi
cmp -s "$CONFIG" "$TMP/invalid-current"

echo "Vampire boot settings bootstrap tests passed."
