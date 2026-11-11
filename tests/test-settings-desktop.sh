#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
CONFIG="$TMP/settings.conf"
export VAMPIRE_SETTINGS_FILE="$CONFIG"
sh -n "$ROOT/rootfs-overlay/usr/bin/vsettings"
sh -n "$ROOT/rootfs-overlay/usr/bin/vdesktop"
# Use the shipped defaults as the defaults source for this isolated test.
mkdir -p "$TMP/etc/vampire"
cp "$ROOT/rootfs-overlay/etc/vampire/settings.defaults" "$TMP/etc/vampire/settings.defaults"
# Exercise settings CRUD using a test-local defaults path by copying script and rewriting path.
sed "s|DEFAULTS=/etc/vampire/settings.defaults|DEFAULTS=$TMP/etc/vampire/settings.defaults|" "$ROOT/rootfs-overlay/usr/bin/vsettings" > "$TMP/vsettings"
chmod +x "$TMP/vsettings"
"$TMP/vsettings" reset
test "$("$TMP/vsettings" get theme)" = dark
"$TMP/vsettings" set theme light
test "$("$TMP/vsettings" get theme)" = light
"$TMP/vsettings" set blur extreme
test "$("$TMP/vsettings" get blur)" = extreme
"$TMP/vsettings" set terminal_opacity 70
test "$("$TMP/vsettings" get terminal_opacity)" = 70
if "$TMP/vsettings" set theme 'dark; touch /tmp/pwned' >/dev/null 2>&1; then
  echo "settings accepted an invalid/injected value" >&2
  exit 1
fi
if "$TMP/vsettings" get unknown >/dev/null 2>&1; then
  echo "settings accepted an unknown key" >&2
  exit 1
fi
grep -q '^voice_access=false$' "$CONFIG"
echo "Vampire settings and desktop launcher tests passed."
