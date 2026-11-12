#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
CONFIG="$TMP/settings.conf"
export VAMPIRE_SETTINGS_FILE="$CONFIG"
export VAMPIRE_SETTINGS_DEFAULTS="$TMP/settings.defaults"
sh -n "$ROOT/rootfs-overlay/usr/bin/vsettings"
sh -n "$ROOT/rootfs-overlay/usr/bin/vdesktop"
sh -n "$ROOT/rootfs-overlay/usr/bin/vmonitor"
cp "$ROOT/rootfs-overlay/etc/vampire/settings.defaults" "$VAMPIRE_SETTINGS_DEFAULTS"
cp "$ROOT/rootfs-overlay/usr/bin/vsettings" "$TMP/vsettings"
chmod +x "$TMP/vsettings"
"$TMP/vsettings" reset
test "$("$TMP/vsettings" get theme)" = dark
test "$("$TMP/vsettings" get accent)" = crimson
test "$("$TMP/vsettings" get dock_position)" = bottom-center
"$TMP/vsettings" set theme light
test "$("$TMP/vsettings" get theme)" = light
"$TMP/vsettings" set blur extreme
test "$("$TMP/vsettings" get blur)" = extreme
"$TMP/vsettings" set terminal_opacity 70
test "$("$TMP/vsettings" get terminal_opacity)" = 70
"$TMP/vsettings" set accent rose
test "$("$TMP/vsettings" get accent)" = rose
"$TMP/vsettings" set surface_transparency 60
test "$("$TMP/vsettings" get surface_transparency)" = 60
"$TMP/vsettings" set dock_auto_hide false
test "$("$TMP/vsettings" get dock_auto_hide)" = false
"$TMP/vsettings" set show_network false
test "$("$TMP/vsettings" get show_network)" = false
if "$TMP/vsettings" set theme 'dark; touch /tmp/pwned' >/dev/null 2>&1; then
  echo "settings accepted an invalid/injected value" >&2; exit 1
fi
if "$TMP/vsettings" set surface_transparency 90 >/dev/null 2>&1; then
  echo "settings accepted out-of-range transparency" >&2; exit 1
fi
if "$TMP/vsettings" get unknown >/dev/null 2>&1; then
  echo "settings accepted an unknown key" >&2; exit 1
fi
grep -q '^voice_access=false$' "$CONFIG"
grep -q '^dock_magnification=true$' "$CONFIG"
sh "$ROOT/rootfs-overlay/usr/bin/vmonitor" > "$TMP/monitor.out"
grep -q "VAMPIRE MONITOR" "$TMP/monitor.out"
echo "Vampire settings, desktop launcher and monitor tests passed."
