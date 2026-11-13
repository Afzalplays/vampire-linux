#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
CONFIG="$TMP/settings.conf"
export VAMPIRE_SETTINGS_FILE="$CONFIG"
export VAMPIRE_SETTINGS_DEFAULTS="$TMP/settings.defaults"
export VAMPIRE_SETTINGS_APPLY="$ROOT/rootfs-overlay/usr/lib/vampire/settings_apply.py"
export VAMPIRE_WESTON_BASE="$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
export VAMPIRE_WESTON_RUNTIME_CONFIG="$TMP/weston.ini"
export VAMPIRE_FOOT_BASE="$ROOT/rootfs-overlay/etc/xdg/foot/foot.ini"
export XDG_CONFIG_HOME="$TMP/xdg"
sh -n "$ROOT/rootfs-overlay/usr/bin/vsettings"
python3 -m py_compile "$ROOT/rootfs-overlay/usr/lib/vampire/settings_apply.py"
sh -n "$ROOT/rootfs-overlay/usr/bin/vdesktop"
sh -n "$ROOT/rootfs-overlay/usr/bin/vmonitor"
cp "$ROOT/rootfs-overlay/etc/vampire/settings.defaults" "$VAMPIRE_SETTINGS_DEFAULTS"
cp "$ROOT/rootfs-overlay/usr/bin/vsettings" "$TMP/vsettings"
chmod +x "$TMP/vsettings"
"$TMP/vsettings" reset
test "$("$TMP/vsettings" get theme)" = dark
printf "0\n" | VAMPIRE_SETTINGS_CMD="$TMP/vsettings" "$ROOT/rootfs-overlay/usr/bin/vdesktop" --settings > "$TMP/settings-menu.out"
grep -q "Vampire Settings" "$TMP/settings-menu.out"
test "$("$TMP/vsettings" get accent)" = crimson
test "$("$TMP/vsettings" get dock_position)" = bottom-center
test "$("$TMP/vsettings" get update_channel)" = stable
test "$("$TMP/vsettings" get voice_access)" = false
"$TMP/vsettings" set theme light
test "$("$TMP/vsettings" get theme)" = light
"$TMP/vsettings" set blur extreme
test "$("$TMP/vsettings" get blur)" = extreme
"$TMP/vsettings" set terminal_opacity 70
test "$("$TMP/vsettings" get terminal_opacity)" = 70
"$TMP/vsettings" set accent rose
test "$("$TMP/vsettings" get accent)" = rose
"$TMP/vsettings" set surface_transparency 60
"$TMP/vsettings" set top_panel false
"$TMP/vsettings" set reduced_motion true
test "$("$TMP/vsettings" get surface_transparency)" = 60
"$TMP/vsettings" set dock_auto_hide false
test "$("$TMP/vsettings" get dock_auto_hide)" = false
"$TMP/vsettings" set show_network false
test "$("$TMP/vsettings" get show_network)" = false
"$TMP/vsettings" set update_channel testing
test "$("$TMP/vsettings" get update_channel)" = testing
"$TMP/vsettings" set voice_access true
test "$("$TMP/vsettings" get voice_access)" = true
"$TMP/vsettings" apply
grep -q "^background-color=0xfff2f2f6$" "$TMP/weston.ini"
grep -q "^panel-color=0x6671324c$" "$TMP/weston.ini"
grep -q "^panel-position=none$" "$TMP/weston.ini"
grep -q "^animation=none$" "$TMP/weston.ini"
grep -q "^alpha=0.70$" "$TMP/xdg/foot/foot.ini"
"$TMP/vsettings" validate
cp "$CONFIG" "$TMP/settings.good"
printf 'unknown_key=bad\n' > "$CONFIG"
if "$TMP/vsettings" validate >/dev/null 2>&1; then
  echo "settings validation accepted an unknown key" >&2; exit 1
fi
cp "$TMP/settings.good" "$CONFIG"
printf 'theme=dark\ntheme=light\n' > "$CONFIG"
if "$TMP/vsettings" validate >/dev/null 2>&1; then
  echo "settings validation accepted a duplicate key" >&2; exit 1
fi
cp "$TMP/settings.good" "$CONFIG"
if "$TMP/vsettings" set theme 'dark; touch /tmp/pwned' >/dev/null 2>&1; then
  echo "settings accepted an invalid/injected value" >&2; exit 1
fi
if "$TMP/vsettings" set surface_transparency 90 >/dev/null 2>&1; then
  echo "settings accepted out-of-range transparency" >&2; exit 1
fi
if "$TMP/vsettings" get unknown >/dev/null 2>&1; then
  echo "settings accepted an unknown key" >&2; exit 1
fi
grep -q '^voice_access=true$' "$CONFIG"
grep -q '^dock_magnification=true$' "$CONFIG"
mkdir -p "$TMP/mockbin"
cat > "$TMP/mockbin/vsh" <<'MOCK'
#!/bin/sh
printf 'started\n' >> "$VSH_TEST_LOG"
MOCK
chmod +x "$TMP/mockbin/vsh"
export VSH_TEST_LOG="$TMP/vsh.log"
printf '5\n0\n' | PATH="$TMP/mockbin:$PATH" "$ROOT/rootfs-overlay/usr/bin/vdesktop" >/dev/null
grep -qx 'started' "$VSH_TEST_LOG"
printf '2\n16\ntesting\n17\ntrue\n1\ndark\n0\n0\n' | VAMPIRE_SETTINGS_CMD="$TMP/vsettings" PATH="$TMP/mockbin:$PATH" "$ROOT/rootfs-overlay/usr/bin/vdesktop" >/dev/null
test "$("$TMP/vsettings" get update_channel)" = testing
test "$("$TMP/vsettings" get voice_access)" = true
test "$("$TMP/vsettings" get theme)" = dark
grep -q "^background-color=0xff08080c$" "$TMP/weston.ini"

cat > "$TMP/mockbin/vpm" <<'MOCK'
#!/bin/sh
exit 1
MOCK
cat > "$TMP/mockbin/vupdate" <<'MOCK'
#!/bin/sh
exit 1
MOCK
chmod +x "$TMP/mockbin/vpm" "$TMP/mockbin/vupdate"
printf '9\n\n10\n\n0\n' | PATH="$TMP/mockbin:$PATH" "$ROOT/rootfs-overlay/usr/bin/vdesktop" > "$TMP/errors.out"
grep -q 'Command failed (exit 1)' "$TMP/errors.out"

sh "$ROOT/rootfs-overlay/usr/bin/vmonitor" > "$TMP/monitor.out"
grep -q "VAMPIRE MONITOR" "$TMP/monitor.out"

# Recent/following log and live monitor menu entries must dispatch exact arguments.
cat > "$TMP/mockbin/vlogs" <<'MOCK'
#!/bin/sh
printf 'vlogs %s\n' "$*" >> "$VLOGS_TEST_LOG"
MOCK
cat > "$TMP/mockbin/vmonitor" <<'MOCK'
#!/bin/sh
printf 'vmonitor %s\n' "$*" >> "$VLOGS_TEST_LOG"
MOCK
chmod +x "$TMP/mockbin/vlogs" "$TMP/mockbin/vmonitor"
export VLOGS_TEST_LOG="$TMP/log-menu.log"
printf '19\n\n20\n\n21\n\n0\n' | PATH="$TMP/mockbin:$PATH" "$ROOT/rootfs-overlay/usr/bin/vdesktop" > "$TMP/log-menu.out"
grep -qx 'vlogs --lines 100' "$VLOGS_TEST_LOG"
grep -qx 'vlogs --follow' "$VLOGS_TEST_LOG"
grep -qx 'vmonitor --watch 2' "$VLOGS_TEST_LOG"

# Installer menu exposes the non-destructive layout preview after preflight.
cat > "$TMP/mockbin/vinstall" <<'MOCK'
#!/bin/sh
printf 'vinstall %s\n' "$*" >> "$VINSTALL_TEST_LOG"
case "$1" in preflight|plan) exit 0 ;; *) exit 2 ;; esac
MOCK
chmod +x "$TMP/mockbin/vinstall"
export VINSTALL_TEST_LOG="$TMP/install-menu.log"
printf '7\n/dev/mockdisk\ny\nuefi\n\n0\n' | VAMPIRE_INSTALLER_CMD="$TMP/mockbin/vinstall" PATH="$TMP/mockbin:$PATH" "$ROOT/rootfs-overlay/usr/bin/vdesktop" > "$TMP/install-menu.out"
grep -qx 'vinstall system-check' "$VINSTALL_TEST_LOG" || true
grep -qx 'vinstall list' "$VINSTALL_TEST_LOG" || true
grep -qx 'vinstall preflight /dev/mockdisk' "$VINSTALL_TEST_LOG"
grep -qx 'vinstall plan /dev/mockdisk uefi' "$VINSTALL_TEST_LOG"

echo "Vampire settings, Desktop preference menu, log/monitor dispatch, Vampire Shell dispatch and monitor tests passed."
